#!/usr/bin/env bats

load test_helper
setup() { setup_test_environment; }
teardown() { teardown_test_environment; }

@test "unknown commands and arguments use status 2" {
  run "${CLI_PATH}" missing
  [ "$status" -eq 2 ]
  run "${CLI_PATH}" clean --missing
  [ "$status" -eq 2 ]
}

@test "missing option values use status 2" {
  run "${CLI_PATH}" install --target
  [ "$status" -eq 2 ]
  [[ "$output" == *"requires a value"* ]]
}

@test "help aliases work" {
  run "${CLI_PATH}" help; [ "$status" -eq 0 ]
  run "${CLI_PATH}" build help; [ "$status" -eq 0 ]
}
