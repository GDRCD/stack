#!/usr/bin/env bats

load test_helper

setup() {
  setup_test_environment
  VERSION_ROOT="${TEST_ROOT}/stack"
  copy_stack "${VERSION_ROOT}"
  rm -f "${VERSION_ROOT}/.env"
  CLI_PATH="${VERSION_ROOT}/stack"
}

teardown() { teardown_test_environment; }

@test "archive installations report the validated version without an environment file" {
  printf '%s\n' v4.1.0-rc.1+build.5 >"${VERSION_ROOT}/.version"

  run "$CLI_PATH" --version
  [ "$status" -eq 0 ]
  [ "$output" = v4.1.0-rc.1+build.5 ]

  run "$CLI_PATH" version
  [ "$status" -eq 0 ]
  [ "$output" = v4.1.0-rc.1+build.5 ]
}

@test "Git checkouts report git describe as their development version" {
  git -C "${VERSION_ROOT}" init -q
  git -C "${VERSION_ROOT}" config user.email tests@example.test
  git -C "${VERSION_ROOT}" config user.name Tests
  git -C "${VERSION_ROOT}" add .
  git -C "${VERSION_ROOT}" commit -qm initial
  git -C "${VERSION_ROOT}" tag v4.1.0

  run "$CLI_PATH" --version
  [ "$status" -eq 0 ]
  [ "$output" = v4.1.0 ]

  printf '%s\n' dirty >>"${VERSION_ROOT}/sample.env"
  run "$CLI_PATH" version
  [ "$status" -eq 0 ]
  [ "$output" = v4.1.0-dirty ]
}

@test "version rejects invalid archive metadata and extra arguments" {
  printf '%s\n' v4.01.0 >"${VERSION_ROOT}/.version"

  run "$CLI_PATH" --version
  [ "$status" -eq 1 ]
  [[ "$output" == *"non determinabile"* ]]

  run "$CLI_PATH" --version extra
  [ "$status" -eq 2 ]

  run "$CLI_PATH" version extra
  [ "$status" -eq 2 ]
}
