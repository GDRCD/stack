#!/usr/bin/env bash
# shellcheck disable=SC2034,SC2154 # Messages and colors are provided across sourced modules.

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
    *)
      printf "Unknown prompt type: %s\n" "${kind}" >&2
      return 2
      ;;
  esac

  printf '  %b%s%b\n' "${color}" "${text}" "${c_default}" >&"${stream}"
}
