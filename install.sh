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
    1) INSTALL_OSPF=true; ask_deployment_mode "ospf";;
    2) INSTALL_ISIS=true; ask_deployment_mode "isis";;
    3) INSTALL_OSPF=true; ask_deployment_mode "ospf"; INSTALL_ISIS=true; ask_deployment_mode "isis";;
    4) echo "No components selected for installation.";;
    *) echo "Invalid choice"; exit 1;;
  esac
}

ask_deployment_mode() {
  local proto=$1
  echo -e "\nSelect deployment mode for ${proto^^} Watcher:"
  echo "  1) Local clab"
  echo "  2) Network device"
  read -rp "Enter your choice (1-2): " mode
  case $mode in
    1) eval "DEPLOY_${proto^^}_CLAB=true";;
    2) eval "DEPLOY_${proto^^}_NETDEV=true";;
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

# ---------- STARTERS ----------

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
  if [[ ! -d "$BASE_DIR/ospfwatcher" ]]; then
    echo "[$(date)] Cloning ospfwatcher repository..."
    git clone https://github.com/Vadims06/ospfwatcher.git ospfwatcher
    check_mark "OSPF Watcher repository cloned."
  else
    cross_mark "OSPF Watcher repository exists"
  fi

  cd ospfwatcher || exit

  if [[ "$DEPLOY_OSPF_CLAB" == true ]]; then
    echo "[$(date)] start prepairing clab"
    ./containerlab/ospf01/prepare.sh
    check_mark "Local clab prepaired."
    # create expected folder for watcher logs
    mkdir -p ./watcher
    BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    # Symlink for logstash
    ln -sfn "$BASE_DIR/containerlab/ospf01/watcher/logs" "$BASE_DIR/watcher"
    
    # Ask user for host IP. Communication between containers using 127.0.0.1 doesn't work
    while true; do
        read -rp "Enter the host IP address where Docker is hosted: " HOST_IP
        if [[ -n "$HOST_IP" ]]; then
            break
        else
            echo "Host IP cannot be empty. Please try again."
        fi
    done

    # Replace TOPOLOGRAPH_HOST in .env
    if [[ -f .env ]]; then
        sed -i "s/^TOPOLOGRAPH_HOST=.*/TOPOLOGRAPH_HOST=${HOST_IP}/" .env
        sed -i "s/^WEBHOOK_URL=.*/WEBHOOK_URL=${HOST_IP}/" .env
        sed -i 's/^DEBUG_BOOL=False/DEBUG_BOOL=True/' .env
        echo "[$(date)] DEBUG_BOOL set to True in .env"
    fi

    echo "[$(date)] start local clab"
    sudo clab deploy --topo containerlab/ospf01/ospf01.clab.yml
    check_mark "Local clab has been successfully started."
    SUMMARY+=("OSPF Watcher lab deployed with Containerlab")
  else
    # If symlink exists, remove it and restart docker-compose
    if [[ -L ./watcher/logs ]]; then
        echo "[$(date)] Removing existing watcher/logs symlink to avoid conflicts"
        unlink ./watcher/logs
        echo "[$(date)] Restarting Docker Compose for affected services..."
        # Optionally, you can specify the services if you don't want all
        docker compose down
        docker compose up -d

        echo "[$(date)] Docker Compose restarted successfully."
    fi
    generate_watcher_configs "ospf"
    echo "Run on network device mode (no lab auto-deploy)."
  fi

  if ! check_container_running ospf-logstash; then
    sudo $DOCKER_COMPOSE build
    sudo $DOCKER_COMPOSE up -d
    SUMMARY+=("Logstash to export OSPF Watcher logs started")
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

  if [[ "$DEPLOY_ISIS_CLAB" == true ]]; then
    ln -sfn containerlab/isis01/watcher/logs watcher/logs
    ./containerlab/isis01/prepare.sh
    sudo clab deploy --topo containerlab/isis01/isis01.clab.yml
    SUMMARY+=("ISIS Watcher lab deployed with Containerlab")
  else
    generate_watcher_configs "isis"
    echo "Run on network device mode (no lab auto-deploy)."
  fi

  if ! check_container_running isis-logstash; then
    sudo $DOCKER_COMPOSE build
    sudo $DOCKER_COMPOSE up -d
    SUMMARY+=("Logstash to export ISIS Watcher logs started")
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
