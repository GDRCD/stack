#!/usr/bin/env bash
# shellcheck disable=SC2016 # This file intentionally emits unexpanded shell source.

if [[ "${STACK_SHELL_INTEGRATION_LOADED:-false}" == "true" ]]; then return 0; fi
readonly STACK_SHELL_INTEGRATION_LOADED="true"

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

render_shell_init() { render_shell_wrapper "$1" && render_shell_completion "$1" "$2"; }

shell_integration_file() { printf '%s/%s/shell-init.%s\n' "${XDG_DATA_HOME:-${HOME}/.local/share}" "$1" "$2"; }
shell_startup_file() { case "$1" in bash) printf '%s/.bashrc\n' "${HOME}" ;; zsh) printf '%s/.zshrc\n' "${HOME}" ;; *) return 2 ;; esac }

_rewrite_managed_shell_block() {
  local rc_file="$1" command_name="$2" mode="$3" target="${4:-}" hook_file="${5:-}"
  local begin="# >>> ${command_name} shell integration >>>" end="# <<< ${command_name} shell integration <<<"
  local temporary legacy shell_name
  case "${rc_file##*/}" in .zshrc) shell_name="zsh" ;; *) shell_name="bash" ;; esac
  temporary="$(mktemp "${rc_file}.tmp.XXXXXX")" || return 1
  cp -p -- "${rc_file}" "${temporary}"
  legacy="eval \"\$(${command_name} shell-init ${shell_name})\""
  awk -v begin="${begin}" -v end="${end}" -v legacy="${legacy}" '
    $0 == begin { managed=1; next }
    $0 == end { managed=0; next }
    !managed && $0 != legacy { print }
  ' "${rc_file}" > "${temporary}"
  if [[ "${mode}" == "install" ]]; then
    {
      printf '\n%s\n' "${begin}"
      printf 'case ":$PATH:" in *":%s:"*) ;; *) export PATH="%s:$PATH" ;; esac\n' "${target}" "${target}"
      printf '[ -r "%s" ] && . "%s"\n%s\n' "${hook_file}" "${hook_file}" "${end}"
    } >> "${temporary}"
  fi
  mv -f -- "${temporary}" "${rc_file}"
}

install_shell_integration() {
  local command_name="$1" shell_name="$2" target="$3" hook_file rc_file hook_dir temporary backup
  hook_file="$(shell_integration_file "${command_name}" "${shell_name}")" || return
  rc_file="$(shell_startup_file "${shell_name}")" || return
  if ! shell_integration_path_is_safe "${target}" || ! shell_integration_path_is_safe "${hook_file}"; then
    prompt -e "Shell integration paths contain unsupported characters."
    return 2
  fi
  hook_dir="$(dirname "${hook_file}")"
  mkdir -p -- "${hook_dir}" "$(dirname "${rc_file}")"
  touch "${rc_file}"
  temporary="$(mktemp "${hook_dir}/shell-init.${shell_name}.tmp.XXXXXX")" || return 1
  render_shell_init "${command_name}" "${shell_name}" > "${temporary}" || {
    rm -f -- "${temporary}"
    return 1
  }
  chmod 0644 "${temporary}"
  mv -f -- "${temporary}" "${hook_file}"
  backup="${rc_file}.${command_name}.backup"
  [[ -e "${backup}" ]] || cp -p -- "${rc_file}" "${backup}"
  _rewrite_managed_shell_block "${rc_file}" "${command_name}" install "${target}" "${hook_file}"
}

remove_shell_integration() {
  local command_name="$1" shell_name="$2" hook_file rc_file hook_dir
  hook_file="$(shell_integration_file "${command_name}" "${shell_name}")" || return
  rc_file="$(shell_startup_file "${shell_name}")" || return
  [[ ! -f "${rc_file}" ]] || _rewrite_managed_shell_block "${rc_file}" "${command_name}" remove
  rm -f -- "${hook_file}"
  hook_dir="$(dirname "${hook_file}")"
  rmdir "${hook_dir}" 2> /dev/null || true
}
