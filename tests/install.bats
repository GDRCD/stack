#!/usr/bin/env bats

load test_helper
setup() {
  setup_test_environment
  INSTALL_HOME="${TEST_ROOT}/home"; INSTALL_DATA="${TEST_ROOT}/data"; INSTALL_BIN="${TEST_ROOT}/bin"
  export INSTALL_HOME INSTALL_DATA INSTALL_BIN
}
teardown() { teardown_test_environment; }

@test "install creates an owned symlink and idempotent static hook" {
  run env HOME="${INSTALL_HOME}" XDG_DATA_HOME="${INSTALL_DATA}" SHELL=/bin/bash \
    "${CLI_PATH}" install --target "${INSTALL_BIN}" --shell-hook
  [ "$status" -eq 0 ]
  [ -L "${INSTALL_BIN}/${INSTALL_NAME}" ]
  [ -f "${INSTALL_DATA}/${INSTALL_NAME}/shell-init.bash" ]
  grep -Fq "# >>> ${INSTALL_NAME} shell integration >>>" "${INSTALL_HOME}/.bashrc"
  run bash --noprofile --norc -c '. "$1"; complete -p "$2"' _ "${INSTALL_DATA}/${INSTALL_NAME}/shell-init.bash" "${INSTALL_NAME}"
  [ "$status" -eq 0 ]

  run env HOME="${INSTALL_HOME}" XDG_DATA_HOME="${INSTALL_DATA}" SHELL=/bin/bash \
    "${CLI_PATH}" install --target "${INSTALL_BIN}" --shell-hook --force
  [ "$status" -eq 0 ]
  [ "$(grep -Fc "# >>> ${INSTALL_NAME} shell integration >>>" "${INSTALL_HOME}/.bashrc")" -eq 1 ]
}

@test "uninstall removes only managed files" {
  env HOME="${INSTALL_HOME}" XDG_DATA_HOME="${INSTALL_DATA}" SHELL=/bin/bash \
    "${CLI_PATH}" install --target "${INSTALL_BIN}" --shell-hook >/dev/null
  printf '%s\n' '# keep' >>"${INSTALL_HOME}/.bashrc"
  run env HOME="${INSTALL_HOME}" XDG_DATA_HOME="${INSTALL_DATA}" \
    "${INSTALL_BIN}/${INSTALL_NAME}" uninstall --target "${INSTALL_BIN}"
  [ "$status" -eq 0 ]
  [ ! -e "${INSTALL_BIN}/${INSTALL_NAME}" ]
  grep -Fq '# keep' "${INSTALL_HOME}/.bashrc"
}

@test "install refuses to replace files and foreign symlinks" {
  mkdir -p "${INSTALL_BIN}"
  touch "${INSTALL_BIN}/${INSTALL_NAME}"
  run "${CLI_PATH}" install --target "${INSTALL_BIN}" --force --no-shell-hook
  [ "$status" -eq 1 ]
  rm -f "${INSTALL_BIN}/${INSTALL_NAME}"
  ln -s "${TEST_ROOT}/foreign" "${INSTALL_BIN}/${INSTALL_NAME}"
  run "${CLI_PATH}" install --target "${INSTALL_BIN}" --force --no-shell-hook
  [ "$status" -eq 1 ]
}
