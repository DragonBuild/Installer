#!/bin/sh

nosudo() {
    echo "This cannot be ran as root or with sudo."
    exit 1
}

[[ $UID == 0 || $EUID == 0 ]] && nosudo

sudo -p "Password for installation: " printf "" || exit 1

need=""

command -v wget >/dev/null 2>&1 || need+="wget "
command -v ninja >/dev/null 2>&1 || need+="ninja "
command -v python3 >/dev/null 2>&1 || need+="python3 "
command -v ldid >/dev/null 2>&1 || need+="ldid "
command -v perl >/dev/null 2>&1 || need+="perl "
command -v dpkg >/dev/null 2>&1 || need+="dpkg "
command -v unzip >/dev/null 2>&1 || need+="unzip "

macosInstall() {
    read -p "Using Brew To Install Dependencies. Press Enter to Continue." || exit 1
    brew install $need
}

linuxInstall() {
    if [ $need != "" ]; then
      read -p "Installing Dependencies. Press Enter to Continue." || exit 1
      if [ -x "$(command -v apk)" ];       then sudo apk add --no-cache $need || failedinstall=1
       elif [ -x "$(command -v apt-get)" ]; then sudo apt-get install $need || failedinstall=1
       elif [ -x "$(command -v dnf)" ];     then sudo dnf install $need || failedinstall=1
       elif [ -x "$(command -v zypper)" ];  then sudo zypper install $need || failedinstall=1
      else failedinstall=1;
      fi
      if [ $failedinstall == 1 ]; then
        echo "Installing dependencies failed. You need to manually install: $need">&2; 
      fi
    fi
}

installDragonBuild() {
    distr=$(uname -s)
    if [ $distr == "Darwin" ]; then macosInstall
    else linuxInstall
    fi
    echo "Downloading DragonBuild..."
    cd /tmp
    wget https://github.com/DragonBuild/DragonBuild/archive/master.zip
    echo "Installing DragonBuild"
    unzip master.zip -d ~/.dragonbuild
    mv ~/.dragonbuild/DragonBuild-master/* ~/.dragonbuild && rm -rf ~/.dragonbuild/DragonBuild-master
    rm -rf master.zip
    cd ~
    echo "source ~/.dragonbuild/internal/environment" >> .zshrc
    echo "source ~/.dragonbuild/internal/environment" >> .bash_profile
    echo "source ~/.dragonbuild/internal/environment" >> .profile
    source ~/.dragonbuild/internal/environment
    sudo ln -s ~/.dragonbuild/dragon /opt/local/bin/dragon
}

installDragonBuild
