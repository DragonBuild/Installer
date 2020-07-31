#!/usr/bin/env bash

# Add colors for text
export PrefixColor='\033[1;34m'
export BoldColor='\033[1;37m'
export NC='\033[0m'

crd=$PWD

# Check if user is root already
if [[ $UID == 0 || $EUID == 0 ]]; then
    printf "${PrefixColor}[Dragon]${BoldColor} Do not run this script as root.\n"
    exit
fi

# Get sudo perms
sudo -p "Password for installation: " printf "\n" || exit 1

# Set need to "" for adding dependencies
need=""

# See if system is debian-based for different ninja name.
if [ -f "/etc/debian_version" ]; then
    command -v wget >/dev/null 2>&1 || need+="wget "
    command -v ninja >/dev/null 2>&1 || need+="ninja-build "
    command -v python3 >/dev/null 2>&1 || need+="python3 "
    command -v ldid >/dev/null 2>&1 || need+="ldid "
    command -v perl >/dev/null 2>&1 || need+="perl "
    command -v dpkg >/dev/null 2>&1 || need+="dpkg "
    command -v unzip >/dev/null 2>&1 || need+="unzip "
else
    command -v wget >/dev/null 2>&1 || need+="wget "
    command -v ninja >/dev/null 2>&1 || need+="ninja "
    command -v python3 >/dev/null 2>&1 || need+="python3 "
    command -v ldid >/dev/null 2>&1 || need+="ldid "
    command -v perl >/dev/null 2>&1 || need+="perl "
    command -v dpkg >/dev/null 2>&1 || need+="dpkg "
    command -v unzip >/dev/null 2>&1 || need+="unzip "
fi

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
        if [ "$arch" == "arm" ] || [ "$arch" == "arm64" ]; then iosInstall
        else macosInstall
        fi
    else linuxInstall
    fi
    printf "${PrefixColor}[Dragon] ${BoldColor}Downloading DragonBuild...\n"
    cd ~
    git clone https://github.com/DragonBuild/DragonBuild.git
    mv DragonBuild .dragonbuild
    printf "${PrefixColor}[Dragon] ${BoldColor}Installing DragonBuild...\n"
    source ~/.dragonbuild/internal/environment
    cd ~/.dragonbuild 
    git pull
    git submodule update --init --recursive
    cd ~
    sudo ln -s ~/.dragonbuild/dragon /usr/local/bin/dragon
    
}

installDragonBuild
cd $crd
