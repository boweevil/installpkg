#!/bin/bash -
#===============================================================================
#
#          FILE: installPkg.sh
#
#         USAGE: ./installPkg.sh
#
#   DESCRIPTION: Install all packages from the packages directory.
#
#       OPTIONS: --help, --version, --install
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Jason Carpenter (boweevil),
#         EMAIL: argonaut.linux@gmail.com
#  ORGANIZATION:
#       CREATED: 03/17/2017 08:25
#      REVISION:  ---
#===============================================================================

#-------------------------------------------------------------------------------
# OPTIONS
#-------------------------------------------------------------------------------
set -e

set -o pipefail

# Enable alias expansion.
shopt -s expand_aliases

#-------------------------------------------------------------------------------
# VARIABLES
#-------------------------------------------------------------------------------
SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}"  )" && pwd  )
export SCRIPT_DIR
SCRIPT_NAME="$( basename "$0" )"
SCRIPT_VERSION='1.0.0'

linux_release_file=/etc/os-release
redhat_file=/etc/redhat-release

color0='\e[0m'
color1='\e[0;34m'

pkgs_dir="${SCRIPT_DIR}/packages"

redhat_distros=(
  "fedora"
  "centos"
  "centos linux"
    )


debian_distros=(
  "debian"
  "ubuntu"
    )


arch_distros=(
  "arch"
  "antergos linux"
    )


supported_distros=(
  "${redhat_distros[@]}"
  "${debian_distros[@]}"
  "${arch_distros[@]}"
    )


export supported_distros

#-------------------------------------------------------------------------------
# FUNCTIONS
#-------------------------------------------------------------------------------
except ()
{
  #---  FUNCTION  ----------------------------------------------------------------
  #          NAME:  except
  #   DESCRIPTION:  Print an error message and return and error.
  #    PARAMETERS:  [MESSAGE]
  #       RETURNS:  [MESSAGE] and exit code 1
  #-------------------------------------------------------------------------------
  echo "Error: $*"
  return 1
}	# ----------  end of function except  ----------


version ()
{
  #---  FUNCTION  ----------------------------------------------------------------
  #          NAME:  version
  #   DESCRIPTION:  Print the script version and exit.
  #    PARAMETERS:  None
  #       RETURNS:  Version number.
  #-------------------------------------------------------------------------------
  echo "${SCRIPT_NAME}, version: ${SCRIPT_VERSION}"
  echo
}	# ----------  end of function version  ----------


usage ()
{
  #---  FUNCTION  ----------------------------------------------------------------
  #          NAME:  usage
  #   DESCRIPTION:  Print a help message.
  #    PARAMETERS:  None
  #       RETURNS:  Usage information.
  #-------------------------------------------------------------------------------
  version
  echo "Usage: ${SCRIPT_NAME} [ARGUMENTS]..."
  echo
  echo "The following arguments are available."
  echo "  -h, --help        Print this help and exit."
  echo "  -v, --version     Print the version and exit."
  echo "  -i, --install     Install all packages from ${SCRIPT_DIR}/packages/."
  echo "  -c, --custom      Specify a custom packages directory from which to install."
  echo
  echo "Examples:"
  echo "${SCRIPT_NAME} -h"
  echo
  echo "${SCRIPT_NAME} -v"
  echo
  echo "${SCRIPT_NAME} -i"
  echo
  echo "${SCRIPT_NAME} -c ./path/to/packages"
  echo
}	# ----------  end of function usage  ----------


linuxDistro ()
{
  #---  FUNCTION  ----------------------------------------------------------------
  #          NAME:  linuxDistro
  #   DESCRIPTION:  Export the detected values to be used in other scripts.
  #    PARAMETERS:  None
  #       RETURNS:  None
  #-------------------------------------------------------------------------------
  export {linux_distribution,linux_release,linux_codename}
  linux_distro=(
    "${linux_distribution}"
    "${linux_release}"
    "${linux_codename}"
      )
  export linux_distro
}	# ----------  end of function linuxDistro  ----------


pythonPlatform ()
{
  #---  FUNCTION  ----------------------------------------------------------------
  #          NAME:  pythonPlatform
  #   DESCRIPTION:  Looks for python and if found, uses it to detect information
  #                 about the distribution.
  #    PARAMETERS:  0, 1, or 2
  #       RETURNS:  0 = Linux distribution
  #                 1 = Distribution release
  #                 2 = Distribution codename
  #-------------------------------------------------------------------------------
  if which python &>/dev/null; then
    local py_path
    py_path=$(which python)
  elif which python3 &> /dev/null; then
    local py_path
    py_path=$(which python3)
  else
    return 1
  fi
  "${py_path}" -c \
  "import platform as p; dist = p.linux_distribution()[$1]; print(dist.lower())"
}	# ----------  end of function pythonPlatform  ----------


