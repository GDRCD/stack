#!/usr/bin/env bats

load test_helper
setup() { setup_test_environment; }
teardown() { teardown_test_environment; }

@test "bootstrap installs a release archive into an isolated target" {
  release="${TEST_ROOT}/release/stack-4.0.0"
  mkdir -p "${release}/bin/commands" "${release}/.docker"
  cp "${PROJECT_ROOT}/stack" "${PROJECT_ROOT}/sample.env" "${release}/"
  cp "${PROJECT_ROOT}/bin/commands/services" "${release}/bin/commands/"
  touch "${release}/.docker/compose.yml"
  tar -czf "${TEST_ROOT}/release.tar.gz" -C "${TEST_ROOT}/release" stack-4.0.0
  export CURL_STUB_ARCHIVE="${TEST_ROOT}/release.tar.gz"

  run env PATH="${PROJECT_ROOT}/tests/fixtures:${PATH}" CURL_STUB_ARCHIVE="${CURL_STUB_ARCHIVE}" \
    bash "${PROJECT_ROOT}/boot.sh" --version v4.0.0 "${TEST_ROOT}/target"

  [ "$status" -eq 0 ]
  [ -x "${TEST_ROOT}/target/stack" ]
  [ -f "${TEST_ROOT}/target/.env" ]
  [ "$(cat "${TEST_ROOT}/target/.version")" = v4.0.0 ]
  [ -d "${TEST_ROOT}/target/www" ]
}
