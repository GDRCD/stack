#!/usr/bin/env bats

load test_helper
setup() {
  setup_test_environment
  INSTALL_HOME="${TEST_ROOT}/home"; INSTALL_BIN="${TEST_ROOT}/bin"
  export INSTALL_HOME INSTALL_BIN
}
teardown() { teardown_test_environment; }

@test "install creates only the command by default" {
  run env HOME="${INSTALL_HOME}" "${CLI_PATH}" install --target "${INSTALL_BIN}"
  [ "$status" -eq 0 ]
  [ -L "${INSTALL_BIN}/${INSTALL_NAME}" ]
  [ ! -e "${INSTALL_HOME}/.bashrc" ]
}

@test "activate installs one working idempotent line" {
  run env HOME="${INSTALL_HOME}" SHELL=/bin/bash \
    "${CLI_PATH}" install --target "${INSTALL_BIN}" --activate
  [ "$status" -eq 0 ]
  [ "$(grep -Fc "activate bash" "${INSTALL_HOME}/.bashrc")" -eq 1 ]
  run bash --noprofile --norc -c '. "$1"; complete -p "$2"' _ "${INSTALL_HOME}/.bashrc" "${INSTALL_NAME}"
  [ "$status" -eq 0 ]

  run env HOME="${INSTALL_HOME}" SHELL=/bin/bash \
    "${CLI_PATH}" install --target "${INSTALL_BIN}" --activate --force
  [ "$status" -eq 0 ]
  [ "$(grep -Fc "activate bash" "${INSTALL_HOME}/.bashrc")" -eq 1 ]
}

@test "uninstall removes only managed files" {
  env HOME="${INSTALL_HOME}" SHELL=/bin/bash \
    "${CLI_PATH}" install --target "${INSTALL_BIN}" --activate >/dev/null
  printf '%s\n' '# keep' >>"${INSTALL_HOME}/.bashrc"
  run env HOME="${INSTALL_HOME}" \
    "${INSTALL_BIN}/${INSTALL_NAME}" uninstall --target "${INSTALL_BIN}"
  [ "$status" -eq 0 ]
  [ ! -e "${INSTALL_BIN}/${INSTALL_NAME}" ]
  grep -Fq '# keep' "${INSTALL_HOME}/.bashrc"
  ! grep -Fq 'shell integration' "${INSTALL_HOME}/.bashrc"
}

@test "install refuses to replace files and foreign symlinks" {
  mkdir -p "${INSTALL_BIN}"
  touch "${INSTALL_BIN}/${INSTALL_NAME}"
  run "${CLI_PATH}" install --target "${INSTALL_BIN}" --force
  [ "$status" -eq 1 ]
  rm -f "${INSTALL_BIN}/${INSTALL_NAME}"
  ln -s "${TEST_ROOT}/foreign" "${INSTALL_BIN}/${INSTALL_NAME}"
  run "${CLI_PATH}" install --target "${INSTALL_BIN}" --force
  [ "$status" -eq 1 ]
}
