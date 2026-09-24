#!/usr/bin/env bats

load test_helper
setup() { setup_test_environment; }
teardown() { teardown_test_environment; }

@test "cd prints canonical www and root paths" {
  run "${CLI_PATH}" cd; [ "$status" -eq 0 ]; [ "$output" = "${PROJECT_ROOT}/www" ]
  run "${CLI_PATH}" cd --root; [ "$status" -eq 0 ]; [ "$output" = "${PROJECT_ROOT}" ]
}

@test "activation changes the parent shell directory" {
  run bash --noprofile --norc -c 'source <("$1" activate bash); stack cd; pwd -P; stack cd --root; pwd -P' _ "${CLI_PATH}"
  [ "$status" -eq 0 ]
  [[ "$output" == *"${PROJECT_ROOT}/www"* ]]
  [[ "$output" == *"${PROJECT_ROOT}"* ]]
}
