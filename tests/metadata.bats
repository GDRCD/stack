#!/usr/bin/env bats

load test_helper

trim_field() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

setup() { setup_test_environment; }
teardown() { teardown_test_environment; }

@test "root help and every command help work without .env" {
  mv "${PROJECT_ROOT}/.env" "${TEST_ROOT}/env"
  run env NO_COLOR=1 "${CLI_PATH}" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"COMMANDS:"* ]]
  while IFS= read -r command_file; do
    run env NO_COLOR=1 "${CLI_PATH}" "$(basename "${command_file}")" --help
    [ "$status" -eq 0 ] || { printf '%s\n' "$output" >&2; return 1; }
    [[ "$output" == *"Usage:"* ]]
  done < <(find "${PROJECT_ROOT}/bin/commands" -type f -perm -u+x | sort)
  mv "${TEST_ROOT}/env" "${PROJECT_ROOT}/.env"
}

@test "all executable commands expose valid metadata" {
  run "${CLI_PATH}" __validate-specs
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "completion exposes all commands options services and enum values" {
  while IFS= read -r command_file; do
    command="$(basename "${command_file}")"
    run "${CLI_PATH}" __complete 0 ""
    [ "$status" -eq 0 ]
    printf '%s\n' "$output" | grep -Fxq "$command"
  done < <(find "${PROJECT_ROOT}/bin/commands" -type f -perm -u+x | sort)

  run "${CLI_PATH}" __complete 1 build ""
  [[ "$output" == *"webserver"* && "$output" == *"database"* ]]
  run "${CLI_PATH}" __complete 1 enable ""
  [[ "$output" == *"phpmyadmin"* && "$output" == *"mailhog"* ]]
  run "${CLI_PATH}" __complete 1 clean -
  [[ "$output" == *"--volumes"* ]]
  run "${CLI_PATH}" __complete 1 activate ""
  [[ "$output" == *"bash"* && "$output" == *"zsh"* ]]
}

@test "generated Bash and Zsh integration is syntactically valid" {
  run bash -c '"$1" activate bash | bash -n' _ "${CLI_PATH}"; [ "$status" -eq 0 ]
  run bash -c '"$1" activate zsh | zsh -n' _ "${CLI_PATH}"; [ "$status" -eq 0 ]
}

@test "completion mirrors every declared option and enum" {
  local file command record names kind alias values value completion_output
  while IFS= read -r file; do
    command="$(basename "$file")"
    while IFS= read -r record; do
      record="${record#\# @cli.option:}"
      IFS='|' read -r names kind _ _ <<<"$record"
      names="$(trim_field "$names")"; kind="$(trim_field "$kind")"
      run "${CLI_PATH}" __complete 1 "$command" -
      [ "$status" -eq 0 ]; completion_output="$output"; names="${names//,/ }"
      for alias in $names; do printf '%s\n' "$completion_output" | grep -Fxq -- "$alias"; done
      if [[ "$kind" == enum\(*\) ]]; then
        alias="${names%% *}"; run "${CLI_PATH}" __complete 2 "$command" "$alias" ""; [ "$status" -eq 0 ]
        values="${kind#enum(}"; values="${values%)}"; values="${values//,/ }"
        for value in $values; do printf '%s\n' "$output" | grep -Fxq -- "$value"; done
      fi
    done < <(grep '^# @cli.option:' "$file" || true)
  done < <(find "${PROJECT_ROOT}/bin/commands" -type f -perm -u+x | sort)
}
