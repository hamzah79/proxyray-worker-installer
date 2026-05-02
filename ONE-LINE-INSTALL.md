# ProxyRay Worker - One-Line Installation

## 🚀 Super Praktis - Install dengan 1 Command!

### Cara Install:

**Pilih salah satu:**

```bash
# Menggunakan curl
curl -fsSL http://YOUR_DOMAIN/downloads/install-worker-online.sh | sudo bash
```

**ATAU**

```bash
# Menggunakan wget
wget -qO- http://YOUR_DOMAIN/downloads/install-worker-online.sh | sudo bash
```

**Selesai!** Installer akan:
1. ✅ Auto-install Docker (jika belum ada)
2. ✅ Tanya konfigurasi (Worker ID, Region, Master IP, dll)
3. ✅ Download worker package otomatis
4. ✅ Setup dan build Docker image
5. ✅ Start worker
6. ✅ Verifikasi installation

---

## 📋 Yang Akan Ditanyakan:

Saat installer berjalan, Anda akan ditanya:

1. **Worker ID** - Contoh: `worker-2`, `worker-3`, `worker-sg-1`
2. **Worker Region** - Contoh: `sg`, `us`, `eu`, `id`
3. **Master Server IP** - IP server master Anda
4. **Database Password** - Password PostgreSQL master (default: `proxy_pass`)
5. **Redis Password** - Password Redis master (default: `proxy_redis_pass`)
6. **Tor Instances** - Jumlah Tor instances (default: `20`)

---

## 🎯 Contoh Penggunaan:

```bash
# Install worker
curl -fsSL http://84.247.136.121:9090/downloads/install-worker-online.sh | sudo bash

# Installer akan tanya:
# Enter Worker ID: worker-2
# Enter Worker Region: sg
# Enter Master Server IP: 84.247.136.121
# Enter Master Database Password [proxy_pass]: (tekan Enter)
# Enter Master Redis Password [proxy_redis_pass]: (tekan Enter)
# Enter number of Tor instances [20]: (tekan Enter)
# Continue? (y/n): y

# ... installer berjalan otomatis ...
# ✅ Installation Complete!
```

---

## ⚡ Keuntungan One-Line Installer:

✅ **Tidak perlu download manual** - Langsung dari internet  
✅ **Tidak perlu extract** - Otomatis  
✅ **Tidak perlu chmod** - Langsung executable  
✅ **Interactive** - Tanya konfigurasi saat install  
✅ **Auto-detect OS** - Support Ubuntu & Debian  
✅ **Auto-install Docker** - Jika belum ada  
✅ **Verifikasi otomatis** - Cek status setelah install  

---

## 🔄 Update Worker:

Untuk update worker ke versi baru:

```bash
# Stop worker lama
cd /opt/proxy-worker
docker compose down

# Backup konfigurasi
cp .env .env.backup

# Install versi baru (akan backup folder lama otomatis)
curl -fsSL http://YOUR_DOMAIN/downloads/install-worker-online.sh | sudo bash

# Restore konfigurasi jika perlu
# (atau input ulang saat installer tanya)
```

---

## 🛠️ Troubleshooting:

### Installer gagal download
```bash
# Cek koneksi internet
ping -c 3 google.com

# Cek URL download
curl -I http://YOUR_DOMAIN/downloads/proxy-worker-master.tar.gz
```

### Docker tidak terinstall
```bash
# Install manual
curl -fsSL https://get.docker.com | sudo sh
```

### Worker tidak muncul di admin panel
```bash
# Cek log
cd /opt/proxy-worker
docker compose logs -f rotating-proxy

# Cek koneksi ke master
ping MASTER_IP
```

---

## 📦 Alternatif: Offline Installer

Jika server tidak ada internet atau prefer offline install:

1. Download package lengkap:
   ```bash
   wget http://YOUR_DOMAIN/downloads/proxyray-worker-installer-v1.0.0.tar.gz
   ```

2. Extract dan install:
   ```bash
   tar xzf proxyray-worker-installer-v1.0.0.tar.gz
   sudo bash install-worker.sh
   ```

---

## 🔐 Security Notes:

- Script installer di-serve dari server master Anda
- Pastikan URL download menggunakan HTTPS (jika ada SSL)
- Verifikasi URL sebelum run: `curl -I http://YOUR_DOMAIN/downloads/install-worker-online.sh`
- Jangan run script dari sumber yang tidak dipercaya

---

## 📞 Support:

- Admin Panel: http://MASTER_IP:9090/admin-ui
- Full Documentation: Download `WORKER-INSTALL-README.md`
- Changelog: Download `WORKER-CHANGELOG.md`

---

**Version:** 1.0.0  
**Last Updated:** 2026-05-02  
**Installer Type:** One-Line Online Installer
