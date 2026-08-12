#!/bin/bash

# Set Library Name
LIB_NAME="lib-services.sh"

# Check if STACK_DIR is set
if [[ ! "${STACK_DIR}" ]]; then
  echo "Please define 'STACK_DIR' variable"; exit 1
fi

# Check if lib-core.sh is already imported
if [[ "${PROCESS_SOURCE[*]}" =~ $LIB_NAME ]]; then
  echo "Warning! '${LIB_NAME}' is already imported"; exit 1
fi

# Add lib-core.sh to the list of imported files
PROCESS_SOURCE=("$LIB_NAME")

# ---------------------------------------------------------------------
# Variables
# ---------------------------------------------------------------------

# ------------Services--------------#
CORE_SERVICES=("webserver" "database")
OPTIONAL_SERVICES=("phpmyadmin" "mailhog")

# Combine CORE_SERVICES and the services from services (only the enabled ones)
SERVICES=()
SERVICES=("${CORE_SERVICES[@]}")
if [[ -f "${STACK_DIR}/services" ]]; then
  # Read comma-separated services from file
  while IFS=',' read -ra ENABLED || [[ ${#ENABLED[@]} -gt 0 ]]; do
    for service in "${ENABLED[@]}"; do
      # Trim whitespace
      service=$(echo "$service" | xargs)
      if [[ -n "$service" ]]; then
        SERVICES+=("$service")
      fi
    done
  done < "${STACK_DIR}/services"
fi

# ------------Services Descriptions--------------#
SERVICE_DESCRIPTIONS=(
  "phpmyadmin:Web interface for MySQL database management"
  "mailhog:Email testing tool for local development"
)

# ---------------------------------------------------------------------
# Services
# ---------------------------------------------------------------------

# Check if a value is present in the given list (exact match)
containsService() {
  local needle=$1; shift

  for item in "$@"; do
    if [[ "$item" == "$needle" ]]; then
      return 0
    fi
  done

  return 1
}

# Persist the currently enabled optional services to the services file
saveEnabledServices() {
  local enabled=()
  for service in "${SERVICES[@]}"; do
    if ! containsService "$service" "${CORE_SERVICES[@]}"; then
      enabled+=("$service")
    fi
  done

  # Write them back comma-separated
  local IFS=','
  echo "${enabled[*]}" > "${STACK_DIR}/services"
}

# Get only enabled optional services
getOptionalServices() {
  local services=()
  for service in "${SERVICES[@]}"; do
    if ! containsService "$service" "${CORE_SERVICES[@]}"; then
      services+=("$service")
    fi
  done
  echo "${services[@]}"
}

# Get all available optional services
getAllOptionalServices() {
  echo "${OPTIONAL_SERVICES[@]}"
}

# Get service description
getServiceDescription() {
  local service=$1

  for desc in "${SERVICE_DESCRIPTIONS[@]}"; do
    IFS=':' read -r svc description <<< "$desc"
    if [[ "$svc" == "$service" ]]; then
      echo "$description"
      return
    fi
  done

  echo "No description available"
}

listAllOptionalServices() {
  # Get all optional services
  services=($(getAllOptionalServices))

  # Print each service with its status and description
  for service in "${services[@]}"; do

    status="disabled"
    if isServiceEnabled "$service"; then
      status="enabled"
    fi

    description=$(getServiceDescription "$service")

    helpify "$service" "$description" "Status: $status"
  done
}

# Check if service is enabled
isServiceEnabled() {
  local service=$1
  containsService "$service" "${SERVICES[@]}"
}

# Enable a service
enableService() {
  local service=$1

  # Validate service exists
  if ! containsService "$service" "${OPTIONAL_SERVICES[@]}"; then
    message --error "Service '$service' not found"
    return 1
  fi

  # Enable the service if not already enabled
  if ! isServiceEnabled "$service"; then
    SERVICES+=("$service")
    saveEnabledServices
  fi
}

# Disable a service
disableService() {
  local service=$1

  # Validate service exists
  if ! containsService "$service" "${OPTIONAL_SERVICES[@]}"; then
    message --error "Service '$service' not found"
    return 1
  fi

  # Drop only this service
  if isServiceEnabled "$service"; then
    local remaining=()
    for item in "${SERVICES[@]}"; do
      if [[ "$item" != "$service" ]]; then
        remaining+=("$item")
      fi
    done

    SERVICES=("${remaining[@]}")
    saveEnabledServices
  fi
}