platformDetect ()
{
  #---  FUNCTION  ----------------------------------------------------------------
  #          NAME:  platformDetect
  #   DESCRIPTION:  Calls the pythonPlatform function and applies the values to
  #                 the variables linux_distribution, linux_release, and
  #                 linux_codename.
  #    PARAMETERS:  None
  #       RETURNS:  None
  #-------------------------------------------------------------------------------
  linux_distribution="$(pythonPlatform 0)"
  linux_release="$(pythonPlatform 1)"
  linux_codename="$(pythonPlatform 2)"
  linuxDistro
}	# ----------  end of function platformDetect  ----------


lsbRelease ()
{
  #---  FUNCTION  ----------------------------------------------------------------
  #          NAME:  lsbRelease
  #   DESCRIPTION:  Detects distribution information using lsb_release &
  #                 sets the variables linux_distribution, linux_release, &
  #                 linux_codename.
  #    PARAMETERS:  None
  #       RETURNS:  None
  #-------------------------------------------------------------------------------
  if ! which lsb_release &>/dev/null; then
    return 1
  fi
  linux_distribution="$(lsb_release --id | awk -F: '{print tolower($2)}' | xargs)"
  linux_release="$(lsb_release --release | awk -F: '{print tolower($2)}' | xargs)"
  linux_codename="$(lsb_release --codename | awk -F: '{print tolower($2)}' | xargs)"
  linuxDistro
}	# ----------  end of function lsbRelease  ----------


osRelease ()
{
  #---  FUNCTION  ----------------------------------------------------------------
  #          NAME:  osRelease
  #   DESCRIPTION:  Detects distribution information using /etc/os-release &
  #                 sets the variables linux_distribution, linux_release, &
  #                 linux_codename.
  #    PARAMETERS:  None
  #       RETURNS:  None
  #-------------------------------------------------------------------------------
  if [ ! -e "${linux_release_file}" ]; then
    return 1
  fi
  # shellcheck source=/etc/os-release
  source "${linux_release_file}"
  linux_distribution="${NAME,,}"
  linux_release="${VERSION_ID,,}"
  linux_codename=
  linuxDistro
}	# ----------  end of function osRelease  ----------


redHatDistro ()
{
  #---  FUNCTION  ----------------------------------------------------------------
  #          NAME:  redHatDistro
  #   DESCRIPTION:  Detects distribution information using /etc/redhat-release &
  #                 sets the variables linux_distribution, linux_release, &
  #                 linux_codename.
  #    PARAMETERS:  None
  #       RETURNS:  None
  #-------------------------------------------------------------------------------
  if [ ! -e "${redhat_file}" ]; then
    return 1
  fi
  for distro in "${redhat_distros[@]}"; do
    if egrep -io "${distro}" "${redhat_file}" &>/dev/null; then
      linux_distribution="$(grep -io "${distro}" "${redhat_file}")"
      linux_release="$(grep -io '[0-9]*' "${redhat_file}")"
      linux_codename="$(grep -ioP '(?<=\().*(?=\))' "${redhat_file}")"
      linuxDistro
    fi
  done
}	# ----------  end of function redHatDistro  ----------


debianDistro ()
{
  #---  FUNCTION  ----------------------------------------------------------------
  #          NAME:  debianDistro
  #   DESCRIPTION:
  #    PARAMETERS:
  #       RETURNS:
  #-------------------------------------------------------------------------------
  echo "Feature not yet implemented."
}	# ----------  end of function debianDistro  ----------


unknownDistro ()
{
  #---  FUNCTION  ----------------------------------------------------------------
  #          NAME:  unknownDistro
  #   DESCRIPTION:  Returns a message that the distribution is unknown & sets the
  #                 variables linux_distribution, linux_release, & linux_codename
  #                 to "Unknown".
  #    PARAMETERS:  None
  #       RETURNS:  "Unable to detect linux distribution."
  #-------------------------------------------------------------------------------
  echo "Unable to detect linux distribution."
  export {linux_distribution,linux_release,linux_codename}="Unknown"
  linuxDistro
}	# ----------  end of function unknownDistro  ----------


