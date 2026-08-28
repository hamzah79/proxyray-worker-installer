#!/bin/bash
#
# ProxyRay Worker - One-Line Installer (v2.1.0)
# Fixed: uses prebuilt dist instead of npm run build (avoids source mismatch)
#
# Usage:
#   Method 1 (Interactive):
#     wget https://raw.githubusercontent.com/hamzah79/proxyray-worker-installer/main/install-worker-online.sh
#     sudo bash install-worker-online.sh
#
#   Method 2 (Non-Interactive with Env Vars):
#     export WORKER_ID="worker-2"
#     export WORKER_REGION="sg"
#     export MASTER_IP="84.247.136.121"
#     export DB_PASS="proxy_pass"
#     export REDIS_PASS="proxy_redis_pass"
#     export TOR_INSTANCES="20"
#     curl -fsSL https://raw.githubusercontent.com/hamzah79/proxyray-worker-installer/main/install-worker-online.sh | sudo -E bash

set -e

echo "========================================="
echo "  ProxyRay Worker - One-Line Installer v2.1.0"
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
    apt-get update -qq 2>/dev/null || apk add --no-cache docker-compose 2>/dev/null || true
    apt-get install -y docker-compose-plugin 2>/dev/null || true
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
    INTERACTIVE=true
else
    INTERACTIVE=false
    echo "⚠️  Running in pipe mode - using environment variables"
    echo "   Set WORKER_ID, WORKER_REGION, MASTER_IP, etc."
    echo ""
fi

# Ask for configuration or use environment variables
if [ "$INTERACTIVE" = true ]; then
    read -p "Enter Worker ID (e.g., worker-2): " WORKER_ID
    while [ -z "$WORKER_ID" ]; do
        echo "❌ Worker ID cannot be empty!"
        read -p "Enter Worker ID (e.g., worker-2): " WORKER_ID
    done
    
    read -p "Enter Worker Region (e.g., sg, us, eu): " WORKER_REGION
    while [ -z "$WORKER_REGION" ]; do
        echo "❌ Worker Region cannot be empty!"
        read -p "Enter Worker Region (e.g., sg, us, eu): " WORKER_REGION
    done
    
    # Auto-detect public IP
    echo "Detecting public IP..."
    PUBLIC_IP=$(curl -s ifconfig.me || curl -s icanhazip.com || echo "")
    if [ -n "$PUBLIC_IP" ]; then
        read -p "Enter Worker Public IP [$PUBLIC_IP]: " PUBLIC_IP_INPUT
        PUBLIC_IP=${PUBLIC_IP_INPUT:-$PUBLIC_IP}
    else
        read -p "Enter Worker Public IP: " PUBLIC_IP
    fi
    
    read -p "Enter Master Server IP: " MASTER_IP
    while [ -z "$MASTER_IP" ]; do
        echo "❌ Master Server IP cannot be empty!"
        read -p "Enter Master Server IP: " MASTER_IP
    done
    
    read -p "Enter Master Database Password [proxy_pass]: " DB_PASS
    DB_PASS=${DB_PASS:-proxy_pass}
    read -p "Enter Master Redis Password [proxy_redis_pass]: " REDIS_PASS
    REDIS_PASS=${REDIS_PASS:-proxy_redis_pass}
    
    read -p "Enter Admin Token (must match master): " ADMIN_TOKEN
    while [ -z "$ADMIN_TOKEN" ]; do
        echo "❌ Admin Token cannot be empty!"
        read -p "Enter Admin Token (must match master): " ADMIN_TOKEN
    done
    read -p "Enter number of Tor instances [20]: " TOR_INSTANCES
    TOR_INSTANCES=${TOR_INSTANCES:-20}
else
    # Use environment variables with defaults
    WORKER_ID=${WORKER_ID:-}
    WORKER_REGION=${WORKER_REGION:-}
    PUBLIC_IP=${PUBLIC_IP:-}
    MASTER_IP=${MASTER_IP:-}
    DB_PASS=${DB_PASS:-proxy_pass}
    REDIS_PASS=${REDIS_PASS:-proxy_redis_pass}
    ADMIN_TOKEN=${ADMIN_TOKEN:-}
    TOR_INSTANCES=${TOR_INSTANCES:-20}
    
    # Validate required variables
    if [ -z "$WORKER_ID" ] || [ -z "$WORKER_REGION" ] || [ -z "$MASTER_IP" ] || [ -z "$PUBLIC_IP" ] || [ -z "$ADMIN_TOKEN" ]; then
        echo "❌ Error: Required environment variables not set"
        echo ""
        echo "Please set these variables before running:"
        echo "  export WORKER_ID=\"worker-2\""
        echo "  export WORKER_REGION=\"sg\""
        echo "  export PUBLIC_IP=\"188.166.236.73\""
        echo "  export MASTER_IP=\"84.247.136.121\""
        echo "  export ADMIN_TOKEN=\"your-admin-token\""
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
echo "  Public IP: $PUBLIC_IP"
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

# Clone latest code from GitHub repository
echo ""
echo "Cloning latest ProxyRay code from GitHub..."
INSTALL_DIR="/opt/proxy-worker"

