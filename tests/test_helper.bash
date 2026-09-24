PROJECT_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd -P)"
CLI_PATH="${PROJECT_ROOT}/stack"
INSTALL_NAME="gdrcd-tests"
export PROJECT_ROOT CLI_PATH INSTALL_NAME

setup_test_environment() {
  TEST_ROOT="$(mktemp -d "${BATS_TEST_TMPDIR}/gdrcd-test.XXXXXX")"
  export TEST_ROOT
  rm -f "${PROJECT_ROOT}/services"
}

copy_stack() {
  local target="$1"
  mkdir -p "${target}"
  cp -R "${PROJECT_ROOT}/stack" "${PROJECT_ROOT}/boot.sh" "${PROJECT_ROOT}/bin" \
    "${PROJECT_ROOT}/.docker" "${PROJECT_ROOT}/sample.env" "${target}/"
  cp "${PROJECT_ROOT}/.env" "${target}/.env"
}

create_release_archive() {
  local version="$1" marker="${2:-updated}" release
  release="${TEST_ROOT}/release/stack-${version#v}"
  rm -rf "${TEST_ROOT}/release"
  mkdir -p "${release}/bin/commands" "${release}/.docker"
  printf '#!/usr/bin/env bash\n' >"${release}/stack"
  printf '#!/usr/bin/env bash\n' >"${release}/boot.sh"
  printf '#!/usr/bin/env bash\n' >"${release}/bin/commands/noop"
  printf '%s\n' "${marker}" >"${release}/README.md"
  printf '%s\n' 'PROJECT=release' >"${release}/sample.env"
  touch "${release}/.docker/compose.yml"
  chmod +x "${release}/stack" "${release}/boot.sh" "${release}/bin/commands/noop"
  tar -czf "${TEST_ROOT}/release.tar.gz" -C "${TEST_ROOT}/release" "stack-${version#v}"
}

teardown_test_environment() {
  if [[ -f "${TEST_ROOT}/env" && ! -f "${PROJECT_ROOT}/.env" ]]; then mv "${TEST_ROOT}/env" "${PROJECT_ROOT}/.env"; fi
  rm -rf "${TEST_ROOT}"
  rm -f "${PROJECT_ROOT}/services"
}

enable_docker_stub() {
  export DOCKER_STUB_LOG="${TEST_ROOT}/docker.log"
  export PATH="${PROJECT_ROOT}/tests/fixtures:${PATH}"
}
