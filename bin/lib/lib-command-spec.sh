#!/usr/bin/env bash

COMMAND_METADATA_VALUE=""

_metadata_trim() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "${value}"
}

command_metadata_file() {
  printf '%s/%s\n' "${COMMANDS_DIR}" "$1"
}

command_metadata_read() {
  local file="$1" marker="# @cli.${2}:" line
  COMMAND_METADATA_VALUE=""
  while IFS= read -r line; do
    [[ "${line}" == "${marker}"* ]] || continue
    COMMAND_METADATA_VALUE="${line#"${marker}"}"
    COMMAND_METADATA_VALUE="${COMMAND_METADATA_VALUE#"${COMMAND_METADATA_VALUE%%[![:space:]]*}"}"
    COMMAND_METADATA_VALUE="${COMMAND_METADATA_VALUE%"${COMMAND_METADATA_VALUE##*[![:space:]]}"}"
    return 0
  done < "${file}"
  return 1
}

command_metadata_value() {
  command_metadata_read "$1" "$2" || return
  printf '%s\n' "${COMMAND_METADATA_VALUE}"
}

command_metadata_records() {
  local file="$1" marker="# @cli.${2}:" line value
  while IFS= read -r line; do
    [[ "${line}" == "${marker}"* ]] || continue
    value="${line#"${marker}"}"
    _metadata_trim "${value}"
    printf '\n'
  done < "${file}"
}

command_spec_exists() {
  local file="${COMMANDS_DIR}/$1"
  [[ -f "${file}" ]] || return 1
  command_metadata_read "${file}" summary || return 1
  [[ -n "${COMMAND_METADATA_VALUE}" ]]
}

command_help_requested() {
  local argument
  for argument in "$@"; do
    [[ "${argument}" == "--" ]] && return 1
    case "${argument}" in -h | --help | help) return 0 ;; esac
  done
  return 1
}

render_command_help() {
  local command_name="$1" file usage summary record names kind label description arguments_printed="false"
  file="$(command_metadata_file "${command_name}")"
  [[ -f "${file}" ]] || {
    prompt -e "No command metadata found for '${command_name}'."
    return 1
  }
  usage="$(command_metadata_value "${file}" usage)"
  summary="$(command_metadata_value "${file}" summary)"
  helpify_title "${command_name}" "${usage}"
  helpify_subtitle "${summary}"

  while IFS= read -r record; do
    [[ -n "${record}" ]] || continue
    IFS='|' read -r names kind label description <<< "${record}"
    names="$(_metadata_trim "${names}")"
    description="$(_metadata_trim "${description}")"
    if [[ "${arguments_printed}" != "true" ]]; then
      printf '\n'
      helpify_subtitle "ARGUMENTS:"
      arguments_printed="true"
    fi
    helpify "${names}" "${description}"
  done < <(command_metadata_records "${file}" argument)

  printf '\n'
  helpify_subtitle "OPTIONS:"
  helpify "-h, --help" "Mostra questo aiuto"
  while IFS= read -r record; do
    [[ -n "${record}" ]] || continue
    IFS='|' read -r names kind label description <<< "${record}"
    names="$(_metadata_trim "${names}")"
    label="$(_metadata_trim "${label}")"
    description="$(_metadata_trim "${description}")"
    [[ -n "${label}" ]] && names="${names} ${label}"
    helpify "${names}" "${description}"
  done < <(command_metadata_records "${file}" option)
}

_command_completion_values() {
  local kind="$1" prefix="$2" value values
  case "${kind}" in
    enum\(*\))
      values="${kind#enum(}"
      values="${values%)}"
      values="${values//,/ }"
      for value in ${values}; do [[ "${value}" == "${prefix}"* ]] && printf '%s\n' "${value}"; done
      ;;
    service) while IFS= read -r value; do [[ "${value}" == "${prefix}"* ]] && printf '%s\n' "${value}"; done < <(listServices) ;;
    optional-service) while IFS= read -r value; do [[ "${value}" == "${prefix}"* ]] && printf '%s\n' "${value}"; done < <(listOptionalServices) ;;
    file) compgen -f -- "${prefix}" || true ;;
    directory) compgen -d -- "${prefix}" || true ;;
  esac
}

_command_completion_commands() {
  local prefix="$1" path name
  for path in "${COMMANDS_DIR}"/*; do
    [[ -f "${path}" && -x "${path}" ]] || continue
    name="${path##*/}"
    [[ "${name}" == "${prefix}"* ]] && printf '%s\n' "${name}"
  done
}

_command_option_alias_matches() {
  local aliases="${1//,/ }" expected="$2" alias
  for alias in ${aliases}; do [[ "${alias}" == "${expected}" ]] && return 0; done
  return 1
}

