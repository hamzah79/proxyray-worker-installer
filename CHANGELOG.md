# Worker Installer Changelog

## 2026-05-01 - Load Balancing Fix

### Perubahan:

1. **install-worker.sh**
   - Menambahkan konfigurasi `TRUSTED_PROXY_IPS` di .env
   - Format: `TRUSTED_PROXY_IPS=${MASTER_IP},127.0.0.1,::1`
   - Ini memungkinkan worker menerima koneksi dari master tanpa IP whitelist check
   - Menampilkan Trusted IPs di output konfigurasi

2. **file-worker.tar.gz**
   - Update `src/master/smartRouter.ts` dengan algoritma load balancing yang diperbaiki
   - Ketika load score sama (0/1 vs 0/10 = 0), sekarang memilih worker dengan lebih banyak Tor instances
   - Ini memastikan worker dengan kapasitas lebih besar (10 Tor instances) diprioritaskan dibanding master (1 Tor instance)

### Cara Update Worker yang Sudah Terinstall:

```bash
# SSH ke worker
ssh root@<worker-ip>

# Tambahkan TRUSTED_PROXY_IPS ke .env
cd /opt/proxy-worker
echo "TRUSTED_PROXY_IPS=<master-ip>,127.0.0.1,::1" >> .env

# Rebuild dan restart
docker compose down
docker compose up -d --build
```

### Testing:

Setelah update, verifikasi dengan:

```bash
# Di master, cek worker stats
curl -H "Authorization: Bearer <token>" http://localhost:9090/admin/api/workers/stats

# Cek routing assignments
curl -H "Authorization: Bearer <token>" http://localhost:9090/admin/api/routing/assignments

# Test koneksi via proxy
curl -x http://username:password@master-ip:8080 https://api.ipify.org
```

### Hasil yang Diharapkan:

- User baru akan di-route ke worker-1 (bukan master-1)
- Load balancing mendistribusikan user berdasarkan load score
- Worker dengan lebih banyak Tor instances mendapat prioritas lebih tinggi
- Tidak ada lagi error "Socket closed" atau "ip not whitelisted"
