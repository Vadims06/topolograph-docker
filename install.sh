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

  # Add the repository to Apt sources:
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  check_mark "Docker installed (Ubuntu)"
}

install_clab() {
  echo "Installing Containerlab..."
  bash -c "$(curl -sL https://get.containerlab.dev)"
  check_mark "Containerlab installed"
}

install_git() {
  echo "Installing Git..."
  sudo apt-get update
  sudo apt-get install -y git
  check_mark "Git installed"
}

install_conntrack() {
  echo "Installing conntrack..."
  sudo apt-get update
  sudo apt-get install -y conntrack
  check_mark "Conntrack installed"
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

check_clab_installed() {
  if ! command -v clab &>/dev/null; then
    install_clab
  else
    check_mark "Containerlab is installed"
  fi
}

check_git_installed() {
  if ! command -v git &>/dev/null; then
    install_git
  else
    check_mark "Git is installed"
  fi
}

check_conntrack_installed() {
  if ! command -v conntrack &>/dev/null; then
    install_conntrack
  else
    check_mark "Conntrack is installed"
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

check_topolograph_suite_state() {
  echo "Checking Topolograph Suite Status..."
  check_docker_installed
  check_clab_installed
  check_git_installed
  check_conntrack_installed
  check_docker_compose_cmd
  check_container_running flask
  check_container_running ospfwatcher
  check_container_running isiswatcher
}

ask_installation_options() {
  echo "Checking Topolograph Suite Status..."
  check_docker_installed
  check_clab_installed
  check_git_installed
  check_conntrack_installed
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

  echo -e "\nWatchers are needed to listen to real network and log changes"
  echo -e "Select components to install:"
  echo "  1) OSPF Watcher"
  echo "  2) ISIS Watcher"
  echo "  3) Both"
  echo "  4) Do not install anything"
  read -rp "Enter your choice (1-4): " choice
  case $choice in
    1) INSTALL_OSPF=true;;
    2) INSTALL_ISIS=true;;
    3) INSTALL_OSPF=true; INSTALL_ISIS=true;;
    4) echo "No components selected for installation.";;
    *) echo "Invalid choice"; exit 1;;
  esac
}

generate_watcher_configs() {
  local protocol=$1
  echo "Generating watcher configs for $protocol..."

  sudo docker run -it --rm --user "$UID" \
    -v "$(pwd):/home/watcher/watcher/" \
    -v /etc/passwd:/etc/passwd:ro \
    -v /etc/group:/etc/group:ro \
    vadims06/${protocol}-watcher:latest python3 ./client.py --action add_watcher
}

select_watcher_folder() {
  local script_dir
  script_dir="$(pwd)"
  local possible_dirs=("ospfwatcher/watcher" "isiswatcher/watcher" "watcher")
  local folders=()
  local labels=()

  shopt -s nullglob
  for dir in "${possible_dirs[@]}"; do
    local abs_dir="$script_dir/$dir"
    [[ -d "$abs_dir" ]] || continue
    for d in "$abs_dir"/watcher*-gre*-*/; do
      [[ -d "$d" ]] || continue
      folders+=("${d%/}")
      labels+=("$(basename "${d%/}")")
    done
  done
  shopt -u nullglob

  if [[ ${#folders[@]} -eq 0 ]]; then
    echo "No watcher config folders found!" >&2
    return 1
  fi

  >&2 echo "Available OSPF/ISIS watcher configurations:"
  for i in "${!folders[@]}"; do
    >&2 echo "  $((i+1))) ${labels[i]}"
  done

  local choice
  read -rp "Select watcher folder to deploy (1-${#folders[@]}): " choice
  if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#folders[@]} )); then
    echo "Invalid choice." >&2
    return 1
  fi
  echo "${folders[$((choice - 1))]}"
}

start_topolograph() {
  echo "Starting Topolograph..."
  if check_container_running flask; then
    echo "Topolograph is already running."
  else
    git clone https://github.com/Vadims06/topolograph-docker.git topolograph || true
    cd topolograph
    $DOCKER_COMPOSE up -d
    cd ..
  fi
  SUMMARY+=("Topolograph started")
}

start_ospfwatcher() {
  echo -e "\n${GREEN}=== Starting OSPF Watcher ===${NC}"
  if git clone https://github.com/Vadims06/ospfwatcher.git ospfwatcher >/dev/null 2>&1; then
    check_mark "OSPF Watcher repository cloned."
  else
    cross_mark "OSPF Watcher repository exists or failed to clone."
  fi

  cd ospfwatcher || exit
  generate_watcher_configs "ospf"
  watcher_folder=$(select_watcher_folder)

  echo "Deploying watcher from folder: '$(basename "$watcher_folder")'"
  if [[ -f "$watcher_folder/config.yml" ]]; then
    sudo clab deploy --topo "$watcher_folder/config.yml"
    if ! check_container_running ospf-logstash; then
      sudo $DOCKER_COMPOSE build
      sudo $DOCKER_COMPOSE up -d
      SUMMARY+=("Logstash to export OSPF Watcher logs started")
    fi
    SUMMARY+=("OSPF Watcher deployed from $(basename "$watcher_folder")")
  else
    echo "Error: config.yml not found in $watcher_folder"
    exit 1
  fi
  cd ..
}

start_isiswatcher() {
  echo -e "\n${GREEN}=== Starting ISIS Watcher ===${NC}"
  if git clone https://github.com/Vadims06/isiswatcher.git isiswatcher >/dev/null 2>&1; then
    check_mark "ISIS Watcher repository cloned."
  else
    cross_mark "ISIS Watcher repository exists or failed to clone."
  fi

  cd isiswatcher || exit
  generate_watcher_configs "isis"
  watcher_folder=$(select_watcher_folder)

  echo "Deploying watcher from folder: '$(basename "$watcher_folder")'"
  if [[ -f "$watcher_folder/config.yml" ]]; then
    sudo clab deploy --topo "$watcher_folder/config.yml"
    if ! check_container_running isis-logstash; then
      sudo $DOCKER_COMPOSE build
      sudo $DOCKER_COMPOSE up -d
      SUMMARY+=("Logstash to export ISIS Watcher logs started")
    fi
    SUMMARY+=("ISIS Watcher deployed from $(basename "$watcher_folder")")
  else
    echo "Error: config.yml not found in $watcher_folder"
    exit 1
  fi
  cd ..
}

fix_ownership() {
  local user="${SUDO_USER:-root}"
  local group
  group=$(id -gn "$user")
  for dir in topolograph ospfwatcher isiswatcher; do
    if [[ -d "$dir" ]]; then
      sudo chown -R "$user:$group" "$dir"
      check_mark "Ownership fixed for $dir (set to $user:$group)"
    fi
  done
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
  if [[ "$INSTALL_OSPF" == true ]]; then
    start_ospfwatcher
  fi
  if [[ "$INSTALL_ISIS" == true ]]; then
    start_isiswatcher
  fi
  fix_ownership
  print_summary
}

main
