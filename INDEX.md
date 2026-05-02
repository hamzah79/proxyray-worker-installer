# ProxyRay - Downloads

## Worker Installer

### Latest Version: 1.0.0 (2026-05-02)

**Main Installer Package:**
- 📦 [proxyray-worker-installer-v1.0.0.tar.gz](./proxyray-worker-installer-v1.0.0.tar.gz) (133 KB)
- 🔐 [SHA256 Checksum](./proxyray-worker-installer-v1.0.0.tar.gz.sha256)

**Documentation:**
- 🚀 [One-Line Install Guide](./ONE-LINE-INSTALL.md) ⭐ **RECOMMENDED**
- 📖 [Quick Start Guide](./QUICKSTART.md)
- 📘 [Installation README](./WORKER-INSTALL-README.md)
- 📝 [Changelog](./WORKER-CHANGELOG.md)
- 🏷️ [Version Info](./WORKER-VERSION.txt)

**Individual Files:**
- 🔧 [One-Line Installer Script](./install-worker-online.sh) ⭐ **NEW**
- 🔧 [Offline Installer Script](./install-worker.sh) (5.2 KB)
- 📦 [Worker Source Package](./proxy-worker-master.tar.gz) (128 KB)

---

## Installation

### 🚀 One-Line Install (Super Praktis!)

**Install dengan 1 command saja:**

```bash
# Menggunakan curl
curl -fsSL http://YOUR_DOMAIN/downloads/install-worker-online.sh | sudo bash
```

**ATAU**

```bash
# Menggunakan wget
wget -qO- http://YOUR_DOMAIN/downloads/install-worker-online.sh | sudo bash
```

✅ Tidak perlu download manual  
✅ Tidak perlu extract  
✅ Interactive configuration  
✅ Auto-install Docker  

📖 [One-Line Install Guide](./ONE-LINE-INSTALL.md)

---

### 📦 Offline Install (Jika server tidak ada internet)

```bash
# Download package lengkap
wget http://YOUR_DOMAIN/downloads/proxyray-worker-installer-v1.0.0.tar.gz

# Verify checksum (optional)
wget http://YOUR_DOMAIN/downloads/proxyray-worker-installer-v1.0.0.tar.gz.sha256
sha256sum -c proxyray-worker-installer-v1.0.0.tar.gz.sha256

# Extract
tar xzf proxyray-worker-installer-v1.0.0.tar.gz

# Run installer
sudo bash install-worker.sh
```

---

**Last Updated:** 2026-05-02
