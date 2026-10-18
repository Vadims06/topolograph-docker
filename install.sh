#!/bin/bash

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

SUMMARY=()

check_mark() {
  echo -e "${GREEN}✔ $1${NC}"
}

cross_mark() {
  echo -e "${RED}✘ $1${NC}"
}

# ---------- INSTALLERS ----------

install_docker_ubuntu() {
  echo "Installing Docker for Ubuntu..."
  sudo apt-get update
  sudo apt-get install ca-certificates curl
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  check_mark "Docker installed (Ubuntu)"
}

install_git() {
  echo "Installing Git..."
  sudo apt-get update
  sudo apt-get install -y git
  check_mark "Git installed"
}

# ---------- CHECKERS ----------

check_docker_installed() {
  if ! command -v docker &>/dev/null; then
    if [[ -f /etc/lsb-release ]] && grep -qi ubuntu /etc/lsb-release; then
      install_docker_ubuntu
    else
      cross_mark "Docker is not installed. Please install Docker manually for your OS."
      exit 1
    fi
  else
    check_mark "Docker is installed"
  fi
}

check_docker_compose_cmd() {
  if docker compose version &>/dev/null; then
    echo "Using 'docker compose'"
    DOCKER_COMPOSE="docker compose"
  elif docker-compose version &>/dev/null; then
    echo "Using 'docker-compose'"
    DOCKER_COMPOSE="docker-compose"
  else
    cross_mark "Neither 'docker compose' nor 'docker-compose' found!"
    exit 1
  fi
}

check_git_installed() {
  if ! command -v git &>/dev/null; then
    install_git
  else
    check_mark "Git is installed"
  fi
}

check_container_running() {
  local name=$1
  if sudo docker ps --format '{{.Names}}' | grep -q "$name"; then
    check_mark "Container $name    Running"
    return 0
  else
    cross_mark "Container $name    Not Running"
    return 1
  fi
}

# ---------- CORE FUNCTIONS ----------

ask_installation_options() {
  echo "Checking Topolograph Suite Status..."
  check_docker_installed
  check_git_installed
  check_docker_compose_cmd

  local topolograph_missing=false

  if ! docker ps --format '{{.Names}}' | grep -q "flask"; then
    cross_mark "Container topolograph    Not Running"
    topolograph_missing=true
  else
    check_mark "Container topolograph    Running"
  fi

  if [[ ! -d "topolograph" ]]; then
    cross_mark "Topolograph folder not found"
    topolograph_missing=true
  fi

  if [[ "$topolograph_missing" == true ]]; then
    read -rp "Topolograph is not running or missing. Do you want to install it now? (y/n): " install_topo
    if [[ "$install_topo" =~ ^[Yy]$ ]]; then
      INSTALL_TOPO=true
    else
      echo "Cannot continue without Topolograph. Exiting."
      exit 1
    fi
  fi
}

# ---------- STARTERS ----------

start_topolograph() {
  echo "Starting Topolograph..."
  if check_container_running flask; then
    echo "Topolograph is already running."
  else
    git clone https://github.com/Vadims06/topolograph-docker.git topolograph || true
    cd topolograph
    if [[ ! -f .env ]]; then
      cp env.example .env
      # A fresh database gets its own password instead of the published default.
      sed -i "s/^MONGODB_PASSWORD=.*/MONGODB_PASSWORD=$(head -c 16 /dev/urandom | od -An -tx1 | tr -d ' \\n')/" .env
      check_mark ".env created from env.example"
    fi
    $DOCKER_COMPOSE up -d
    cd ..
  fi
  SUMMARY+=("Topolograph started")
}

fix_ownership() {
  local user="${SUDO_USER:-root}"
  local group
  group=$(id -gn "$user")
  if [[ -d topolograph ]]; then
    sudo chown -R "$user:$group" topolograph
    check_mark "Ownership fixed for topolograph (set to $user:$group)"
  fi
}

print_summary() {
  echo -e "\n${GREEN}=== Installation Summary ===${NC}"
  for item in "${SUMMARY[@]}"; do
    check_mark "$item"
  done
}

main() {
  ask_installation_options
  if [[ "$INSTALL_TOPO" == true ]]; then
    start_topolograph
  fi
  fix_ownership
  print_summary
  # Watchers that feed Topolograph are registered from its UI, an Enterprise feature.
  echo -e "\nWatchers that send live events to Topolograph are part of Enterprise: https://topolograph.com/#editions"
}

main
