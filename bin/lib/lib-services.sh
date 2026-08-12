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
  while IFS=',' read -ra ENABLED; do
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

# Get only enabled optional services
getOptionalServices() {
  local services=()
  for service in "${SERVICES[@]}"; do
    if [[ ! "${CORE_SERVICES[*]}" =~ $service ]]; then
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
  [[ "${SERVICES[*]}" =~ $service ]]
}

# Enable a service
enableService() {
  local service=$1

  # Validate service exists
  if [[ ! "${OPTIONAL_SERVICES[*]}" =~ $service ]]; then
    message --error "Service '$service' not found"
    return 1
  fi

  # Add to services file if not already enabled
  if ! isServiceEnabled "$service"; then
    if [[ -f "${STACK_DIR}/services" ]]; then
      echo -n ",$service" >> "${STACK_DIR}/services"
    else
      echo "$service" > "${STACK_DIR}/services"
    fi
  fi
}

# Disable a service
disableService() {
  local service=$1

  # Validate service exists
  if [[ ! "${OPTIONAL_SERVICES[*]}" =~ $service ]]; then
    message --error "Service '$service' not found"
    return 1
  fi

  # Remove from services file if enabled
  if isServiceEnabled "$service"; then
    sed -i "/$service/d" "${STACK_DIR}/services"
  fi
}
