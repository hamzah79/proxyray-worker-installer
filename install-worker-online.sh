#!/bin/bash
#
# ProxyRay Worker - One-Line Installer
# Version: 1.0.3
# 
# Usage: 
#   Method 1 (Interactive - Public Repo):
#     wget https://raw.githubusercontent.com/hamzah79/proxyray-worker-installer/main/install-worker-online.sh
#     sudo bash install-worker-online.sh
#
#   Method 2 (Interactive - Private Repo):
#     export GITHUB_TOKEN="ghp_xxxxxxxxxxxx"
#     wget --header="Authorization: token $GITHUB_TOKEN" https://raw.githubusercontent.com/hamzah79/proxyray-worker-installer/main/install-worker-online.sh
#     sudo -E bash install-worker-online.sh
#
#   Method 3 (Non-Interactive with Env Vars):
#     export GITHUB_TOKEN="ghp_xxxxxxxxxxxx"  # For private repo
#     export WORKER_ID="worker-2"
#     export WORKER_REGION="sg"
#     export MASTER_IP="84.247.136.121"
#     export DB_PASS="proxy_pass"
#     export REDIS_PASS="proxy_redis_pass"
#     export TOR_INSTANCES="20"
#     curl -H "Authorization: token $GITHUB_TOKEN" -fsSL https://raw.githubusercontent.com/hamzah79/proxyray-worker-installer/main/install-worker-online.sh | sudo -E bash
#

set -e

DOWNLOAD_BASE_URL="https://raw.githubusercontent.com/hamzah79/proxyray-worker-installer/main"
WORKER_PACKAGE="proxy-worker-master.tar.gz"

echo "========================================="
echo "  ProxyRay Worker - One-Line Installer"
echo "========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
  echo "Error: Please run as root (use sudo)"
  exit 1
fi

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VER=$VERSION_ID
else
    echo "Error: Cannot detect OS"
    exit 1
fi

echo "Detected OS: $OS $VER"
echo ""

# Install Docker if not installed
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com | sh
    systemctl enable docker
    systemctl start docker
    echo "✅ Docker installed"
else
    echo "✅ Docker already installed: $(docker --version)"
fi

# Install Docker Compose Plugin if not installed
if ! docker compose version &> /dev/null; then
    echo "Installing Docker Compose Plugin..."
    apt-get update -qq
    apt-get install -y docker-compose-plugin
    echo "✅ Docker Compose installed"
else
    echo "✅ Docker Compose already installed"
fi

echo ""
echo "========================================="
echo "  Worker Configuration"
echo "========================================="
echo ""

# Check if running in pipe mode (stdin not a terminal)
if [ -t 0 ]; then
    # Interactive mode - can use read
    INTERACTIVE=true
else
    # Pipe mode - use environment variables
    INTERACTIVE=false
    echo "⚠️  Running in pipe mode - using environment variables"
    echo "   Set WORKER_ID, WORKER_REGION, MASTER_IP, etc."
    echo ""
fi

# Ask for configuration or use environment variables
if [ "$INTERACTIVE" = true ]; then
    read -p "Enter Worker ID (e.g., worker-2): " WORKER_ID
    read -p "Enter Worker Region (e.g., sg, us, eu): " WORKER_REGION
    read -p "Enter Master Server IP: " MASTER_IP
    read -p "Enter Master Database Password [proxy_pass]: " DB_PASS
    DB_PASS=${DB_PASS:-proxy_pass}
    read -p "Enter Master Redis Password [proxy_redis_pass]: " REDIS_PASS
    REDIS_PASS=${REDIS_PASS:-proxy_redis_pass}
    read -p "Enter number of Tor instances [20]: " TOR_INSTANCES
    TOR_INSTANCES=${TOR_INSTANCES:-20}
else
    # Use environment variables with defaults
    WORKER_ID=${WORKER_ID:-}
    WORKER_REGION=${WORKER_REGION:-}
    MASTER_IP=${MASTER_IP:-}
    DB_PASS=${DB_PASS:-proxy_pass}
    REDIS_PASS=${REDIS_PASS:-proxy_redis_pass}
    TOR_INSTANCES=${TOR_INSTANCES:-20}
    
    # Validate required variables
    if [ -z "$WORKER_ID" ] || [ -z "$WORKER_REGION" ] || [ -z "$MASTER_IP" ]; then
        echo "❌ Error: Required environment variables not set"
        echo ""
        echo "Please set these variables before running:"
        echo "  export WORKER_ID=\"worker-2\""
        echo "  export WORKER_REGION=\"sg\""
        echo "  export MASTER_IP=\"84.247.136.121\""
        echo ""
        echo "Then run:"
        echo "  curl -fsSL https://raw.githubusercontent.com/hamzah79/proxyray-worker-installer/main/install-worker-online.sh | sudo -E bash"
        echo ""
        echo "Or download and run interactively:"
        echo "  wget https://raw.githubusercontent.com/hamzah79/proxyray-worker-installer/main/install-worker-online.sh"
        echo "  sudo bash install-worker-online.sh"
        exit 1
    fi
fi

echo ""
echo "Configuration:"
echo "  Worker ID: $WORKER_ID"
echo "  Region: $WORKER_REGION"
echo "  Master IP: $MASTER_IP"
echo "  Tor Instances: $TOR_INSTANCES"
echo ""

