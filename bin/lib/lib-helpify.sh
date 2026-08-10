#!/bin/bash

# Set Library Name
LIB_NAME="lib-helpify.sh"

# Check if STACK_DIR is set
if [[ ! "${STACK_DIR}" ]]; then
  echo "Please define 'STACK_DIR' variable"; exit 1
fi

# Check if lib-core.sh is already imported
if [[ "${PROCESS_SOURCE[*]}" =~ $LIB_NAME ]]; then
  echo "Warning! '${LIB_NAME}' is already imported"; exit 1
fi

# Add lib-core.sh to the list of imported files
PROCESS_SOURCE=("$LIB_NAME")

# ---------------------------------------------------------------------
# Helpify
# ---------------------------------------------------------------------

helpify_title() {
  local STACK_COMMAND_NAME="$(basename "${0}")"
  printf "  ${c_cyan}%s${c_blue}%s ${c_blue}%s ${c_green}%s\n\n" "Usage: " "$STACK_COMMAND_NAME" "$1" "$2"
}

helpify_subtitle() {
  printf "  ${c_cyan}%s\n${c_default}" "$1"
}

helpify_subcommand_title() {
  printf "  ${c_cyan}%s${c_red}%s ${c_red}%s ${c_green}%s\n\n${c_default}" "Usage: " "$1" "$2" "$3"
  printf "  ${c_cyan}%s\n${c_default}" "COMMANDS:"
}

helpify_separator() {
  printf "\n"
}

helpify() {
  printf "    ${c_blue}%-20s ${c_green}%-60s ${c_magenta}%s\n${c_default}" "${1}" "${2}" "${3}"
}