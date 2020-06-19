#!/bin/sh

nosudo() {
    echo "This cannot be ran as root or with sudo."
    exit 1
}

crd=$PWD

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

iosInstall() {
    if [ $need != "" ]; then
      echo "Please Install the Following Dependencies (${need})."
      exit 1
    fi
}

macosInstall() {
    if [ $need != "" ]; then
      read -p "Using Brew To Install Dependencies (${need}). Press Enter to Continue." || exit 1
      brew install $need
    fi
}

linuxInstall() {
    if [ $need != "" ]; then
      read -p "Installing Dependencies (${need}). Press Enter to Continue." || exit 1
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
    arch=$(uname -p)
    if [ $distr == "Darwin" ]; then 
        if [ $arch == "arm" ] || [ $arch == "arm64" ]; then iosInstall
        else macosInstall
        fi
    else linuxInstall
    fi
    echo "Downloading DragonBuild..."
    cd ~
    git clone https://github.com/DragonBuild/DragonBuild.git
    mv DragonBuild .dragonbuild
    echo "Installing DragonBuild"
    source ~/.dragonbuild/internal/environment
    cd ~/.dragonbuild 
    git pull
    git submodule update --init --recursive
    cd ~
    sudo ln -s ~/.dragonbuild/dragon /usr/local/bin/dragon
}

installDragonBuild
cd $crd
