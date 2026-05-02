# ProxyRay Worker Installer

Official installer package for ProxyRay Worker nodes.

## 🚀 Quick Install (One-Line)

Install worker dengan 1 command:

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/proxyray-worker-installer/main/install-worker-online.sh | sudo bash
```

**ATAU**

```bash
wget -qO- https://raw.githubusercontent.com/YOUR_USERNAME/proxyray-worker-installer/main/install-worker-online.sh | sudo bash
```

## 📦 Offline Install

Untuk server tanpa internet:

```bash
# Download release
wget https://github.com/YOUR_USERNAME/proxyray-worker-installer/releases/download/v1.0.0/proxyray-worker-installer-v1.0.0.tar.gz

# Extract
tar xzf proxyray-worker-installer-v1.0.0.tar.gz

# Install
sudo bash install-worker.sh
```

## 📖 Documentation

- [One-Line Install Guide](./ONE-LINE-INSTALL.md) ⭐ **RECOMMENDED**
- [Full Installation Guide](./WORKER-INSTALL-README.md)
- [Quick Start Guide](./QUICKSTART.md)
- [Changelog](./WORKER-CHANGELOG.md)

## ✨ Features

- ✅ Multi-Tor instance support (1-50 instances)
- ✅ Auto-registration to master server
- ✅ Health monitoring and heartbeat
- ✅ Circuit breaker for stability
- ✅ Retry mechanism with exponential backoff
- ✅ HTTP and SOCKS5 proxy support
- ✅ Load balancing integration
- ✅ Docker-based deployment
- ✅ One-line installation

## 🔧 System Requirements

- **OS:** Ubuntu 20.04+, Debian 11+, or compatible Linux
- **CPU:** 2 cores minimum (4 cores recommended)
- **RAM:** 2GB minimum (4GB recommended)
- **Disk:** 10GB free space
- **Network:** Stable connection to master server

## 📋 What Gets Installed

1. Docker & Docker Compose (if not already installed)
2. ProxyRay Worker application
3. Tor instances (configurable count)
4. Auto-configuration and startup

## 🛠️ Configuration

During installation, you'll be asked:

- **Worker ID** - Unique identifier (e.g., worker-2)
- **Worker Region** - Geographic region (e.g., sg, us, eu)
- **Master Server IP** - Your master server IP address
- **Database Password** - Master PostgreSQL password
- **Redis Password** - Master Redis password
- **Tor Instances** - Number of Tor instances (default: 20)

## 📊 Monitoring

After installation, check worker status in admin panel:

```
http://MASTER_IP:9090/admin-ui
Menu: Workers
```

## 🔄 Update Worker

To update to a new version:

```bash
cd /opt/proxy-worker
docker compose down
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/proxyray-worker-installer/main/install-worker-online.sh | sudo bash
```

## 🐛 Troubleshooting

### Worker not showing in admin panel

```bash
# Check logs
cd /opt/proxy-worker
docker compose logs -f rotating-proxy

# Check connectivity to master
ping MASTER_IP
```

### Tor not bootstrapping

```bash
# Check Tor logs
docker logs rotating-proxy | grep -i tor

# Restart worker
docker compose restart rotating-proxy
```

## 📝 License

Proprietary - ProxyRay

## 🤝 Support

For support, contact your system administrator or check the admin panel.

---

**Version:** 1.0.0  
**Last Updated:** 2026-05-02
