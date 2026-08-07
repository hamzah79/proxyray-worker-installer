#!/bin/bash
#
# ProxyRay Worker - Deploy Script
# 
# Usage:
#   ./deploy-worker.sh <WORKER_IP> <WORKER_PASSWORD>
#
# Example:
#   ./deploy-worker.sh 167.99.78.85 Hamzah79AA
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check arguments
if [ $# -ne 2 ]; then
    echo -e "${RED}Error: Missing arguments${NC}"
    echo "Usage: $0 <WORKER_IP> <WORKER_PASSWORD>"
    echo "Example: $0 167.99.78.85 Hamzah79AA"
    exit 1
fi

WORKER_IP=$1
WORKER_PASS=$2
WORKER_USER="root"
WORKER_DIR="/opt/proxy-worker"

echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}  ProxyRay Worker - Deploy Script${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo -e "Target: ${YELLOW}${WORKER_USER}@${WORKER_IP}${NC}"
echo -e "Directory: ${YELLOW}${WORKER_DIR}${NC}"
echo ""

# Check if sshpass is installed
if ! command -v sshpass &> /dev/null; then
    echo -e "${YELLOW}Installing sshpass...${NC}"
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo apt-get update -qq && sudo apt-get install -y sshpass
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        brew install hudochenkov/sshpass/sshpass
    else
        echo -e "${RED}Error: Please install sshpass manually${NC}"
        exit 1
    fi
fi

# Check if worker directory exists
echo -e "${YELLOW}Checking worker directory...${NC}"
sshpass -p "$WORKER_PASS" ssh -o StrictHostKeyChecking=no ${WORKER_USER}@${WORKER_IP} "
    if [ ! -d '${WORKER_DIR}' ]; then
        echo 'Creating directory...'
        mkdir -p '${WORKER_DIR}'
    fi
" || {
    echo -e "${RED}Error: Cannot connect to worker${NC}"
    exit 1
}

# Sync source code
echo -e "${YELLOW}Syncing source code...${NC}"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"

rsync -avz --progress \
    --exclude='node_modules' \
    --exclude='.git' \
    --exclude='dist' \
    --exclude='frontend-v2' \
    --exclude='.env' \
    -e "sshpass -p '$WORKER_PASS' ssh -o StrictHostKeyChecking=no" \
    "$PARENT_DIR/src/" \
    ${WORKER_USER}@${WORKER_IP}:${WORKER_DIR}/src/

# Sync package files
echo -e "${YELLOW}Syncing package files...${NC}"
rsync -avz --progress \
    -e "sshpass -p '$WORKER_PASS' ssh -o StrictHostKeyChecking=no" \
    "$PARENT_DIR/package.json" \
    "$PARENT_DIR/package-lock.json" \
    ${WORKER_USER}@${WORKER_IP}:${WORKER_DIR}/

# Sync Docker files
echo -e "${YELLOW}Syncing Docker files...${NC}"
rsync -avz --progress \
    -e "sshpass -p '$WORKER_PASS' ssh -o StrictHostKeyChecking=no" \
    "$PARENT_DIR/Dockerfile" \
    "$PARENT_DIR/docker-compose.yml" \
    "$PARENT_DIR/.dockerignore" \
    ${WORKER_USER}@${WORKER_IP}:${WORKER_DIR}/

# Build Docker image
echo -e "${YELLOW}Building Docker image (this may take a few minutes)...${NC}"
sshpass -p "$WORKER_PASS" ssh -o StrictHostKeyChecking=no ${WORKER_USER}@${WORKER_IP} "
    cd '${WORKER_DIR}'
    docker compose build --no-cache rotating-proxy
" || {
    echo -e "${RED}Error: Docker build failed${NC}"
    exit 1
}

# Recreate container
echo -e "${YELLOW}Recreating container...${NC}"
sshpass -p "$WORKER_PASS" ssh -o StrictHostKeyChecking=no ${WORKER_USER}@${WORKER_IP} "
    cd '${WORKER_DIR}'
    docker compose up -d rotating-proxy
" || {
    echo -e "${RED}Error: Container recreate failed${NC}"
    exit 1
}

# Wait for container to start
echo -e "${YELLOW}Waiting for container to start...${NC}"
sleep 5

# Check container status
echo -e "${YELLOW}Checking container status...${NC}"
sshpass -p "$WORKER_PASS" ssh -o StrictHostKeyChecking=no ${WORKER_USER}@${WORKER_IP} "
    cd '${WORKER_DIR}'
    docker compose ps rotating-proxy
"

echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}  ✅ Deploy Complete!${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo -e "Worker: ${YELLOW}${WORKER_IP}${NC}"
echo -e "Status: ${GREEN}Running${NC}"
echo ""
echo -e "Check logs:"
echo -e "  ${YELLOW}ssh ${WORKER_USER}@${WORKER_IP}${NC}"
echo -e "  ${YELLOW}cd ${WORKER_DIR} && docker compose logs -f rotating-proxy${NC}"
echo ""
