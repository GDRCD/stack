#!/usr/bin/env bash

isCommand() {
  [[ -f "${COMMANDS_DIR}/${1:-}" && -x "${COMMANDS_DIR}/${1:-}" ]]
}

usageCommands() {
  local command_path command_name
  helpify_subtitle "COMMANDS:"
  for command_path in "${COMMANDS_DIR}"/*; do
    [[ -f "${command_path}" && -x "${command_path}" ]] || continue
    command_name="${command_path##*/}"
    command_metadata_read "${command_path}" summary || continue
    helpify "${command_name}" "${COMMAND_METADATA_VALUE}"
  done
}

messageUnknownCommand() {
  prompt -e "Argomento non riconosciuto: ${2:-}"
  prompt -i "Prova '${STACK_COMMAND_NAME} ${1:-} --help'."
}
