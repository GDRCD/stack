#!/usr/bin/env bash

set -Eeo pipefail

# ---------------------------------------------------------------------
# Variables
# ---------------------------------------------------------------------

# Repository to install from
REPO="GDRCD/stack"

#------------Decoration-----------#
c_default="\033[0m"
c_cyan="\033[1;36m"
c_green="\033[1;32m"
c_red="\033[1;31m"
c_magenta="\033[1;35m"

# Commands variables
target=""
target_default="stack"
version_tag=""
force_install="false"

# ---------------------------------------------------------------------
# Messages
# ---------------------------------------------------------------------

MESSAGE_INSTALL_START="Starting installation"
MESSAGE_INSTALL_SUCCESS="Installation completed!"

MESSAGE_UNKNOWN_OPTION="Unrecognized option"
MESSAGE_NOT_BASH="This script must be run with bash"
MESSAGE_BASH_TOO_OLD="bash 3.2 or newer is required, found"
MESSAGE_CURL_NOT_INSTALLED="'curl' is not installed, please install it first"
MESSAGE_TAR_NOT_INSTALLED="'tar' is not installed, please install it first"
MESSAGE_TARGET_NOT_DIRECTORY="Target path is not a directory, please check the path"
MESSAGE_TARGET_NOT_EMPTY="Target path is not empty, use the '-f' option to unpack into it anyway"
MESSAGE_TARGET_INSTALLED="Target path already holds a stack, use './stack upgrade' from inside it"
MESSAGE_VERSION_NOT_RESOLVED="Cannot reach GitHub to resolve the latest release"
MESSAGE_DOWNLOAD_FAILED="Cannot download the release, please check that the version exists"
MESSAGE_ARCHIVE_INCOMPLETE="The downloaded archive is incomplete"

# ---------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------

# Echo a message in a specific color
prompt() {
  case "${1}" in
    "-s")
      echo -e "  ${c_green}${2}${c_default}" ;;
    "-e")
      echo -e "  ${c_red}Error: ${2}${c_default}" >&2 ;;
    "-i")
      echo -e "  ${c_cyan}${2}${c_default}" ;;
    "-t")
      echo -e "  ${c_magenta}${2}${c_default}" ;;
  esac
}

# Function for showing usage of this script
usage() {
  cat <<'EOF'

  Usage: ./boot.sh [OPTIONS...] [TARGET]

  Download and unpack the GDRCD development stack.

  ARGUMENTS:
    TARGET               Directory to unpack into [default: ./stack]

  OPTIONS:
    -h, --help           Show this help
    -v, --version <tag>  Install a specific release (e.g. v2.3.1)
    -f, --force          Unpack even if the target directory is not empty

EOF
}

# Check if the script is being run with a supported bash
isBashSupported() {
  if [[ -z "${BASH_VERSION}" ]]; then
    prompt -e "${MESSAGE_NOT_BASH}"
    exit 1
  fi

  if [ "${BASH_VERSINFO[0]}" -lt 3 ] ||
    { [ "${BASH_VERSINFO[0]}" -eq 3 ] && [ "${BASH_VERSINFO[1]}" -lt 2 ]; }; then
    prompt -e "${MESSAGE_BASH_TOO_OLD} ${BASH_VERSION}"
    exit 1
  fi
}

# Check if curl is installed
isCurlInstalled() {
  if ! command -v curl &> /dev/null; then
    prompt -e "${MESSAGE_CURL_NOT_INSTALLED}"
    exit 1
  fi
}

# Check if tar is installed
isTarInstalled() {
  if ! command -v tar &> /dev/null; then
    prompt -e "${MESSAGE_TAR_NOT_INSTALLED}"
    exit 1
  fi
}

# Check if the target path is available
isTargetAvailable() {
  if [[ ! -e "${target}" ]]; then
    return 0
  fi

  if [[ ! -d "${target}" ]]; then
    prompt -e "${MESSAGE_TARGET_NOT_DIRECTORY}"
    exit 1
  fi

  if [[ -f "${target}/.env" ]]; then
    prompt -e "${MESSAGE_TARGET_INSTALLED}"
    exit 1
  fi

  if [[ -n "$(ls -A "${target}" 2> /dev/null)" ]] && [[ "${force_install}" != "true" ]]; then
    prompt -e "${MESSAGE_TARGET_NOT_EMPTY}"
    exit 1
  fi
}

# Get the latest release tag
getLatestVersion() {
  local url tag

  url="$(curl -fsSL -o /dev/null -w '%{url_effective}' "https://github.com/${REPO}/releases/latest")" || return 1

  tag="${url##*/}"
  case "${tag}" in
    v[0-9]*)
      echo "${tag}" ;;
    *)
      return 1 ;;
  esac
}

# ---------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------

#---------------------------PARSE ARGUMENTS-------------------------------#

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "${1}" in
  -h | --help)
    usage
    exit 0
    ;;
  -v | --version)
    version_tag="${2}"
    shift
    shift
    ;;
  -f | --force)
    force_install="true"
    shift
    ;;
  -*)
    prompt -e "${MESSAGE_UNKNOWN_OPTION}: ${1}"
    usage
    exit 1
    ;;
  *)
    target="${1}"
    shift
    ;;
  esac
done

target="${target:-${target_default}}"

#---------------------------RUN COMMAND-------------------------------#

boot() {
  # Preliminary checks
  isBashSupported
  isCurlInstalled
  isTarInstalled
  isTargetAvailable

  # Resolve the version to install
  if [[ -z "${version_tag}" ]]; then
    if ! version_tag="$(getLatestVersion)"; then
      prompt -e "${MESSAGE_VERSION_NOT_RESOLVED}"
      exit 1
    fi
  fi

  prompt -t "${MESSAGE_INSTALL_START}: ${version_tag} in ${target}"

  # Unpack into a staging directory first
  local staging
  staging="$(mktemp -d)"
  # shellcheck disable=SC2064
  trap "rm -rf '${staging}'" EXIT

  prompt -i "Downloading ${version_tag}..."
  if ! curl -fsSL "https://github.com/${REPO}/archive/refs/tags/${version_tag}.tar.gz" 2> /dev/null |
    tar -xzf - -C "${staging}" --strip-components=1 2> /dev/null; then
    prompt -e "${MESSAGE_DOWNLOAD_FAILED}"
    exit 1
  fi

  # Check the archive is complete
  local entry
  for entry in stack bin .docker; do
    if [[ ! -e "${staging}/${entry}" ]]; then
      prompt -e "${MESSAGE_ARCHIVE_INCOMPLETE}: '${entry}' is missing"
      exit 1
    fi
  done

  prompt -i "Unpacking..."
  mkdir -p "${target}"
  # The trailing '/.' copies dotfiles too
  cp -R "${staging}/." "${target}/"

  # Create .env, sourced unconditionally at startup
  if [[ ! -f "${target}/.env" ]]; then
    cp "${target}/sample.env" "${target}/.env"
    prompt -i "Created .env from sample.env"
  fi

  # Ensure the user directories exist
  mkdir -p "${target}/www" "${target}/logs/nginx" "${target}/logs/database"

  # Save the installed version, read back by 'upgrade'
  echo "${version_tag}" > "${target}/.version"

  # Set the permissions
  chmod +x "${target}/stack"
  chmod +x "${target}"/bin/commands/*

  prompt -s "${MESSAGE_INSTALL_SUCCESS}"
}

boot