rpmPackageQuery ()
{
  #---  FUNCTION  ----------------------------------------------------------------
  #          NAME:  rpmPackageQuery
  #   DESCRIPTION:  Uses rpm to detect if [PACKAGE_NAME] are installed.
  #    PARAMETERS:  [PACKAGE_NAME]
  #       RETURNS:  Exit status
  #-------------------------------------------------------------------------------
  if rpm -q "$@" &>/dev/null; then
    return 0
  else
    return 1
  fi
}	# ----------  end of function rpmPackageQuery  ----------


rpmPackageInstall ()
{
  #---  FUNCTION  ----------------------------------------------------------------
  #          NAME:  rpmPackageInstall
  #   DESCRIPTION:  Installs [PACKAGES_LIST] using dnf or yum.
  #    PARAMETERS:  [PACKAGES_LIST]
  #       RETURNS:  None
  #-------------------------------------------------------------------------------
  if which dnf &>/dev/null; then
    sudo dnf -y install "$@"
  else
    sudo yum -y install "$@"
  fi
}	# ----------  end of function rpmPackageInstall  ----------


debPackageQuery ()
{
  #---  FUNCTION  ----------------------------------------------------------------
  #          NAME:  debPackageQuery
  #   DESCRIPTION:  Uses dpkg to detect if [PACKAGE_NAME] are installed.
  #    PARAMETERS:  [PACKAGE_NAME]
  #       RETURNS:  Exit status
  #-------------------------------------------------------------------------------
  if dpkg -s "$@" &>/dev/null; then
    return 0
  else
    return 1
  fi
}	# ----------  end of function debPackageQuery  ----------


debPackageInstall ()
{
  #---  FUNCTION  ----------------------------------------------------------------
  #          NAME:  debPackageInstall
  #   DESCRIPTION:  Installs [PACKAGES_LIST] using apt or apt-get.
  #    PARAMETERS:  [PACKAGES_LIST]
  #       RETURNS:  None
  #-------------------------------------------------------------------------------
  if which apt &>/dev/null; then
    sudo apt -y install "$@"
  else
    sudo apt-get -y install "$@"
  fi
}	# ----------  end of function debPackageInstall  ----------


archPackageQuery ()
{
  #---  FUNCTION  ----------------------------------------------------------------
  #          NAME:  archPackageQuery
  #   DESCRIPTION:  Uses pacman to detect if [PACKAGE_NAME] are installed.
  #    PARAMETERS:  [PACKAGE_NAME]
  #       RETURNS:  Exit status
  #-------------------------------------------------------------------------------
  if pacman -Qi "$@" &>/dev/null; then
    return 0
  else
    return 1
  fi
}	# ----------  end of function archPackageQuery  ----------


archPackageInstall ()
{
  #---  FUNCTION  ----------------------------------------------------------------
  #          NAME:  debPackageInstall
  #   DESCRIPTION:  Installs [PACKAGES_LIST] using apt or apt-get.
  #    PARAMETERS:  [PACKAGES_LIST]
  #       RETURNS:  None
  #-------------------------------------------------------------------------------
  sudo pacman --noconfirm -S "$@"
}	# ----------  end of function archPackageInstall  ----------


rpmRepoSetup ()
{
  #---  FUNCTION  ----------------------------------------------------------------
  #          NAME:  rpmRepoSetup
  #   DESCRIPTION:  Install/Configure repositories for rpm based distros.
  #    PARAMETERS:  None
  #       RETURNS:  None
  #-------------------------------------------------------------------------------
  if rpm -q rpmfusion-free-release &>/dev/null; then
    return 0
  fi
  repo_rpms=(
    "https://download1.rpmfusion.org/free/${base_distro}/rpmfusion-free-release-${linux_release%%.*}.noarch.rpm"
    "https://download1.rpmfusion.org/nonfree/${base_distro}/rpmfusion-nonfree-release-${linux_release%%.*}.noarch.rpm"
      )
  if which dnf &>/dev/null; then
    sudo dnf install "${repo_rpms[@]}"
  else
    sudo yum install "${repo_rpms[@]}"
  fi
}	# ----------  end of function rpmRepoSetup  ----------


debRepoSetup ()
{
  #---  FUNCTION  ----------------------------------------------------------------
  #          NAME:  debRepoSetup
  #   DESCRIPTION:  
  #    PARAMETERS:  
  #       RETURNS:  
  #-------------------------------------------------------------------------------
  echo "debRepoSetup feature not implemented yet."
}	# ----------  end of function debRepoSetup  ----------


