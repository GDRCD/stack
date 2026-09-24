#!/usr/bin/env bats

load test_helper
setup() { setup_test_environment; enable_docker_stub; }
teardown() { teardown_test_environment; }

@test "safe lifecycle commands execute through the Docker stub" {
  for command in build clean logs recreate restart start stop; do
    : >"${DOCKER_STUB_LOG}"
    run "${CLI_PATH}" "$command"
    [ "$status" -eq 0 ] || { printf '%s: %s\n' "$command" "$output" >&2; return 1; }
    [ -s "${DOCKER_STUB_LOG}" ]
  done
}

@test "build uses cache by default and force disables it" {
  run "${CLI_PATH}" build webserver; [ "$status" -eq 0 ]
  ! grep -Fxq -- --no-cache "${DOCKER_STUB_LOG}"
  : >"${DOCKER_STUB_LOG}"
  run "${CLI_PATH}" build --force webserver; [ "$status" -eq 0 ]
  grep -Fxq -- --no-cache "${DOCKER_STUB_LOG}"
}

@test "clean removes volumes only when requested" {
  run "${CLI_PATH}" clean; [ "$status" -eq 0 ]
  ! grep -Fxq -- -v "${DOCKER_STUB_LOG}"
  : >"${DOCKER_STUB_LOG}"
  run "${CLI_PATH}" clean --volumes; [ "$status" -eq 0 ]
  grep -Fxq -- -v "${DOCKER_STUB_LOG}"
}

@test "optional services can be enabled and disabled together" {
  run "${CLI_PATH}" enable phpmyadmin mailhog
  [ "$status" -eq 0 ]
  [ "$(cat "${PROJECT_ROOT}/services")" = "phpmyadmin,mailhog" ]
  run "${CLI_PATH}" disable phpmyadmin mailhog
  [ "$status" -eq 0 ]
  [ -z "$(cat "${PROJECT_ROOT}/services")" ]
}
