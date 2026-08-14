#!/bin/bash

set -Eeo pipefail

# Check if STACK_DIR is set
if [[ ! "${STACK_DIR}" ]]; then
  echo "Please define 'STACK_DIR' variable"
  exit 1
fi

# Libraries already imported
PROCESS_SOURCE=()

# ---------------------------------------------------------------------
# Variables
# ---------------------------------------------------------------------

#------------Directories--------------#
BIN_DIR="${STACK_DIR}/bin"
LIB_DIR="${STACK_DIR}/bin/lib"
COMMANDS_DIR="${STACK_DIR}/bin/commands"
DOCKER_DIR="${STACK_DIR}/.docker"

#------------Decoration-----------#
export c_default="\033[0m"
export c_blue="\033[1;34m"
export c_magenta="\033[1;35m"
export c_cyan="\033[1;36m"
export c_green="\033[1;32m"
export c_red="\033[1;31m"
export c_yellow="\033[1;33m"

#------------Trigger-----------#
need_help="false"
need_usage4help="false"
has_any_error="false"

# Set the command name
STACK_COMMAND_NAME="$(basename "${0}")"

# ---------------------------------------------------------------------
# Utilities
# ---------------------------------------------------------------------

# Check if a value is present in the given list (exact match)
containsValue() {
  local needle=$1; shift

  for item in "$@"; do
    if [[ "$item" == "$needle" ]]; then
      return 0
    fi
  done

  return 1
}

# Check if env file exists
isEnvFileExists() {
  if [[ ! -f "${STACK_DIR}/.env" ]]; then
    prompt -e "Error! '.env' file is not found. Please create it first."
    exit 1
  fi
}

# ---------------------------------------------------------------------
# Import Libraries
# ---------------------------------------------------------------------

importLib() {
  # Check if library exists
  if [[ ! -f "${BIN_DIR}/${1}" ]]; then
    prompt -e "Error! '${1}' is not found."
    exit 1
  fi

  # Check if library is already imported, if not import it
  if ! containsValue "${1}" "${PROCESS_SOURCE[@]}"; then
    # shellcheck source=bin/lib/lib-core.sh
    source "${BIN_DIR}/${1}"
    PROCESS_SOURCE+=("${1}")
  fi
}
