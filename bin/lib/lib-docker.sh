#!/bin/bash

# ---------------------------------------------------------------------
# Variables
# ---------------------------------------------------------------------

# ---------------------------------------------------------------------
# Utilities
# ---------------------------------------------------------------------

# Check if env file exists
isEnvFileExists() {
  if [[ ! -f "${STACK_DIR}/.env" ]]; then
    prompt -e "Error! '.env' file is not found. Please create it first."
    exit 1
  fi
}

# Check if docker is installed
isDockerInstalled() {
  if ! command -v docker &> /dev/null; then
    prompt -e "Error! Docker is not installed. Please install it first."
    exit 1
  fi
}

# Check if docker-compose is installed
isDockerComposeInstalled() {
  if ! command -v docker compose &> /dev/null; then
    prompt -e "Error! Docker Compose is not installed. Please install it first."
    exit 1
  fi
}

# Check if docker is running
isDockerRunning() {
  if ! docker info &> /dev/null; then
    prompt -e "Error! Docker is not running. Please start it first."
    exit 1
  fi
}

# Check if container network exists
isContainerExist() {
  # if container name is passed as argument, i check if it exists
  if [[ "$1" ]]; then
    if [[ ! "$(docker ps -aq -f name="${PROJECT}_$1")" ]]; then
      prompt -e "Error! Container '${PROJECT}_$1' is not found."
      prompt -i "Run '${STACK_COMMAND_NAME} recreate' to create it."
      exit 1
    fi
    return 0;
  fi

  # otherwise, i check if at least one container exists
  local found=0
  for service in "${SERVICES[@]}"; do
    # database
    if [[ "$service" == "database" ]]; then
      if [[ "$(docker ps -aq -f name="${PROJECT}_$service")" ]]; then
        found=1
        break
      fi
      continue
    fi

    # other services
    if [[ "$(docker ps -aq -f name="${PROJECT}_$service")" ]]; then
      found=1
      break
    fi
  done

  if [[ $found -eq 0 ]]; then
    prompt -e "Error! No containers found for project '${PROJECT}'."
    prompt -i "Run '${STACK_COMMAND_NAME} recreate' to create them."
    exit 1
  fi
}

# Check if container is running
isContainerRunning() {
  # if container name is passed as argument, i check if it's running
  if [[ "$1" ]]; then
    if [[ ! "$(docker ps -q -f name="${PROJECT}_$1")" ]]; then
      prompt -e "Error! Container '${PROJECT}_$1' is not running."
      exit 1
    fi
    return 0;
  fi

  # otherwise, i check if all containers are running
  for service in "${SERVICES[@]}"; do
    # database
    if [[ "$service" == "database" ]]; then
      if [[ ! "$(docker ps -q -f name="${PROJECT}_$service")" ]]; then
        prompt -e "Error! Container '${PROJECT}_$service' is not running."
        exit 1
      fi
      continue
    fi
    # other services
    if [[ ! "$(docker ps -q -f name="${PROJECT}_$service")" ]]; then
      prompt -e "Error! Container '${PROJECT}_$service' is not running."
      exit 1
    fi
  done
}

# Check if docker network exists, otherwise create it
isStackNetworkExists() {
  if [[ ! "$(docker network ls -q -f name=${PROJECT}_network)" ]]; then
    prompt -i "Creating '${PROJECT}_network' docker network... "
    docker network create --driver bridge "${PROJECT}_network"
  fi
}

# ---------------------------------------------------------------------
# Commands
# ---------------------------------------------------------------------

dockerCompose() {
  # Check if docker compose is installed
  isDockerComposeInstalled
  # Check if docker is running
  isDockerRunning
  # Check if env file exists
  isEnvFileExists
  # Check if stack network exists, otherwise create it
  isStackNetworkExists

  # Build profiles array based on enabled services
  profiles=()
  for service in "${OPTIONAL_SERVICES[@]}"; do
    if isServiceEnabled "$service"; then
      profiles+=("--profile" "$service")
    fi
  done

  export STACK_DIR ;
  docker compose -p "${PROJECT}" -f "$DOCKER_DIR/compose.yml" --env-file "$STACK_DIR/.env" "${profiles[@]}" "$@"
}