if [ "$INTERACTIVE" = true ]; then
    read -p "Continue? (y/n): " CONFIRM
    if [ "$CONFIRM" != "y" ]; then
        echo "Installation cancelled"
        exit 0
    fi
else
    echo "Auto-continuing in non-interactive mode..."
    sleep 2
fi

# Download and extract worker files
echo ""
echo "Downloading worker package..."
INSTALL_DIR="/opt/proxy-worker"

# Backup existing installation if exists
if [ -d "$INSTALL_DIR" ]; then
    BACKUP_DIR="/opt/proxy-worker.backup-$(date +%Y%m%d-%H%M%S)"
    echo "Backing up existing installation to $BACKUP_DIR"
    mv "$INSTALL_DIR" "$BACKUP_DIR"
fi

mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Download worker package
echo "Downloading from: $DOWNLOAD_BASE_URL/$WORKER_PACKAGE"

# Check if GITHUB_TOKEN is set (for private repos)
if [ -n "$GITHUB_TOKEN" ]; then
    echo "Using GitHub token for private repository..."
    if command -v wget &> /dev/null; then
        wget -q --show-progress --header="Authorization: token $GITHUB_TOKEN" "$DOWNLOAD_BASE_URL/$WORKER_PACKAGE" -O /tmp/worker.tar.gz
    elif command -v curl &> /dev/null; then
        curl -H "Authorization: token $GITHUB_TOKEN" -fsSL "$DOWNLOAD_BASE_URL/$WORKER_PACKAGE" -o /tmp/worker.tar.gz
    else
        echo "Error: wget or curl required"
        exit 1
    fi
else
    # Public repo - no token needed
    if command -v wget &> /dev/null; then
        wget -q --show-progress "$DOWNLOAD_BASE_URL/$WORKER_PACKAGE" -O /tmp/worker.tar.gz
    elif command -v curl &> /dev/null; then
        curl -fsSL "$DOWNLOAD_BASE_URL/$WORKER_PACKAGE" -o /tmp/worker.tar.gz
    else
        echo "Error: wget or curl required"
        exit 1
    fi
fi

echo "Extracting..."
tar xzf /tmp/worker.tar.gz -C "$INSTALL_DIR" --strip-components=1
rm /tmp/worker.tar.gz

# Create .env file
echo "Creating configuration..."

# Backup existing .env if exists
if [ -f .env ]; then
    BACKUP_ENV=".env.backup-$(date +%Y%m%d-%H%M%S)"
    echo "Backing up existing .env to $BACKUP_ENV"
    cp .env "$BACKUP_ENV"
fi

cat > .env << EOF
# ══════════════════════════════════════════════
# ProxyRay Worker Configuration
# Auto-generated by one-line installer v1.0.3
# Generated: $(date)
# ══════════════════════════════════════════════

SERVER_MODE=worker
SERVER_ID=$WORKER_ID
SERVER_REGION=$WORKER_REGION

MASTER_DATABASE_URL=postgres://proxy_app:$DB_PASS@$MASTER_IP:5432/proxy_db
MASTER_REDIS_URL=redis://:$REDIS_PASS@$MASTER_IP:6379

JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
SESSION_SECRET=your-super-secret-session-key-change-this-in-production

TRUSTED_PROXY_IPS=$MASTER_IP,127.0.0.1,::1

TOR_INSTANCES=$TOR_INSTANCES
TOR_EXIT_NODES={us},{gb}
TOR_STRICT_NODES=false
TOR_NEW_CIRCUIT_PERIOD_SECONDS=600

HTTP_PROXY_PORT=8080
SOCKS_PROXY_PORT=1080
ADMIN_PORT=9090

RETRY_MAX_ATTEMPTS=3
RETRY_INITIAL_DELAY_MS=1000
RETRY_MAX_DELAY_MS=10000
RETRY_BACKOFF_MULTIPLIER=2

CIRCUIT_BREAKER_FAILURE_THRESHOLD=10
CIRCUIT_BREAKER_SUCCESS_THRESHOLD=3
CIRCUIT_BREAKER_TIME_WINDOW_MS=60000
CIRCUIT_BREAKER_OPEN_TIMEOUT_MS=30000
CIRCUIT_BREAKER_MINIMUM_REQUESTS=10

LOG_LEVEL=info
AUTO_MIGRATE=false
EOF

# Build Docker image
echo ""
echo "Building Docker image..."
docker compose build

# Start worker
echo ""
echo "Starting worker..."
docker compose up -d

# Wait for startup
echo ""
echo "Waiting for worker to start..."
sleep 10

# Check status
echo ""
echo "========================================="
echo "  ✅ Installation Complete!"
echo "========================================="
echo ""
echo "Worker Status:"
docker compose ps

echo ""
echo "Checking Tor bootstrap (this may take a minute)..."
sleep 20
BOOTSTRAPPED=$(docker logs rotating-proxy 2>&1 | grep -c "Bootstrapped 100" || true)
echo "Tor instances bootstrapped: $BOOTSTRAPPED / $TOR_INSTANCES"

echo ""
echo "📋 Useful commands:"
echo "  cd $INSTALL_DIR"
echo "  docker compose logs -f rotating-proxy"
echo "  docker compose restart rotating-proxy"
echo "  docker compose down"
echo ""
echo "🌐 Check admin panel: http://$MASTER_IP:9090/admin-ui"
echo ""
