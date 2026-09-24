#!/usr/bin/env bats

load test_helper
setup() { setup_test_environment; enable_docker_stub; }
teardown() { teardown_test_environment; }

@test "compressed import streams data without changing its source" {
  printf '%s\n' 'SELECT 42;' >"${TEST_ROOT}/dump.sql"
  gzip -c "${TEST_ROOT}/dump.sql" >"${TEST_ROOT}/dump.sql.gz"
  checksum="$(sha256sum "${TEST_ROOT}/dump.sql.gz")"
  run "${CLI_PATH}" import app "${TEST_ROOT}/dump.sql.gz"
  [ "$status" -eq 0 ]
  [ "$(sha256sum "${TEST_ROOT}/dump.sql.gz")" = "$checksum" ]
  grep -Fxq mysql "${DOCKER_STUB_LOG}"
}

@test "failed export preserves an existing destination" {
  printf '%s\n' original >"${TEST_ROOT}/dump.sql"
  export DOCKER_STUB_FAIL_MYSQLDUMP=true
  run "${CLI_PATH}" export app "${TEST_ROOT}/dump.sql"
  [ "$status" -eq 9 ]
  [ "$(cat "${TEST_ROOT}/dump.sql")" = original ]
}

@test "refresh requires confirmation outside a terminal" {
  run "${CLI_PATH}" refresh app
  [ "$status" -eq 2 ]
  [[ "$output" == *"--yes"* ]]
  run "${CLI_PATH}" refresh --yes app
  [ "$status" -eq 0 ]
  grep -Fq 'DROP DATABASE' "${DOCKER_STUB_LOG}"
}

@test "database names reject SQL syntax" {
  run "${CLI_PATH}" refresh --yes 'app;DROP'
  [ "$status" -eq 2 ]
}
