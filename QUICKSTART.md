# ProxyRay Worker - Quick Start Guide

## Download & Extract

```bash
# Download installer (ganti URL dengan lokasi download Anda)
wget http://YOUR_DOMAIN/downloads/proxyray-worker-installer-v1.0.0.tar.gz

# Extract
tar xzf proxyray-worker-installer-v1.0.0.tar.gz
cd proxyray-worker-installer-v1.0.0
```

## Auto Install (Recommended)

```bash
# Run installer
sudo bash install-worker.sh
```

Installer akan:
1. Install Docker & Docker Compose (jika belum ada)
2. Tanya konfigurasi worker (ID, region, master IP, dll)
3. Extract dan setup worker
4. Build Docker image
5. Start worker
6. Verifikasi installation

## Manual Install

Jika prefer manual installation, lihat `WORKER-INSTALL-README.md` untuk langkah detail.

## Verify Installation

```bash
# Check worker status
docker compose ps

# Check logs
docker compose logs -f rotating-proxy

# Check Tor bootstrap
docker logs rotating-proxy | grep "Bootstrapped 100"
```

## Access Admin Panel

Setelah worker running, cek di master admin panel:
```
http://MASTER_IP:9090/admin-ui
Menu: Workers
```

Worker Anda akan muncul dengan status "online" dan jumlah Tor instances yang healthy.

## Troubleshooting

Jika worker tidak muncul di admin panel:

```bash
# Check connectivity to master
ping MASTER_IP

# Check Docker logs
docker compose logs rotating-proxy | grep -i error

# Restart worker
docker compose restart rotating-proxy
```

## Support

- Full documentation: `WORKER-INSTALL-README.md`
- Changelog: `WORKER-CHANGELOG.md`
- Version: `WORKER-VERSION.txt`

---

**Version:** 1.0.0  
**Release Date:** 2026-05-02
