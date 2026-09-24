#!/usr/bin/env bats

load test_helper
setup() { setup_test_environment; }
teardown() {
  rm -rf "${PROJECT_ROOT}/.git"
  teardown_test_environment
}

@test "git upgrade refuses a dirty working tree before contacting the remote" {
  git -C "${PROJECT_ROOT}" init -q
  git -C "${PROJECT_ROOT}" config user.email tests@example.test
  git -C "${PROJECT_ROOT}" config user.name Tests
  git -C "${PROJECT_ROOT}" add .
  git -C "${PROJECT_ROOT}" commit -qm initial
  printf '%s\n' dirty >>"${PROJECT_ROOT}/sample.env"
  run "${CLI_PATH}" upgrade
  [ "$status" -eq 1 ]
  [[ "$output" == *"working tree"* ]]
  git -C "${PROJECT_ROOT}" checkout -q -- sample.env
}

@test "git upgrade fast-forwards a clean branch" {
  remote="${TEST_ROOT}/remote.git"; producer="${TEST_ROOT}/producer"
  git init --bare -q "${remote}"
  git -C "${PROJECT_ROOT}" init -q
  git -C "${PROJECT_ROOT}" checkout -qb master
  git -C "${PROJECT_ROOT}" config user.email tests@example.test
  git -C "${PROJECT_ROOT}" config user.name Tests
  git -C "${PROJECT_ROOT}" add .
  git -C "${PROJECT_ROOT}" commit -qm initial
  git -C "${PROJECT_ROOT}" remote add origin "${remote}"
  git -C "${PROJECT_ROOT}" push -qu origin master
  git clone -q "${remote}" "${producer}"
  git -C "${producer}" config user.email tests@example.test
  git -C "${producer}" config user.name Tests
  printf '%s\n' '# upstream' >>"${producer}/sample.env"
  git -C "${producer}" add sample.env
  git -C "${producer}" commit -qm upstream
  git -C "${producer}" push -q

  run "${CLI_PATH}" upgrade

  [ "$status" -eq 0 ]
  grep -Fq '# upstream' "${PROJECT_ROOT}/sample.env"
}

@test "archive upgrade preserves user data and replaces the core" {
  release="${TEST_ROOT}/release/stack-4.0.1"
  mkdir -p "${release}/bin/commands" "${release}/.docker" "${PROJECT_ROOT}/www"
  printf '#!/usr/bin/env bash\n' >"${release}/stack"
  printf '#!/usr/bin/env bash\n' >"${release}/boot.sh"
  printf '#!/usr/bin/env bash\n' >"${release}/bin/commands/noop"
  chmod +x "${release}/stack" "${release}/boot.sh" "${release}/bin/commands/noop"
  printf '%s\n' updated >"${release}/README.md"
  touch "${release}/.docker/compose.yml" "${PROJECT_ROOT}/www/keep"
  printf '%s\n' phpmyadmin >"${PROJECT_ROOT}/services"
  cp "${PROJECT_ROOT}/.env" "${TEST_ROOT}/env-before"
  tar -czf "${TEST_ROOT}/release.tar.gz" -C "${TEST_ROOT}/release" stack-4.0.1

  run env PATH="${PROJECT_ROOT}/tests/fixtures:${PATH}" CURL_STUB_ARCHIVE="${TEST_ROOT}/release.tar.gz" \
    "${CLI_PATH}" upgrade --version v4.0.1

  [ "$status" -eq 0 ]
  [ "$(cat "${PROJECT_ROOT}/README.md")" = updated ]
  cmp "${TEST_ROOT}/env-before" "${PROJECT_ROOT}/.env"
  [ -f "${PROJECT_ROOT}/www/keep" ]
  [ "$(cat "${PROJECT_ROOT}/services")" = phpmyadmin ]
}
