#!/usr/bin/env bash

set -Eeo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
export BATS_LIB_PATH="${BATS_LIB_PATH:-/usr/lib/bats}"
find "${ROOT}/bin" -type f -exec shellcheck --severity=error {} +
shellcheck --severity=error "${ROOT}/stack" "${ROOT}/boot.sh" "${ROOT}/tests/fixtures/docker" \
  "${ROOT}/tests/fixtures/mv" "${ROOT}/tests/portability.sh"
bats "${ROOT}/tests"
