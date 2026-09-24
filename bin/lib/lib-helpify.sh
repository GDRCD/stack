#!/usr/bin/env bash
# shellcheck disable=SC2154 # Color constants are defined by lib-core.sh.

helpify_title() {
  local command_name="${STACK_COMMAND_NAME:-$(basename "$0")}"
  printf '  %bUsage: %b%s %b%s %b%s%b\n\n' \
    "${c_cyan}" "${c_blue}" "${command_name}" "${c_blue}" "${1:-}" "${c_green}" "${2:-}" "${c_default}"
}

helpify_subtitle() {
  printf '  %b%s%b\n' "${c_cyan}" "${1:-}" "${c_default}"
}

helpify_separator() {
  printf '\n'
}

helpify() {
  printf '    %b%-20s %b%-60s %b%s%b\n' \
    "${c_blue}" "${1:-}" "${c_green}" "${2:-}" "${c_magenta}" "${3:-}" "${c_default}"
}
