# ProxyRay Worker - Master Installer

## Deskripsi
Master installer untuk ProxyRay Worker Node. File ini berisi konfigurasi dan source code worker yang sudah teruji dan siap deploy.

## Isi Package
- Source code aplikasi worker (TypeScript)
- Dockerfile dan docker-compose.yml
- Konfigurasi .env.example
- Database migrations
- Script deployment

## Cara Install

### 1. Persiapan Server
```bash
# Update system
apt update && apt upgrade -y

# Install Docker & Docker Compose
curl -fsSL https://get.docker.com | sh
apt install -y docker-compose-plugin

# Install Node.js (opsional, untuk build di server)
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs
```

### 2. Extract & Setup
```bash
# Extract file
mkdir -p /opt/proxy-worker
tar xzf proxy-worker-master.tar.gz -C /opt/
cd /opt/proxy-worker

# Copy dan edit konfigurasi
cp .env.example .env
nano .env
```

### 3. Konfigurasi .env
Edit file `.env` dan sesuaikan:

```bash
# ── Mode & Identitas Worker ──
SERVER_MODE=worker
WORKER_ID=worker-2  # Ganti dengan ID unik
WORKER_REGION=sg    # Sesuaikan region

# ── Koneksi ke Master ──
MASTER_DATABASE_URL=postgres://proxy_app:proxy_pass@MASTER_IP:5432/proxy_db
MASTER_REDIS_URL=redis://:proxy_redis_pass@MASTER_IP:6379

# ── Trusted Proxy IPs (IP Master) ──
TRUSTED_PROXY_IPS=MASTER_IP,127.0.0.1,::1

# ── Tor Configuration ──
TOR_INSTANCES=20
TOR_EXIT_NODES={us},{gb}
TOR_STRICT_NODES=false

# ── Port Configuration ──
HTTP_PROXY_PORT=8080
SOCKS_PROXY_PORT=1080
ADMIN_PORT=9090
```

**Ganti:**
- `MASTER_IP` dengan IP server master (contoh: 84.247.136.121)
- `WORKER_ID` dengan ID unik (contoh: worker-2, worker-3, dst)
- `WORKER_REGION` dengan region server (contoh: sg, us, eu)

### 4. Build & Deploy
```bash
# Build Docker image
docker compose build

# Start worker
docker compose up -d

# Cek log
docker compose logs -f rotating-proxy
```

### 5. Verifikasi
```bash
# Cek status container
docker compose ps

# Cek Tor bootstrap
docker logs rotating-proxy | grep "Bootstrapped 100"

# Cek worker registration di Redis (dari server master)
docker exec rotating-proxy-redis redis-cli -a proxy_redis_pass KEYS "*worker*"
```

## Troubleshooting

### Worker tidak terdaftar di master
```bash
# Cek koneksi ke master database
docker exec rotating-proxy node -e "const pg = require('pg'); const client = new pg.Client(process.env.MASTER_DATABASE_URL); client.connect().then(() => console.log('DB OK')).catch(e => console.error(e));"

# Cek koneksi ke master Redis
docker exec rotating-proxy-redis redis-cli -h MASTER_IP -a proxy_redis_pass PING
```

### Tor tidak bootstrap
```bash
# Cek log Tor
docker logs rotating-proxy | grep -i "tor\|bootstrap"

# Restart container
docker compose restart rotating-proxy
```

### Port sudah digunakan
```bash
# Cek port yang digunakan
ss -tuln | grep -E "8080|1080|9090"

# Ubah port di .env jika konflik
```

## Update Worker

### Update dari master installer baru
```bash
# Backup konfigurasi
cp /opt/proxy-worker/.env /opt/proxy-worker/.env.backup

# Stop worker
cd /opt/proxy-worker
docker compose down

# Backup folder lama
cd /opt
mv proxy-worker proxy-worker.backup-$(date +%Y%m%d-%H%M%S)

# Extract installer baru
tar xzf proxy-worker-master-new.tar.gz -C /opt/

# Restore konfigurasi
cp proxy-worker.backup-*/.env proxy-worker/.env

# Build & start
cd proxy-worker
docker compose build
docker compose up -d
```

## Monitoring

### Cek status worker dari admin panel
1. Login ke admin panel master: http://MASTER_IP:9090/admin-ui
2. Menu: Workers
3. Lihat status worker, Tor instances, dan traffic

### Cek log real-time
```bash
docker compose logs -f rotating-proxy
```

### Cek resource usage
```bash
docker stats rotating-proxy
```

## Spesifikasi Minimum Server

- **CPU:** 2 cores (4 cores recommended untuk 20 Tor instances)
- **RAM:** 2GB (4GB recommended)
- **Disk:** 10GB free space
- **Network:** 100Mbps+ bandwidth
- **OS:** Ubuntu 20.04+ atau Debian 11+

## Port yang Digunakan

- **8080:** HTTP Proxy
- **1080:** SOCKS5 Proxy
- **9090:** Admin API (internal)

## Security Notes

1. **Firewall:** Hanya buka port yang diperlukan
2. **TRUSTED_PROXY_IPS:** Hanya tambahkan IP master yang valid
3. **Database & Redis:** Gunakan password yang kuat
4. **Update:** Selalu gunakan installer terbaru dari master

## Support

Untuk bantuan lebih lanjut, hubungi tim DevOps atau cek dokumentasi lengkap di admin panel.

---

**Version:** 1.0.0  
**Last Updated:** 2026-05-02  
**Tested On:** Ubuntu 22.04, Debian 11
