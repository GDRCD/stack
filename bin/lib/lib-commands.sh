#!/bin/bash

# ---------------------------------------------------------------------
# Variables
# ---------------------------------------------------------------------

# ---------------------------------------------------------------------
# Commands
# ---------------------------------------------------------------------

# check if is a command
isCommand() {
  case "${1}" in
    "--abs-path")
      ([[ -f "$2" ]] && command -v "$2") >/dev/null 2>&1;;
    *)
      ([[ -f "${COMMANDS_DIR}/$1" ]] && command -v "${COMMANDS_DIR}/$1") >/dev/null 2>&1;;
  esac
}

# ---------------------------------------------------------------------
# Usage
# ---------------------------------------------------------------------

# Show commands for $STACK_COMMAND_NAME
usageCommands () {
  helpify_subtitle "COMMANDS:";

  # scan bin directory for commands
  for command in "${COMMANDS_DIR}"/*; do
    # skip non-executable files
    if [[ ! -x "${command}" ]]; then
      continue
    fi

    # skip directories
    if [[ -d "${command}" ]]; then
      continue
    fi

    # check if is a command
    if ! isCommand --abs-path "${command}"; then
      continue
    fi

    # execute command to get usage
    # shellcheck disable=SC1090
    source "${command}"
  done
}

messageUnknownCommand () {
  # show error
  prompt -e "Unknown argument: $2";
  prompt -i "Try '${STACK_COMMAND_NAME} $1 --help' for more information.";
}

# ---------------------------------------------------------------------
# Misc
# ---------------------------------------------------------------------

finalize_argument_parsing() {
  # Argument parsing failed
  if [[ "${has_any_error}" == "true" ]]; then
    prompt -i "Try '${STACK_COMMAND_NAME} --help' for more information."
    exit 1
  fi

  if [[ "${need_help}" != "true" ]]; then
    return 0
  fi

  # Sourced to build the command list: print the single line entry and continue
  if [[ "${need_commands_list}" == "true" ]]; then
    usage4help
    return 0
  fi

  usage
  exit 0
}