archRepoSetup ()
{
  #---  FUNCTION  ----------------------------------------------------------------
  #          NAME:  archRepoSetup
  #   DESCRIPTION:  
  #    PARAMETERS:  
  #       RETURNS:  
  #-------------------------------------------------------------------------------
  echo "archRepoSetup feature not implemented yet."
}	# ----------  end of function archRepoSetup  ----------


distroInfo ()
{
  #---  FUNCTION  ----------------------------------------------------------------
  #          NAME:  distroInfo
  #   DESCRIPTION:  Print distribution information.
  #    PARAMETERS:  None
  #       RETURNS:  Distribution information.
  #-------------------------------------------------------------------------------
  echo -en "${color1}supported_distros: ${color0}"
  printf '"%s" ' "${supported_distros[@]}"
  echo

  if [ -n "${linux_distribution}" ]; then
    echo -e "${color1}linux_distribution: ${color0}${linux_distribution}"
  fi

  if [ -n "${linux_release}" ]; then
    echo -e "${color1}linux_release: ${color0}${linux_release}"
  fi

  if [ -n "${linux_codename}" ]; then
    echo -e "${color1}linux_codename: ${color0}${linux_codename}"
  fi

  echo
}	# ----------  end of function distroInfo  ----------



#-------------------------------------------------------------------------------
# MAIN
#-------------------------------------------------------------------------------
# Detect distribution.
platformDetect || \
lsbRelease || \
osRelease || \
redHatDistro || \
unknownDistro


while [ -n "$1" ] ; do
  case "$1" in
    '-h' | '--help' )
      usage
      distroInfo
      exit 0
      ;;

    '-v' | '--version' )
      version
      exit 0
      ;;

    '-i' | '--install' )
      break
      ;;

    '-c' | '--custom' )
      shift
      pkgs_dir="$1"
      break
      ;;

    *)
      usage
      except "Invalid argument $1."
      ;;

    esac    # --- end of case ---
done


case "${linux_distribution}" in
  'arch' | 'arch linux' | 'antergos linux' )
    base_distro='arch'
    alias pkgQuery=archPackageQuery
    alias pkgInstall=archPackageInstall
    alias repoSetup=archRepoSetup

    # Get list of packages to install.
    pkgs=($(
      grep -h "${base_distro}" -R "${pkgs_dir}/" \
        | awk -F: '{ print $2 }'
    ))
    ;;

  'centos' | 'centos linux' )
    base_distro='el'
    alias pkgQuery=rpmPackageQuery
    alias pkgInstall=rpmPackageInstall
    alias repoSetup=rpmRepoSetup

    # Get list of packages to install.
    pkgs=($(
      grep -h "${base_distro}${linux_release%%.*}" -R "${pkgs_dir}/" \
        | awk -F: '{ print $2 }'
    ))
    ;;

  'fedora' )
    base_distro='fedora'
    alias pkgQuery=rpmPackageQuery
    alias pkgInstall=rpmPackageInstall
    alias repoSetup=rpmRepoSetup

    # Get list of packages to install.
    pkgs=($(
      grep -h "${base_distro}${linux_release%%.*}" -R "${pkgs_dir}/" \
        | awk -F: '{ print $2 }'
    ))
    ;;

  'debian' )
    base_distro='debian'
    alias pkgQuery=debPackageQuery
    alias pkgInstall=debPackageInstall
    alias repoSetup=debRepoSetup

    # Get list of packages to install.
    pkgs=($(
      grep -h "${base_distro}" -R "${pkgs_dir}/" \
        | awk -F: '{ print $2 }'
    ))
    ;;

  'ubuntu' )
    base_distro='ubuntu'
    alias pkgQuery=debPackageQuery
    alias pkgInstall=debPackageInstall
    alias repoSetup=debRepoSetup

    # Get list of packages to install.
    pkgs=($(
      grep -h "${base_distro}${linux_release}" -R "${pkgs_dir}/" \
        | awk -F: '{ print $2 }'
    ))
    ;;

  'unknown' )
    except "Unknown distro.  Exiting..."
    ;;

esac    # --- end of case ---


# Install repositories.
repoSetup || except "Failed to setup repositories for ${linux_distribution}."



## Check if packages are installed already.
for i in "${!pkgs[@]}"; do
  pkg_name=${pkgs[$i]}
  if pkgQuery "$pkg_name" &>/dev/null; then
    unset pkgs["$i"]
  fi
done


## Install the remaining packages.
if [ -n "${pkgs[*]}" ]; then
  echo "The following packages will be installed: ${pkgs[*]}"
  pkgInstall "${pkgs[@]}" || except "Failed to install packages for ${linux_distribution}."
fi

echo "All packages installed."
exit 0
