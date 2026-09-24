#!/usr/bin/env bats

load test_helper

setup() { setup_test_environment; }
teardown() { teardown_test_environment; }

@test "root and command help aliases work without .env" {
  mv "${PROJECT_ROOT}/.env" "${TEST_ROOT}/env"
  run env NO_COLOR=1 "${CLI_PATH}" help
  [ "$status" -eq 0 ]
  [[ "$output" == *"COMMANDS:"* ]]
  run env NO_COLOR=1 "${CLI_PATH}" build help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage:"* && "$output" == *"ARGUMENTS:"* && "$output" == *"OPTIONS:"* ]]
  mv "${TEST_ROOT}/env" "${PROJECT_ROOT}/.env"
}

@test "all executable commands expose valid metadata" {
  run "${CLI_PATH}" __validate-specs
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "completion exposes all commands options services and enum values" {
  local command_file command command_output
  run "${CLI_PATH}" __complete 0 ""
  [ "$status" -eq 0 ]
  command_output="${output}"
  while IFS= read -r command_file; do
    command="$(basename "${command_file}")"
    printf '%s\n' "${command_output}" | grep -Fxq "${command}"
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
