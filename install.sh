#!/bin/sh

nosudo() {
    echo "This cannot be ran as root or with sudo."
    exit 1
}

crd=$PWD

if [ "$(id -ru)" = "0" ] || [ "$(id -u)" = "0" ]; then
    nosudo
fi

sudo -p "Password for installation: " printf "" || exit 1

need=""

command -v wget >/dev/null 2>&1 || need="${need} wget"
command -v ninja >/dev/null 2>&1 || need="${need} ninja"
command -v python3 >/dev/null 2>&1 || need="${need} python3"
command -v ldid >/dev/null 2>&1 || need="${need} ldid"
command -v perl >/dev/null 2>&1 || need="${need} perl"
command -v dpkg >/dev/null 2>&1 || need="${need} dpkg"
command -v unzip >/dev/null 2>&1 || need="${need} unzip"

iosInstall() {
    if [ "$need" != "" ]; then
      echo "Please Install the Following Dependencies (${need})."
      exit 1
    fi
}

macosInstall() {
    if [ "$need" != "" ]; then
      read "Using Brew To Install Dependencies (${need}). Press Enter to Continue." || exit 1
      brew install $need
    fi
}

linuxInstall() {
    if [ "$need" != "" ]; then
      read "Installing Dependencies (${need}). Press Enter to Continue." || exit 1
      if [ -x "$(command -v apk)" ];       then sudo apk add --no-cache $need || failedinstall=1
       elif [ -x "$(command -v apt-get)" ]; then sudo apt-get install $need || failedinstall=1
       elif [ -x "$(command -v dnf)" ];     then sudo dnf install $need || failedinstall=1
       elif [ -x "$(command -v zypper)" ];  then sudo zypper install $need || failedinstall=1
      else failedinstall=1;
      fi
      if [ 1 = $failedinstall ]; then
        echo "Installing dependencies failed. You need to manually install: $need">&2; 
      fi
    fi
}

installDragonBuild() {
    distr=$(uname -s)
    arch=$(uname -p)
    if [ "Darwin" = "$distr" ]; then 
        if [ "arm" = "$arch" ] || [ "arm64" = "$arch" ]; then iosInstall
        else macosInstall
        fi
    else linuxInstall
    fi
    echo "Downloading DragonBuild..."
    cd ~
    git clone --recursive https://github.com/DragonBuild/DragonBuild.git .dragonbuild
    echo "Installing DragonBuild"
    echo "source ~/.dragonbuild/internal/environment" | bash    # dash has failed me
    cd ~
    sudo ln -s ~/.dragonbuild/dragon /usr/local/bin/dragon
}

installDragonBuild
cd $crd