# Backup existing installation if exists
if [ -d "$INSTALL_DIR" ]; then
    BACKUP_DIR="/opt/proxy-worker.backup-$(date +%Y%m%d-%H%M%S)"
    echo "Backing up existing installation to $BACKUP_DIR"
    mv "$INSTALL_DIR" "$BACKUP_DIR"
fi

mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Clone from GitHub repository
echo "Cloning from: https://github.com/hamzah79/proxyray-proxy.git"

if command -v git &> /dev/null; then
    git clone https://github.com/hamzah79/proxyray-proxy.git .
else
    echo "Installing git..."
    apt-get update -qq 2>/dev/null || apk add --no-cache git 2>/dev/null
    apt-get install -y git 2>/dev/null || apk add --no-cache git
    git clone https://github.com/hamzah79/proxyray-proxy.git .
fi

echo "✅ Code cloned successfully"

# ── KEY FIX: Download prebuilt dist instead of npm run build ──
echo ""
echo "Downloading prebuilt dist (v1.0.2)..."
DIST_URL="https://github.com/hamzah79/proxyray-proxy/releases/download/v1.0.2/dist.tar.gz"
if curl -fsSL "$DIST_URL" -o /tmp/dist.tar.gz; then
    tar -xzf /tmp/dist.tar.gz -C "$INSTALL_DIR"
    rm /tmp/dist.tar.gz
    echo "✅ Prebuilt dist downloaded and extracted"
else
    echo "⚠️  Could not download prebuilt dist, will build from source (may fail if repo is mismatched)"
    echo "     Falling back to npm run build..."
fi

# Patch Dockerfile: use prebuilt dist instead of npm run build
echo ""
echo "Patching Dockerfile to use prebuilt dist..."
cat > Dockerfile << 'DOCKERFILE_EOF'
FROM node:20-alpine

RUN apk add --no-cache tor python3 make g++ postgresql16-client openssh-client

WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm install --omit=dev

COPY tsconfig.json ./
COPY dist ./dist
COPY .env.example ./

# Create frontend dist directory (will be overridden by volume mount)
RUN mkdir -p /app/frontend-v2/dist

# Ensure node user (uid 1000) owns the app directory
RUN chown -R node:node /app && mkdir -p /tmp/.tor-data && chown -R node:node /tmp/.tor-data

EXPOSE 8080 1080 9090

CMD ["npm", "start"]
DOCKERFILE_EOF

# Ensure .dockerignore doesn't exclude dist
if [ -f .dockerignore ]; then
    sed -i '/^dist$/d' .dockerignore
fi

echo "✅ Dockerfile patched"

# Patch usageTracker to skip writes in worker mode
echo ""
echo "Applying worker mode patches..."
cd "$INSTALL_DIR"
python3 << 'PATCH_EOF'
import os

# Patch usageTracker.ts
print("  📝 Patching usageTracker.ts...")
file_path = "src/billing/usageTracker.ts"
if os.path.exists(file_path):
    with open(file_path, 'r') as f:
        content = f.read()
    
    modified = False
    
    if "const SERVER_MODE" not in content:
        content = content.replace(
            "import { DatabaseClient } from '../db/client';",
            "import { DatabaseClient } from '../db/client';\n\n// Check if running in worker mode\nconst SERVER_MODE = process.env.SERVER_MODE || 'master';"
        )
        modified = True
    
    if "// Skip usage tracking in worker mode" not in content:
        pos = content.find("async recordUsage(record: Omit<UsageRecord")
        if pos != -1:
            brace = content.find("{", pos)
            content = content[:brace+1] + "\n    // Skip usage tracking in worker mode\n    if (SERVER_MODE === 'worker') {\n      return;\n    }\n" + content[brace+1:]
            modified = True
    
    if "// Skip flush in worker mode" not in content:
        pos = content.find("async flush(): Promise<void> {")
        if pos != -1:
            brace = content.find("{", pos)
            content = content[:brace+1] + "\n    // Skip flush in worker mode\n    if (SERVER_MODE === 'worker') {\n      return;\n    }\n" + content[brace+1:]
            modified = True
    
    if modified:
        with open(file_path, 'w') as f:
            f.write(content)
        print("    ✅ Patched usageTracker.ts")
    else:
        print("    ℹ️  usageTracker.ts already patched")
else:
    print("    ⚠️  usageTracker.ts not found")

print("  ✅ Worker mode patches applied")
PATCH_EOF

# Create .env file
echo ""
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
# Auto-generated by one-line installer v2.1.0
# Generated: $(date)
# ══════════════════════════════════════════════

SERVER_MODE=worker
SERVER_ID=$WORKER_ID
SERVER_REGION=$WORKER_REGION
PUBLIC_HOST=$PUBLIC_IP

MASTER_DATABASE_URL=postgres://proxy_app:$DB_PASS@$MASTER_IP:5432/proxy_db
MASTER_REDIS_URL=redis://:$REDIS_PASS@$MASTER_IP:6379

ADMIN_TOKEN=$ADMIN_TOKEN
REDIS_KEY_PREFIX=rotating-proxy
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

# Worker-specific
DISABLE_USAGE_TRACKING=true
ENABLE_METRICS=false
ENABLE_ANALYTICS=false
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
