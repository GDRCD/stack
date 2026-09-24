#!/usr/bin/env bash
# shellcheck disable=SC2034 # Constants are consumed by separately sourced modules.

if [[ -z "${STACK_DIR:-}" ]]; then
  printf '%s\n' "Please define 'STACK_DIR' variable" >&2
  exit 1
fi

readonly BIN_DIR="${STACK_DIR}/bin"
readonly COMMANDS_DIR="${BIN_DIR}/commands"
readonly DOCKER_DIR="${STACK_DIR}/.docker"
readonly WWW_DIR="${STACK_DIR}/www"

if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  readonly c_default=$'\033[0m'
  readonly c_blue=$'\033[1;34m'
  readonly c_magenta=$'\033[1;35m'
  readonly c_cyan=$'\033[1;36m'
  readonly c_green=$'\033[1;32m'
  readonly c_red=$'\033[1;31m'
  readonly c_yellow=$'\033[1;33m'
else
  readonly c_default=""
  readonly c_blue=""
  readonly c_magenta=""
  readonly c_cyan=""
  readonly c_green=""
  readonly c_red=""
  readonly c_yellow=""
fi

_STACK_IMPORTED_LIBS=("lib/lib-core.sh")

importLib() {
  local library="${1:-}"
  local imported

  if [[ -z "${library}" || ! -f "${BIN_DIR}/${library}" ]]; then
    printf "Error! Library '%s' was not found.\n" "${library}" >&2
    exit 1
  fi

  for imported in "${_STACK_IMPORTED_LIBS[@]}"; do
    [[ "${imported}" == "${library}" ]] && return 0
  done

  _STACK_IMPORTED_LIBS+=("${library}")
  # shellcheck source=/dev/null
  source "${BIN_DIR}/${library}"
}

require_option_value() {
  local option="${1:-}"
  local value="${2:-}"

  if [[ -z "${value}" || "${value}" == -* ]]; then
    prompt -e "Option '${option}' requires a value."
    return 2
  fi
}

canonicalize_path() {
  local path="$1" directory
  while [[ -L "${path}" ]]; do
    directory="$(cd -P "$(dirname "${path}")" >/dev/null 2>&1 && pwd)" || return 1
    path="$(readlink "${path}")"
    [[ "${path}" != /* ]] && path="${directory}/${path}"
  done
  directory="$(cd -P "$(dirname "${path}")" >/dev/null 2>&1 && pwd)" || return 1
  printf '%s/%s\n' "${directory}" "$(basename "${path}")"
}

isReleaseVersion() {
  [[ "$1" =~ ^v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-[0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$ ]]
}

stackVersion() {
  local version
  if [[ -e "${STACK_DIR}/.git" ]]; then
    command -v git >/dev/null 2>&1 || return 1
    git -C "${STACK_DIR}" describe --tags --always --dirty 2>/dev/null
    return
  fi
  [[ -r "${STACK_DIR}/.version" ]] || return 1
  version="$(head -n 1 "${STACK_DIR}/.version" | tr -d '[:space:]')"
  isReleaseVersion "${version}" || return 1
  printf '%s\n' "${version}"
}
