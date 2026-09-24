#!/usr/bin/env bash

if [[ "${STACK_COMMANDS_LOADED:-false}" == "true" ]]; then return 0; fi
readonly STACK_COMMANDS_LOADED="true"

isCommand() {
  local path
  if [[ "${1:-}" == "--abs-path" ]]; then path="${2:-}"; else path="${COMMANDS_DIR}/${1:-}"; fi
  [[ -f "${path}" && -x "${path}" ]]
}

usageCommands() {
  local command_path command_name summary
  helpify_subtitle "COMMANDS:"
  for command_path in "${COMMANDS_DIR}"/*; do
    [[ -f "${command_path}" && -x "${command_path}" ]] || continue
    command_name="${command_path##*/}"
    command_metadata_read "${command_path}" summary || continue
    summary="${COMMAND_METADATA_VALUE//\{product\}/${STACK_PRODUCT_NAME}}"
    helpify "${command_name}" "${summary}"
  done
}

messageUnknownCommand() {
  prompt -e "Argomento non riconosciuto: ${2:-}"
  prompt -i "Prova '${STACK_COMMAND_NAME} ${1:-} --help'."
}
