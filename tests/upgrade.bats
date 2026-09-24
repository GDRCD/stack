#!/usr/bin/env bats

load test_helper

setup() {
  setup_test_environment
  UPGRADE_ROOT="${TEST_ROOT}/stack"
  copy_stack "${UPGRADE_ROOT}"
  CLI_PATH="${UPGRADE_ROOT}/stack"
  printf '%s\n' v4.0.0 >"${UPGRADE_ROOT}/.version"
  mkdir -p "${UPGRADE_ROOT}/www" "${UPGRADE_ROOT}/logs"
}

teardown() { teardown_test_environment; }

run_upgrade() {
  run env PATH="${PROJECT_ROOT}/tests/fixtures:${PATH}" CURL_STUB_ARCHIVE="${TEST_ROOT}/release.tar.gz" \
    "$CLI_PATH" upgrade "$@"
}

init_stack_repository() {
  git -C "${UPGRADE_ROOT}" init -q
  git -C "${UPGRADE_ROOT}" config user.email tests@example.test
  git -C "${UPGRADE_ROOT}" config user.name Tests
  git -C "${UPGRADE_ROOT}" add .
  git -C "${UPGRADE_ROOT}" commit -qm initial
}

@test "archive upgrade replaces core and preserves user data" {
  create_release_archive v4.1.0
  touch "${UPGRADE_ROOT}/www/keep" "${UPGRADE_ROOT}/logs/keep"
  printf '%s\n' custom >"${UPGRADE_ROOT}/services"
  cp "${UPGRADE_ROOT}/.env" "${TEST_ROOT}/env-before"

  run_upgrade --version v4.1.0

  [ "$status" -eq 0 ]
  [ "$(cat "${UPGRADE_ROOT}/README.md")" = updated ]
  [ "$(cat "${UPGRADE_ROOT}/.version")" = v4.1.0 ]
  cmp "${TEST_ROOT}/env-before" "${UPGRADE_ROOT}/.env"
  [ -f "${UPGRADE_ROOT}/www/keep" ]
  [ -f "${UPGRADE_ROOT}/logs/keep" ]
  [ "$(cat "${UPGRADE_ROOT}/services")" = custom ]
}

@test "archive upgrade also works in a clean Git checkout and preserves Git metadata" {
  create_release_archive v4.1.0
  init_stack_repository

  run_upgrade --version v4.1.0

  [ "$status" -eq 0 ]
  [ -d "${UPGRADE_ROOT}/.git" ]
  [ "$(cat "${UPGRADE_ROOT}/README.md")" = updated ]
  [ "$(cat "${UPGRADE_ROOT}/.version")" = v4.1.0 ]
}

@test "upgrade refuses dirty incoming core paths in a Git checkout" {
  create_release_archive v4.1.0
  init_stack_repository
  printf '%s\n' dirty >>"${UPGRADE_ROOT}/stack"
  cp "${UPGRADE_ROOT}/stack" "${TEST_ROOT}/stack-before"

  run_upgrade --version v4.1.0

  [ "$status" -eq 1 ]
  [[ "$output" == *"core contiene modifiche"* ]]
  cmp "${TEST_ROOT}/stack-before" "${UPGRADE_ROOT}/stack"
  [ "$(cat "${UPGRADE_ROOT}/.version")" = v4.0.0 ]
}

@test "upgrade allows dirty preserved paths in a Git checkout" {
  create_release_archive v4.1.0
  init_stack_repository
  printf '%s\n' local >>"${UPGRADE_ROOT}/.env"
  printf '%s\n' phpmyadmin >"${UPGRADE_ROOT}/services"

  run_upgrade --version v4.1.0

  [ "$status" -eq 0 ]
  grep -Fq local "${UPGRADE_ROOT}/.env"
  [ "$(cat "${UPGRADE_ROOT}/services")" = phpmyadmin ]
}

@test "upgrade validates the archive before mutating the core" {
  release="${TEST_ROOT}/release/stack-4.1.0"
  mkdir -p "${release}/bin/commands" "${release}/.docker"
  touch "${release}/stack" "${release}/boot.sh" "${release}/sample.env"
  tar -czf "${TEST_ROOT}/release.tar.gz" -C "${TEST_ROOT}/release" stack-4.1.0
  cp "${UPGRADE_ROOT}/stack" "${TEST_ROOT}/stack-before"

  run_upgrade --version v4.1.0

  [ "$status" -eq 1 ]
  [[ "$output" == *"incompleto"* ]]
  cmp "${TEST_ROOT}/stack-before" "${UPGRADE_ROOT}/stack"
  [ "$(cat "${UPGRADE_ROOT}/.version")" = v4.0.0 ]
}

@test "upgrade rolls back all core changes after an apply failure" {
  create_release_archive v4.1.0
  printf '%s\n' original >"${UPGRADE_ROOT}/README.md"
  cp -R "${UPGRADE_ROOT}/bin" "${TEST_ROOT}/bin-before"

  run env PATH="${PROJECT_ROOT}/tests/fixtures:${PATH}" CURL_STUB_ARCHIVE="${TEST_ROOT}/release.tar.gz" \
    MV_STUB_FAIL_SOURCE="/bin" MV_STUB_MARKER="${TEST_ROOT}/mv-failed" \
    "$CLI_PATH" upgrade --version v4.1.0

  [ "$status" -ne 0 ]
  [ "$(cat "${UPGRADE_ROOT}/README.md")" = original ]
  [ "$(cat "${UPGRADE_ROOT}/.version")" = v4.0.0 ]
  diff -ru "${TEST_ROOT}/bin-before" "${UPGRADE_ROOT}/bin"
  ! find "${UPGRADE_ROOT}" -maxdepth 1 \( -name '.stack-upgrade.*' -o -name '.stack-rollback.*' \) | grep -q .
}

@test "force reinstalls the current archive version" {
  create_release_archive v4.0.0 reinstalled
  printf '%s\n' original >"${UPGRADE_ROOT}/README.md"

  run_upgrade --version v4.0.0
  [ "$status" -eq 0 ]
  [ "$(cat "${UPGRADE_ROOT}/README.md")" = original ]

  run_upgrade --version v4.0.0 --force
  [ "$status" -eq 0 ]
  [ "$(cat "${UPGRADE_ROOT}/README.md")" = reinstalled ]
}

@test "upgrade rejects invalid release tags" {
  run "$CLI_PATH" upgrade --version v4.01.0

  [ "$status" -eq 2 ]
  [[ "$output" == *"non valido"* ]]
}
