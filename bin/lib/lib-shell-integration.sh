#!/usr/bin/env bash
# shellcheck disable=SC2016 # This file intentionally emits unexpanded shell source.

validate_shell_integration_name() { [[ "$1" =~ ^[[:alpha:]_][[:alnum:]_-]*$ ]]; }
shell_integration_path_is_safe() {
  case "$1" in
    *$'\n'* | *$'\r'* | *'"'* | *'`'* | *'$'* | *\\*) return 1 ;;
    *) return 0 ;;
  esac
}

render_bash_completion() {
  local command_name="$1" function_name="_${1//[^[:alnum:]_]/_}_completion"
  printf '%s() {\n' "${function_name}"
  printf '  local candidate\n  COMPREPLY=()\n'
  printf '  while IFS= read -r candidate; do\n    [ -n "$candidate" ] && COMPREPLY+=("$candidate")\n'
  printf '  done < <(command %s __complete "$((COMP_CWORD - 1))" "${COMP_WORDS[@]:1}")\n}\n' "${command_name}"
  printf 'complete -o bashdefault -o default -F %s %s\n' "${function_name}" "${command_name}"
}

render_zsh_completion() {
  local command_name="$1" function_name="_${1//[^[:alnum:]_]/_}_completion"
  printf '%s() {\n  local -a candidates\n' "${function_name}"
  printf '  candidates=("${(@f)$(command %s __complete "$((CURRENT - 2))" "${words[@]:1}")}")\n' "${command_name}"
  printf '  (( ${#candidates[@]} )) && compadd -- "${candidates[@]}"\n}\n'
  printf 'compdef %s %s\n' "${function_name}" "${command_name}"
}

render_shell_completion() {
  local command_name="$1" shell_name="$2"
  validate_shell_integration_name "${command_name}" || return 2
  case "${shell_name}" in bash) render_bash_completion "${command_name}" ;; zsh) render_zsh_completion "${command_name}" ;; *) return 2 ;; esac
}

render_shell_wrapper() {
  local command_name="$1"
  validate_shell_integration_name "${command_name}" || return 2
  printf '%s() {\n' "${command_name}"
  printf '  if [ "$#" -ge 1 ] && [ "$1" = "cd" ]; then\n    local stack_target_path\n'
  printf '    stack_target_path="$(command %s "$@")" || return $?\n' "${command_name}"
  printf '    if [ -z "$stack_target_path" ] || [ "${stack_target_path#/}" = "$stack_target_path" ] || [[ "$stack_target_path" == *$'\''\\n'\''* ]] || [ ! -d "$stack_target_path" ]; then\n'
  printf '      printf "Invalid target directory: %%s\\n" "$stack_target_path" >&2\n      return 1\n    fi\n'
  printf '    builtin cd -- "$stack_target_path"\n  else\n'
  printf '    command %s "$@"\n  fi\n}\n' "${command_name}"
}

render_shell_activation() {
  local command_name="$1" shell_name="$2" target="$3"
  shell_integration_path_is_safe "${target}" || return 2
  printf 'case ":$PATH:" in *":%s:"*) ;; *) export PATH="%s:$PATH" ;; esac\n' "${target}" "${target}"
  render_shell_wrapper "${command_name}" && render_shell_completion "${command_name}" "${shell_name}"
}

shell_startup_file() { case "$1" in bash) printf '%s/.bashrc\n' "${HOME}" ;; zsh) printf '%s/.zshrc\n' "${HOME}" ;; *) return 2 ;; esac }

_rewrite_shell_activation() {
  local rc_file="$1" command_name="$2" mode="$3" destination="${4:-}" shell_name="${5:-}"
  local temporary marker="# ${command_name} shell integration"
  temporary="$(mktemp "${rc_file}.tmp.XXXXXX")" || return 1
  cp -p -- "${rc_file}" "${temporary}"
  awk -v marker="${marker}" '
    substr($0, length($0) - length(marker) + 1) != marker { print }
  ' "${rc_file}" > "${temporary}"
  if [[ "${mode}" == "install" ]]; then
    printf '\neval "$("%s" activate %s)" %s\n' "${destination}" "${shell_name}" "${marker}" >> "${temporary}"
  fi
  mv -f -- "${temporary}" "${rc_file}"
}

install_shell_integration() {
  local command_name="$1" shell_name="$2" target="$3" rc_file destination
  rc_file="$(shell_startup_file "${shell_name}")" || return
  destination="${target}/${command_name}"
  if ! shell_integration_path_is_safe "${destination}"; then
    prompt -e "Shell integration paths contain unsupported characters."
    return 2
  fi
  mkdir -p -- "$(dirname "${rc_file}")"
  touch "${rc_file}"
  _rewrite_shell_activation "${rc_file}" "${command_name}" install "${destination}" "${shell_name}"
}

remove_shell_integration() {
  local command_name="$1" shell_name="$2" rc_file
  rc_file="$(shell_startup_file "${shell_name}")" || return
  [[ ! -f "${rc_file}" ]] || _rewrite_shell_activation "${rc_file}" "${command_name}" remove
}