_command_option_kind() {
  local file="$1" expected="$2" record names kind label description
  while IFS= read -r record; do
    IFS='|' read -r names kind label description <<< "${record}"
    names="$(_metadata_trim "${names}")"
    if _command_option_alias_matches "${names}" "${expected}"; then
      _metadata_trim "${kind}"
      return 0
    fi
  done < <(command_metadata_records "${file}" option)
  return 1
}

command_completion() {
  local cursor="${1:-0}"
  shift || true
  local words=("$@") current first spec_path file
  local command_words=1 relative previous record names kind label description positional=0 word
  local option_kind skip_option_value="false" last_kind="" last_cardinality=""
  [[ "${cursor}" =~ ^[0-9]+$ ]] || return 2
  current="${words[$cursor]:-}"
  first="${words[0]:-}"
  if [[ "${cursor}" -eq 0 ]]; then
    _command_completion_commands "${current}"
    return
  fi
  spec_path="${first}"
  command_spec_exists "${spec_path}" || return 0
  file="${COMMANDS_DIR}/${spec_path}"
  relative=$((cursor - command_words))
  previous="${words[$((cursor - 1))]:-}"
  for word in "${words[@]:$command_words:$relative}"; do [[ "${word}" == "--" ]] && return 0; done

  while IFS= read -r record; do
    IFS='|' read -r names kind label description <<< "${record}"
    names="$(_metadata_trim "${names}")"
    kind="$(_metadata_trim "${kind}")"
    if _command_option_alias_matches "${names}" "${previous}"; then
      _command_completion_values "${kind}" "${current}"
      return
    fi
  done < <(command_metadata_records "${file}" option)

  if [[ "${current}" == -* ]]; then
    [[ "-h" == "${current}"* ]] && printf '%s\n' -h
    [[ "--help" == "${current}"* ]] && printf '%s\n' --help
    while IFS= read -r record; do
      IFS='|' read -r names kind label description <<< "${record}"
      names="$(_metadata_trim "${names}")"
      names="${names//,/ }"
      for word in ${names}; do [[ "${word}" == "${current}"* ]] && printf '%s\n' "${word}"; done
    done < <(command_metadata_records "${file}" option)
    return
  fi

  for word in "${words[@]:$command_words:$relative}"; do
    if [[ "${skip_option_value}" == "true" ]]; then
      skip_option_value="false"
      continue
    fi
    if [[ "${word}" == -* ]]; then
      option_kind="$(_command_option_kind "${file}" "${word}" || true)"
      [[ -z "${option_kind}" || "${option_kind}" == "flag" ]] || skip_option_value="true"
      continue
    fi
    positional=$((positional + 1))
  done
  while IFS= read -r record; do
    IFS='|' read -r names kind label description <<< "${record}"
    kind="$(_metadata_trim "${kind}")"
    label="$(_metadata_trim "${label}")"
    if [[ "${positional}" -eq 0 ]]; then
      _command_completion_values "${kind}" "${current}"
      return
    fi
    last_kind="${kind}"
    last_cardinality="${label}"
    positional=$((positional - 1))
  done < <(command_metadata_records "${file}" argument)
  if [[ "${last_cardinality}" == "repeatable" ]]; then _command_completion_values "${last_kind}" "${current}"; fi
}

validate_command_metadata() {
  local file failed="false" summary record bars kind
  while IFS= read -r -d '' file; do
    summary="$(command_metadata_value "${file}" summary)"
    if [[ -z "${summary}" ]]; then
      printf 'Missing @cli.summary in %s\n' "${file}" >&2
      failed="true"
    fi
    if ! grep -Fq '# @cli.usage:' "${file}"; then
      printf 'Missing @cli.usage in %s\n' "${file}" >&2
      failed="true"
    fi
    while IFS= read -r record; do
      bars="${record//[^|]/}"
      if [[ "${#bars}" -ne 3 ]]; then
        printf 'Invalid metadata record in %s: %s\n' "${file}" "${record}" >&2
        failed="true"
        continue
      fi
      IFS='|' read -r _ kind _ _ <<< "${record}"
      kind="$(_metadata_trim "${kind}")"
      case "${kind}" in flag | text | file | directory | service | optional-service | enum\(*\)) ;; *)
        printf "Unknown metadata type '%s' in %s\n" "${kind}" "${file}" >&2
        failed="true"
        ;;
      esac
    done < <({
      command_metadata_records "${file}" option
      command_metadata_records "${file}" argument
    })
  done < <(find "${COMMANDS_DIR}" -type f -perm -u+x -print0)
  [[ "${failed}" == "false" ]]
}
