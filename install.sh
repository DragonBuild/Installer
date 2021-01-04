#!/usr/bin/env bash

InstallerVersion="1.0.2"

# Add colors for text
PrefixColor='\033[1;32m'
BoldColor='\033[1;37m'
WhiteColor='\033[0;37m'
NC='\033[0m'

crd=$PWD

# Check if user is root already
if [[ $UID == 0 || $EUID == 0 ]]; then
    printf "${PrefixColor}[Dragon]${BoldColor} Do not run this script as root.\n"
    exit
fi

printf "${BoldColor}starting dragon installer v${InstallerVersion}${NC}\n"

# Get sudo perms
sudo -p "sudo password (for symlinking /usr/local/bin/dragon): " printf "\n" || exit 1

# Set need to "" for adding dependencies
need=""

# See if system is debian-based or Fedora linux for different ninja name.
if [ -f "/etc/debian_version" ]; then
    command -v ninja >/dev/null 2>&1 || need+="ninja-build "
elif grep -Fxq "ID=fedora" /etc/os_release >/dev/null 2>&1; then
    command -v ninja >/dev/null 2>&1 || need+="ninja-build "
else
    command -v ninja >/dev/null 2>&1 || need+="ninja "
fi

command -v python3 >/dev/null 2>&1 || need+="python3 "
command -v ldid >/dev/null 2>&1 || need+="ldid "
command -v perl >/dev/null 2>&1 || need+="perl "
command -v dpkg >/dev/null 2>&1 || need+="dpkg "

iosInstall() {
    if [ "$need" != "" ]; then
      read -p "Installing Dependencies (${need}). Press Enter to Continue." || exit 1
      sudo apt-get install $need
      python3 -m pip install --user pyyaml regex
    fi
}

macosInstall() {
    if [ "$need" != "" ]; then
      read -p "Using Brew To Install Dependencies (${need}). Press Enter to Continue." || exit 1
      brew install $need
      python3 -m pip install --user pyyaml regex
    fi
}

linuxInstall() {
    if [ "$need" != "" ]; then
      read -p "Installing Dependencies (${need}). Press Enter to Continue." || exit 1
      if [ -x "$(command -v apk)" ];       then sudo apk add --no-cache $need || failedinstall=1
       elif [ -x "$(command -v apt-get)" ]; then sudo apt-get install $need || failedinstall=1
       elif [ -x "$(command -v dnf)" ];     then sudo dnf install $need || failedinstall=1
       elif [ -x "$(command -v zypper)" ];  then sudo zypper install $need || failedinstall=1
      else failedinstall=1;
      fi
      if [ $failedinstall == 1 ]; then
        echo "Installing dependencies failed. You need to manually install: $need">&2; 
      else 
        python3 -m pip install --user pyyaml regex
      fi
    fi
}

installDragonBuild() {
    distr=$(uname -s)
    arch=$(uname -p)
    if [ "$distr" == "Darwin" ]; then 
        if [ "$arch" == "arm" ] || [ "$arch" == "arm64" ]; then
	    if [ "${USER}" == "mobile" ]; then
	        iosInstall
	    else
                macosInstall
	    fi
        fi
    else linuxInstall
    fi
    printf "${PrefixColor}[Dragon] ${BoldColor}downloading dragon main project${NC}\n"
    cd ~
    git clone --depth=1 https://github.com/DragonBuild/dragon.git .dragonbuild
    printf "${PrefixColor}[Dragon] ${WhiteColor}loading in environment${NC}\n"
    source ~/.dragonbuild/internal/data/environment
    cd ~/.dragonbuild 
    printf "${PrefixColor}[Dragon] ${WhiteColor}running git pull${NC}\n"
    git pull
    printf "${PrefixColor}[Dragon] ${BoldColor}downloading submodules${NC}\n"
    git submodule update --init --recursive
    printf "${PrefixColor}[Dragon] ${BoldColor}Creating symlink${NC}\n"
    sudo ln -s ~/.dragonbuild/dragon /usr/local/bin/dragon
    
    printf "${PrefixColor}[Dragon] ${BoldColor}dragon v${DRAGONVERS} has been installed.${NC}\n"
    printf "${WhiteColor}Run 'dragon' for a list of tools included.${NC}\n\n"
    
    printf "${PrefixColor}dragon installer v${InstallerVersion} ${BoldColor}-=-=-${NC}\n"
    printf "${WhiteColor}Github Link: https://dr.krit.me/ (https://github.com/DragonBuild/Installer)\n"
    printf "${WhiteColor}Contributors:\n  - kritanta\n  - quiprr\n  - diatrus${NC}\n\n"
    
    printf "${PrefixColor}dragon v${DRAGONVERS} ${BoldColor}-=-=-${NC}\n"
    printf "${WhiteColor}Github Link: https://dragon.krit.me/ (https://github.com/DragonBuild/dragon)\n"
    printf "${WhiteColor}Contributors:\n  - kritanta (author)\n  - l0renzo (DragonGen)\n  - monotrix\n  - iCrazeiOS${NC}\n\n"
    
    printf "${WhiteColor}Use 'dragon update' to update to the latest build\n\n"
    printf "${WhiteColor}Please contribute, file issues, or anything else:\n  - 'https://dragon.krit.me/\n\n"
    printf "${NC}enjoy ~\n\n"
}

installDragonBuild
cd $crd
