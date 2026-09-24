#!/usr/bin/env bats

load test_helper
setup() { setup_test_environment; }
teardown() { teardown_test_environment; }

@test "bootstrap installs a validated release archive" {
  create_release_archive v4.1.0

  run env PATH="${PROJECT_ROOT}/tests/fixtures:${PATH}" CURL_STUB_ARCHIVE="${TEST_ROOT}/release.tar.gz" \
    bash "${PROJECT_ROOT}/boot.sh" --version v4.1.0 "${TEST_ROOT}/target"

  [ "$status" -eq 0 ]
  [ -x "${TEST_ROOT}/target/stack" ]
  [ -x "${TEST_ROOT}/target/boot.sh" ]
  [ -f "${TEST_ROOT}/target/.env" ]
  [ "$(cat "${TEST_ROOT}/target/.version")" = v4.1.0 ]
  [ -d "${TEST_ROOT}/target/www" ]
}

@test "bootstrap rejects invalid release tags before downloading" {
  run env PATH="${PROJECT_ROOT}/tests/fixtures:${PATH}" \
    bash "${PROJECT_ROOT}/boot.sh" --version 4.1.0 "${TEST_ROOT}/target"

  [ "$status" -eq 2 ]
  [[ "$output" == *"Invalid release tag"* ]]
  [ ! -e "${TEST_ROOT}/target" ]
}

@test "bootstrap accepts strict SemVer prerelease and build tags" {
  create_release_archive v4.1.0-rc.1+build.5

  run env PATH="${PROJECT_ROOT}/tests/fixtures:${PATH}" CURL_STUB_ARCHIVE="${TEST_ROOT}/release.tar.gz" \
    bash "${PROJECT_ROOT}/boot.sh" --version v4.1.0-rc.1+build.5 "${TEST_ROOT}/target"

  [ "$status" -eq 0 ]
  [ "$(cat "${TEST_ROOT}/target/.version")" = v4.1.0-rc.1+build.5 ]
}

@test "bootstrap rejects an incomplete archive without mutating the target" {
  release="${TEST_ROOT}/release/stack-4.1.0"
  mkdir -p "${release}/bin/commands" "${release}/.docker"
  touch "${release}/stack" "${release}/boot.sh" "${release}/sample.env"
  tar -czf "${TEST_ROOT}/release.tar.gz" -C "${TEST_ROOT}/release" stack-4.1.0

  run env PATH="${PROJECT_ROOT}/tests/fixtures:${PATH}" CURL_STUB_ARCHIVE="${TEST_ROOT}/release.tar.gz" \
    bash "${PROJECT_ROOT}/boot.sh" --version v4.1.0 "${TEST_ROOT}/target"

  [ "$status" -eq 1 ]
  [[ "$output" == *"incomplete"* ]]
  [ ! -e "${TEST_ROOT}/target" ]
}
