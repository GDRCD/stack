#!/bin/bash

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