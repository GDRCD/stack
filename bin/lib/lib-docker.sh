#!/usr/bin/env bash

if [[ "${STACK_DOCKER_LOADED:-false}" == "true" ]]; then return 0; fi
readonly STACK_DOCKER_LOADED="true"

_STACK_DOCKER_READY="false"

dockerPreflight() {
  [[ "${_STACK_DOCKER_READY}" == "true" ]] && return
  [[ -n "${PROJECT:-}" ]] || { prompt -e "PROJECT deve essere configurato in .env."; return 2; }
  command -v docker >/dev/null 2>&1 || { prompt -e "Docker non è installato."; return 1; }
  docker compose version >/dev/null 2>&1 || { prompt -e "Docker Compose v2 non è disponibile."; return 1; }
  docker info >/dev/null 2>&1 || { prompt -e "Docker non è in esecuzione."; return 1; }
  if ! docker network inspect "${PROJECT}_network" >/dev/null 2>&1; then
    prompt -i "Creazione della rete '${PROJECT}_network'..."
    docker network create --driver bridge "${PROJECT}_network" >/dev/null
  fi
  _STACK_DOCKER_READY="true"
}

dockerCompose() {
  local service
  local profiles=()
  dockerPreflight
  for service in "${OPTIONAL_SERVICES[@]}"; do
    isServiceEnabled "${service}" && profiles+=(--profile "${service}")
  done
  export STACK_DIR
  docker compose -p "${PROJECT}" -f "${DOCKER_DIR}/compose.yml" \
    --env-file "${STACK_DIR}/.env" "${profiles[@]}" "$@"
}

isContainerExist() {
  local service="${1:-}" candidate
  if [[ -n "${service}" ]]; then
    [[ -n "$(dockerCompose ps -aq "${service}")" ]] || {
      prompt -e "Container del servizio '${service}' non trovato."
      return 1
    }
    return
  fi
  while IFS= read -r candidate; do
    [[ -n "$(dockerCompose ps -aq "${candidate}")" ]] && return
  done < <(listServices)
  prompt -e "Nessun container trovato per '${PROJECT}'."
  return 1
}

isContainerRunning() {
  local service="${1:-}" candidate
  if [[ -n "${service}" ]]; then
    [[ -n "$(dockerCompose ps -q "${service}")" ]] || {
      prompt -e "Container del servizio '${service}' non in esecuzione."
      return 1
    }
    return
  fi
  while IFS= read -r candidate; do
    [[ -n "$(dockerCompose ps -q "${candidate}")" ]] || {
      prompt -e "Container del servizio '${candidate}' non in esecuzione."
      return 1
    }
  done < <(listServices)
}
