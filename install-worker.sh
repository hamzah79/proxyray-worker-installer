#!/bin/bash
#
# ProxyRay Worker - Auto Installer
# Version: 1.0.2
# 
# Usage: ./install-worker.sh
#

set -e

echo "========================================="
echo "  ProxyRay Worker - Auto Installer"
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
    echo "Docker installed successfully"
else
    echo "Docker already installed: $(docker --version)"
fi

# Install Docker Compose Plugin if not installed
if ! docker compose version &> /dev/null; then
    echo "Installing Docker Compose Plugin..."
    apt-get update
    apt-get install -y docker-compose-plugin
    echo "Docker Compose installed successfully"
else
    echo "Docker Compose already installed: $(docker compose version)"
fi

echo ""
echo "========================================="
echo "  Worker Configuration"
echo "========================================="
echo ""

# Ask for configuration
read -p "Enter Worker ID (e.g., worker-2): " WORKER_ID
read -p "Enter Worker Region (e.g., sg, us, eu): " WORKER_REGION
read -p "Enter Worker Public IP (this server's public IP): " PUBLIC_IP
read -p "Enter Master Server IP: " MASTER_IP
read -p "Enter Master Database Password [proxy_pass]: " DB_PASS
DB_PASS=${DB_PASS:-proxy_pass}
read -p "Enter Master Redis Password [proxy_redis_pass]: " REDIS_PASS
REDIS_PASS=${REDIS_PASS:-proxy_redis_pass}
read -p "Enter Admin Token (must match master): " ADMIN_TOKEN
read -p "Enter number of Tor instances [20]: " TOR_INSTANCES
TOR_INSTANCES=${TOR_INSTANCES:-20}

echo ""
echo "Configuration:"
echo "  Worker ID: $WORKER_ID"
echo "  Region: $WORKER_REGION"
echo "  Public IP: $PUBLIC_IP"
echo "  Master IP: $MASTER_IP"
echo "  Tor Instances: $TOR_INSTANCES"
echo ""
read -p "Continue with this configuration? (y/n): " CONFIRM

if [ "$CONFIRM" != "y" ]; then
    echo "Installation cancelled"
    exit 0
fi

# Extract worker files
echo ""
echo "Extracting worker files..."
INSTALL_DIR="/opt/proxy-worker"

# Backup existing installation if exists
if [ -d "$INSTALL_DIR" ]; then
    BACKUP_DIR="/opt/proxy-worker.backup-$(date +%Y%m%d-%H%M%S)"
    echo "Backing up existing installation to $BACKUP_DIR"
    mv "$INSTALL_DIR" "$BACKUP_DIR"
fi

mkdir -p "$INSTALL_DIR"
tar xzf proxy-worker-master.tar.gz -C /opt/

cd "$INSTALL_DIR"

# Patch source code to skip database writes in worker mode
echo ""
echo "Applying worker mode patches..."
python3 << 'PATCH_EOF'
import os
import re

# Patch 1: usageTracker.ts
print("  📝 Patching usageTracker.ts...")
file_path = "src/billing/usageTracker.ts"
if os.path.exists(file_path):
    with open(file_path, 'r') as f:
        content = f.read()
    
    modified = False
    
    # Add SERVER_MODE constant
    if "const SERVER_MODE" not in content:
        content = content.replace(
            "import { DatabaseClient } from '../db/client';",
            "import { DatabaseClient } from '../db/client';\n\n// Check if running in worker mode\nconst SERVER_MODE = process.env.SERVER_MODE || 'master';"
        )
        modified = True
    
    # Patch recordUsage
    if "// Skip usage tracking in worker mode" not in content:
        pos = content.find("async recordUsage(record: Omit<UsageRecord")
        if pos != -1:
            brace = content.find("{", pos)
            content = content[:brace+1] + "\n    // Skip usage tracking in worker mode\n    if (SERVER_MODE === 'worker') {\n      return;\n    }\n" + content[brace+1:]
            modified = True
    
    # Patch flush
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

