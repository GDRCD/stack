#!/usr/bin/env bash
# shellcheck disable=SC2034,SC2154 # Messages and colors are provided across sourced modules.

if [[ "${STACK_MESSAGES_LOADED:-false}" == "true" ]]; then
  return 0
fi
readonly STACK_MESSAGES_LOADED="true"

MESSAGE_NO_ARGUMENTS="No arguments passed!"

prompt() {
  local kind="${1:-}"
  local text="${2:-}"
  local color="${c_default}"
  local stream=1

  case "${kind}" in
    -s) color="${c_green}" ;;
    -e)
      color="${c_red}"
      stream=2
      ;;
    -w) color="${c_yellow}" ;;
    -i) color="${c_cyan}" ;;
    -il) color="${c_blue}" ;;
    -t) color="${c_magenta}" ;;
    *)
      printf "Unknown prompt type: %s\n" "${kind}" >&2
      return 2
      ;;
  esac

  printf '  %b%s%b\n' "${color}" "${text}" "${c_default}" >&"${stream}"
}

message() {
  local kind="${1:-}"
  local text="${2:-}"

  if [[ -z "${text}" ]]; then
    prompt -e "Message is not set"
    return 2
  fi

  case "${kind}" in
    --error) prompt -e "Error: ${text}" ;;
    --warning) prompt -w "${text}" ;;
    --info) prompt -i "${text}" ;;
    --info-status) prompt -il "${text}" ;;
    --success) prompt -s "${text}" ;;
    --stack) prompt -t "${text}" ;;
    *)
      prompt -e "Message type '${kind}' is not valid"
      return 2
      ;;
  esac
}
