#!/usr/bin/env bash
# DragonBuild - install.sh
set -e

CWD="$(realpath ${PWD} || echo ${PWD})"
SCRIPT="$(realpath ${0} || echo $0 )"
RELEASE="1.0.0"
INSTALL_USER="$@"

getroot() {
    if sudo -n true &>/dev/null; then
      printf -- '%s\n %s\n' "Using cached permissons sudo to continue with install"  \
        "CRTL-C to cancel."
      sleep 3
    else
      echo "Enter sudo password to continue:"
      sudo -p \
        "$(printf -- '(%s): %s' "sudo" "Password for installation: ")" true
    fi
    sudo ${SCRIPT} "${USER}"
    exit $?
}
[[ ${UID} -eq 0 || ${EUID} -eq 0 ]] || getroot

onexit() {
  [[ -n "${DRAGON_TEMPDIR+x}" ]] && rm -rf ${DRAGON_TEMPDIR}
}; trap "onexit" INT TERM EXIT

needed=()
toInstall=(
  "wget"
  "ninja"
  "python3"
  "ldid"
  "perl"
  "dpkg"
  "unzip"
)

for depend in ${toInstall[@]}; do
  command -v ${depend} &>/dev/null || needed+=(${depend})
done

OS=""
case "$(uname)" in
  Linux)
    : "linux"
    ;;
  Darwin)
    : "darwin"
    ;;
  *)
    : "unknown"
    ;;
# wsl)
#   : "windows"
esac
OS="$_"

macosInstall() {
  [[ -z "${needed[@]}" ]] && return
  read -p \
  "$(printf -- "Using HomeBrew to Install:\n%s\n  Press Enter to Continue. " "${needed[@]}")" _

  for depend in ${needed[@]}; do
    brew install "${depend}"
  done
}

linuxInstall(){
  [[ -z "${needed[@]}" ]] && return
  local cmd

  if command -v apk &>/dev/null; then
    cmd="apk add --no-cache"
  elif command -v apt-get &>/dev/null; then
    cmd="apt-get install"
  elif command -v dnf &>/dev/null; then
    cmd="dnf install"
  elif command -v zypper &>/dev/null; then
    cmd="zypper install"
  else
    cmd="true"
  fi

  ${cmd} ${needed[@]} || :
  [[ "${cmd}" == "true" || $? -ne 0 ]] && \
    {
      printf -- '!!! %s\n%s\n' "Installing dependencies failed. Install manually:" \
        "${needed[@]}";
      # sleep 5;
      # exit 1;
    }
}

installDragonBuild() {
  # WE ARE ROOT, be mindful of our actions
  export URL="https://github.com/DragonBuild/DragonBuild/releases/download/${RELEASE}/DragonBuild.zip"
  # https://github.com/DragonBuild/DragonBuild/archive/1.0.0.zip
  # https://github.com/DragonBuild/DragonBuild/releases/download/1.0.0/DragonBuild.zip
  export DRAGON_TEMPDIR="${TMPDIR:-/tmp}/dragonbuild-install"

  case ${OS} in
    linux) linuxInstall ;;
    darwin) macosInstall ;;
    *) linuxInstall ;;
  esac

  echo "Installing DragonBuild..."

# we're root and want to install as the user we where called from
  cat << EOF | su ${INSTALL_USER} -c bash
    shopt -s extglob nullglob
    set -e
    mkdir ${DRAGON_TEMPDIR}
    cd ${DRAGON_TEMPDIR}
    wget "${URL}"

    unzip DragonBuild.zip -d \${HOME}/.dragonbuild
    mv \${HOME}/.dragonbuild/DragonBuild/* \${HOME}/.dragonbuild
    rm -rf \${HOME}/.dragonbuild/DragonBuild-master

    for profile in zshrc bash_profile profile; do
      printf -- '\n%s\n' "source ~/.dragonbuild/internal/environment" \
        >> \${HOME}/.\${profile}
    done

    source \${HOME}/.dragonbuild/internal/environment
    cd \${HOME}/.dragonbuild

    # git pull
    # git submodule update --init --recursive

EOF

  local _HOME="$(su ${INSTALL_USER} -c echo ${HOME})"

  ln -s ${_HOME}/.dragonbuild/dragon /usr/local/bin/dragon || :
}

installDragonBuild
cd $crd
