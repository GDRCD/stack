PROJECT_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd -P)"
CLI_PATH="${PROJECT_ROOT}/stack"
INSTALL_NAME="gdrcd-tests"
export PROJECT_ROOT CLI_PATH INSTALL_NAME

setup_test_environment() {
  TEST_ROOT="$(mktemp -d "${BATS_TEST_TMPDIR}/gdrcd-test.XXXXXX")"
  export TEST_ROOT
  rm -f "${PROJECT_ROOT}/services"
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