# Patch 2: index.ts
print("  📝 Patching index.ts...")
file_path = "src/index.ts"
if os.path.exists(file_path):
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Patch traffic sample persistence
    if "// Skip traffic sample persistence in worker mode" not in content:
        pattern = r'if \(!usersRepo \|\| !usagePeriodsRepo\) \{\s+return;\s+\}'
        replacement = '''if (!usersRepo || !usagePeriodsRepo) {
      return;
    }

    // Skip traffic sample persistence in worker mode
    if (process.env.SERVER_MODE === 'worker') {
      return;
    }'''
        content = re.sub(pattern, replacement, content)
        
        with open(file_path, 'w') as f:
            f.write(content)
        print("    ✅ Patched index.ts")
    else:
        print("    ℹ️  index.ts already patched")
else:
    print("    ⚠️  index.ts not found")

print("  ✅ Worker mode patches applied")
PATCH_EOF

# Create .env file
echo ""
echo "Creating .env configuration..."

# Backup existing .env if exists
if [ -f .env ]; then
    BACKUP_ENV=".env.backup-$(date +%Y%m%d-%H%M%S)"
    echo "Backing up existing .env to $BACKUP_ENV"
    cp .env "$BACKUP_ENV"
fi

cat > .env << EOF
# ══════════════════════════════════════════════
# ProxyRay Worker Configuration
# Auto-generated by installer v1.0.2
# Generated: $(date)
# ══════════════════════════════════════════════

# ── Wajib: Mode & Identitas Worker ──
SERVER_MODE=worker
SERVER_ID=$WORKER_ID
SERVER_REGION=$WORKER_REGION
PUBLIC_HOST=$PUBLIC_IP

# ── Wajib: Koneksi ke Master ──
MASTER_DATABASE_URL=postgres://proxy_app:$DB_PASS@$MASTER_IP:5432/proxy_db
MASTER_REDIS_URL=redis://:$REDIS_PASS@$MASTER_IP:6379

# ── Wajib: Harus sama dengan Master ──
ADMIN_TOKEN=$ADMIN_TOKEN
REDIS_KEY_PREFIX=rotating-proxy
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
SESSION_SECRET=your-super-secret-session-key-change-this-in-production

# ── Wajib: Trusted Proxy IPs (IP Master yang boleh connect) ──
TRUSTED_PROXY_IPS=$MASTER_IP,127.0.0.1,::1

# ── Tor Configuration ──
TOR_INSTANCES=$TOR_INSTANCES
TOR_EXIT_NODES={us},{gb}
TOR_STRICT_NODES=false
TOR_NEW_CIRCUIT_PERIOD_SECONDS=600

# ── Port Configuration ──
HTTP_PROXY_PORT=8080
SOCKS_PROXY_PORT=1080
ADMIN_PORT=9090

# ── Retry & Circuit Breaker ──
RETRY_MAX_ATTEMPTS=3
RETRY_INITIAL_DELAY_MS=1000
RETRY_MAX_DELAY_MS=10000
RETRY_BACKOFF_MULTIPLIER=2

CIRCUIT_BREAKER_FAILURE_THRESHOLD=10
CIRCUIT_BREAKER_SUCCESS_THRESHOLD=3
CIRCUIT_BREAKER_TIME_WINDOW_MS=60000
CIRCUIT_BREAKER_OPEN_TIMEOUT_MS=30000
CIRCUIT_BREAKER_MINIMUM_REQUESTS=10

# ── Logging & Migration ──
LOG_LEVEL=info
AUTO_MIGRATE=false

# ── Worker-specific: Disable write operations ──
DISABLE_USAGE_TRACKING=true
ENABLE_METRICS=false
ENABLE_ANALYTICS=false
EOF

echo ".env file created"

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
echo "  Installation Complete!"
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
echo "Useful commands:"
echo "  - View logs: docker compose logs -f rotating-proxy"
echo "  - Restart: docker compose restart rotating-proxy"
echo "  - Stop: docker compose down"
echo "  - Status: docker compose ps"
echo ""
echo "Worker should now be visible in master admin panel:"
echo "  http://$MASTER_IP:9090/admin-ui"
echo ""
echo "Installation directory: $INSTALL_DIR"
echo ""
