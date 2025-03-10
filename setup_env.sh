#!/usr/bin/env bash
# Adam OS Environment Setup - v1.1

set -eo pipefail

# Configuration
CONFIG_FILE="./oracle_config.env"
REPO_URL="https://github.com/glen-martin-tvmsi/adam-manager.git"
INSTALL_DIR="${HOME}/adam-oracle"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

install_dependencies() {
    echo -e "${GREEN}Checking system dependencies...${NC}"
    
    # Package lists
    DEBIAN_PKGS=("tree" "cloc" "jq" "git" "python3" "python3-pip" "unzip")
    MAC_PKGS=("tree" "cloc" "jq" "git" "python" "gnu-sed")

    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo apt-get update
        sudo apt-get install -y "${DEBIAN_PKGS[@]}"
        pip3 install --user -U pip setuptools
        
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        if ! command -v brew >/dev/null; then
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        brew install "${MAC_PKGS[@]}"
        
    else
        echo -e "${RED}Unsupported OS: $OSTYPE${NC}"
        exit 1
    fi
}

setup_directories() {
    echo -e "${GREEN}Creating directory structure...${NC}"
    mkdir -p "$INSTALL_DIR"
    mkdir -p "${HOME}/adam_reports"
}

deploy_config() {
    echo -e "${GREEN}Deploying configuration...${NC}"
    cp "$CONFIG_FILE" "$INSTALL_DIR/oracle_config.env"

    # Add to shell profiles
    for PROFILE in ~/.bashrc ~/.zshrc; do
        if [ -f "$PROFILE" ]; then
            echo "source $INSTALL_DIR/oracle_config.env" | tee -a "$PROFILE" >/dev/null
        fi
    done
}

install_oracle() {
    echo -e "${GREEN}Installing Oracle components...${NC}"
    cp "./oracle_analyzer.sh" "$INSTALL_DIR/oracle_analyzer.sh"
    chmod +x "$INSTALL_DIR/oracle_analyzer.sh"

    # Install Python dependencies (if required)
    pip3 install --user -r <(echo "")
}

validate_install() {
    echo -e "\n${GREEN}Validating installation...${NC}"
    
    if ! [ -f "$INSTALL_DIR/oracle_analyzer.sh" ]; then
        echo -e "${RED}Oracle script not found in installation directory!${NC}"
        exit 1
    fi

    echo -e "${GREEN}Testing analysis...${NC}"
    mkdir -p /tmp/adam-test && cd /tmp/adam-test
    git clone -q https://github.com/glen-martin-tvmsi/adam-manager.git .
    bash "$INSTALL_DIR/oracle_analyzer.sh"
    rm -rf /tmp/adam-test
}

main() {
    echo -e "${GREEN}Starting Adam OS Environment Setup${NC}"
    
    install_dependencies
    setup_directories
    deploy_config
    install_oracle
    validate_install
    
    echo -e "\n${GREEN}Setup complete! Run '$INSTALL_DIR/oracle_analyzer.sh' in any project directory.${NC}"
}

# Handle arguments
case "$1" in
    -h|--help)
        echo "Usage: ./setup_env.sh [OPTIONS]"
        echo "Options:"
        echo "  -h  Show this help"
        exit 0
        ;;
    *)
        main
        ;;
esac
