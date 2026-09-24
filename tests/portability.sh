#!/usr/bin/env bash

set -eu
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
bash -n "${ROOT}/stack" "${ROOT}/boot.sh" "${ROOT}"/bin/lib/*.sh "${ROOT}"/bin/commands/*
NO_COLOR=1 "${ROOT}/stack" --help >/dev/null
"${ROOT}/stack" __validate-specs
"${ROOT}/stack" completion bash | bash -n
"${ROOT}/stack" shell-init bash | bash -n
