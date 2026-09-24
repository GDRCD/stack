#!/usr/bin/env bash

if [ -z "${BASH_VERSION:-}" ]; then
  printf '%s\n' "Error: this script must be run with Bash." >&2
  exit 1
fi
if [ "${BASH_VERSINFO[0]}" -lt 3 ] || {
  [ "${BASH_VERSINFO[0]}" -eq 3 ] && [ "${BASH_VERSINFO[1]}" -lt 2 ];
}; then
  printf 'Error: Bash 3.2 or newer is required, found %s.\n' "${BASH_VERSION}" >&2
  exit 1
fi

set -Eeo pipefail

REPOSITORY="GDRCD/stack"
TARGET=""
VERSION_TAG=""
FORCE_INSTALL="false"
STAGING=""
VERSION_TEMP=""

if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  C_DEFAULT=$'\033[0m'; C_CYAN=$'\033[1;36m'; C_GREEN=$'\033[1;32m'; C_RED=$'\033[1;31m'
else
  C_DEFAULT=""; C_CYAN=""; C_GREEN=""; C_RED=""
fi

prompt() {
  local color="${C_CYAN}" stream=1
  case "$1" in success) color="${C_GREEN}" ;; error) color="${C_RED}"; stream=2 ;; info) ;; *) return 2 ;; esac
  printf '  %b%s%b\n' "${color}" "$2" "${C_DEFAULT}" >&"${stream}"
}

usage() {
  cat <<'EOF'

  Usage: ./boot.sh [OPTIONS...] [TARGET]

  Download and unpack the GDRCD development stack.

  ARGUMENTS:
    TARGET               Directory to unpack into [default: ./stack]

  OPTIONS:
    -h, --help           Show this help
    -v, --version TAG    Install a specific release (e.g. v4.1.0)
    -f, --force          Unpack even if the target directory is not empty

EOF
}

is_release_version() {
  local core='(0|[1-9][0-9]*)' prerelease='((0|[1-9][0-9]*)|[0-9]*[A-Za-z-][0-9A-Za-z-]*)'
  [[ "$1" =~ ^v${core}\.${core}\.${core}(-${prerelease}(\.${prerelease})*)?(\+[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*)?$ ]]
}

latest_version() {
  local url version
  url="$(curl -fsSL -o /dev/null -w '%{url_effective}' "https://github.com/${REPOSITORY}/releases/latest")" || return 1
  version="${url##*/}"
  is_release_version "${version}" || return 1
  printf '%s\n' "${version}"
}

validate_target() {
  [[ ! -e "${TARGET}" ]] && return
  [[ -d "${TARGET}" ]] || { prompt error "Target path is not a directory: ${TARGET}"; return 1; }
  [[ ! -f "${TARGET}/.env" ]] || { prompt error "Target already holds a stack; use './stack upgrade' from inside it."; return 1; }
  if [[ -n "$(ls -A "${TARGET}" 2>/dev/null)" && "${FORCE_INSTALL}" != "true" ]]; then
    prompt error "Target path is not empty; use --force to unpack into it."
    return 1
  fi
}

validate_release() {
  local root="$1" commands=("$1"/bin/commands/*)
  [[ -f "${root}/stack" && -f "${root}/boot.sh" && -f "${root}/sample.env" ]] || return 1
  [[ -f "${root}/.docker/compose.yml" && -f "${commands[0]}" ]] || return 1
}

cleanup() {
  [[ -z "${VERSION_TEMP}" || ! -e "${VERSION_TEMP}" ]] || rm -f -- "${VERSION_TEMP}"
  [[ -z "${STAGING}" || ! -d "${STAGING}" ]] || rm -rf -- "${STAGING}"
}
trap cleanup EXIT

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h | --help) usage; exit 0 ;;
    -v | --version)
      [[ $# -ge 2 && -n "$2" && "$2" != -* ]] || { prompt error "Option '$1' requires a tag."; exit 2; }
      VERSION_TAG="$2"; shift 2
      ;;
    -f | --force) FORCE_INSTALL="true"; shift ;;
    -*) prompt error "Unrecognized option: $1"; exit 2 ;;
    *) [[ -z "${TARGET}" ]] || { prompt error "Only one target directory may be specified."; exit 2; }; TARGET="$1"; shift ;;
  esac
done

TARGET="${TARGET:-stack}"
[[ -z "${VERSION_TAG}" ]] || is_release_version "${VERSION_TAG}" || { prompt error "Invalid release tag: ${VERSION_TAG}"; exit 2; }
command -v curl >/dev/null 2>&1 || { prompt error "curl is not installed."; exit 1; }
command -v tar >/dev/null 2>&1 || { prompt error "tar is not installed."; exit 1; }
validate_target

if [[ -z "${VERSION_TAG}" ]]; then
  VERSION_TAG="$(latest_version)" || { prompt error "Unable to determine the latest release."; exit 1; }
fi

STAGING="$(mktemp -d "${TMPDIR:-/tmp}/gdrcd-stack.XXXXXX")"
prompt info "Downloading ${VERSION_TAG}..."
if ! curl -fsSL "https://github.com/${REPOSITORY}/archive/refs/tags/${VERSION_TAG}.tar.gz" |
  tar -xzf - -C "${STAGING}" --strip-components=1; then
  prompt error "Unable to download or extract ${VERSION_TAG}."
  exit 1
fi
validate_release "${STAGING}" || { prompt error "Downloaded archive is incomplete."; exit 1; }

prompt info "Installing ${VERSION_TAG} in ${TARGET}..."
mkdir -p "${TARGET}"
cp -R "${STAGING}/." "${TARGET}/"
[[ -f "${TARGET}/.env" ]] || cp "${TARGET}/sample.env" "${TARGET}/.env"
mkdir -p "${TARGET}/www" "${TARGET}/logs/nginx" "${TARGET}/logs/database"
VERSION_TEMP="$(mktemp "${TARGET}/.version.tmp.XXXXXX")"
printf '%s\n' "${VERSION_TAG}" >"${VERSION_TEMP}"
mv -f -- "${VERSION_TEMP}" "${TARGET}/.version"
VERSION_TEMP=""
chmod +x "${TARGET}/stack" "${TARGET}/boot.sh" "${TARGET}"/bin/commands/*
prompt success "Installation completed: ${TARGET}"
