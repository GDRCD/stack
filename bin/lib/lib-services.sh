#!/usr/bin/env bash

CORE_SERVICES=(webserver database)
OPTIONAL_SERVICES=(phpmyadmin mailhog)
SERVICE_DESCRIPTIONS=(
  "phpmyadmin|Interfaccia web per la gestione MySQL"
  "mailhog|Strumento per testare l'invio email"
)
SERVICES=("${CORE_SERVICES[@]}")

trim_value() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "${value}"
}

containsValue() {
  local needle="$1" item
  shift
  for item in "$@"; do [[ "${item}" == "${needle}" ]] && return 0; done
  return 1
}

if [[ -f "${STACK_DIR}/services" ]]; then
  while IFS=',' read -r -a enabled || [[ ${#enabled[@]} -gt 0 ]]; do
    for service in "${enabled[@]}"; do
      service="$(trim_value "${service}")"
      [[ -z "${service}" ]] && continue
      is_optional="false"
      containsValue "${service}" "${OPTIONAL_SERVICES[@]}" && is_optional="true"
      [[ "${is_optional}" == "true" ]] && SERVICES+=("${service}")
    done
  done <"${STACK_DIR}/services"
fi

listServices() { printf '%s\n' "${SERVICES[@]}"; }
listOptionalServices() { printf '%s\n' "${OPTIONAL_SERVICES[@]}"; }
isServiceEnabled() { containsValue "$1" "${SERVICES[@]}"; }
isOptionalService() { containsValue "$1" "${OPTIONAL_SERVICES[@]}"; }

serviceDescription() {
  local record
  for record in "${SERVICE_DESCRIPTIONS[@]}"; do
    [[ "${record%%|*}" == "$1" ]] && { printf '%s\n' "${record#*|}"; return; }
  done
}

saveEnabledServices() {
  local service IFS=,
  local enabled=()
  for service in "${SERVICES[@]}"; do
    containsValue "${service}" "${CORE_SERVICES[@]}" || enabled+=("${service}")
  done
  printf '%s\n' "${enabled[*]}" >"${STACK_DIR}/services"
}

enableService() {
  isOptionalService "$1" || return 2
  isServiceEnabled "$1" || SERVICES+=("$1")
  saveEnabledServices
}

disableService() {
  local service
  local remaining=()
  isOptionalService "$1" || return 2
  for service in "${SERVICES[@]}"; do [[ "${service}" == "$1" ]] || remaining+=("${service}"); done
  SERVICES=("${remaining[@]}")
  saveEnabledServices
}
