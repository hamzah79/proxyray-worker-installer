# ProxyRay Worker - Changelog

## Version 1.0.0 (2026-05-02)

### Features
- ✅ Multi-Tor instance support (configurable, default 20)
- ✅ Auto-registration ke master server via Redis
- ✅ Health monitoring dan heartbeat
- ✅ Circuit breaker untuk backend stability
- ✅ Retry mechanism dengan exponential backoff
- ✅ IP whitelist bypass untuk trusted proxy (master server)
- ✅ Support HTTP dan SOCKS5 proxy
- ✅ Tor exit node configuration (US, GB)
- ✅ Load balancing integration dengan master

### Configuration
- Server mode: worker
- Database: Connect ke master PostgreSQL
- Redis: Connect ke master Redis untuk coordination
- Trusted proxy IPs: Skip IP whitelist untuk request dari master

### Bug Fixes
- Fixed: IP whitelist check untuk request dari master server
- Fixed: TypeScript compilation errors untuk trusted proxy check
- Fixed: SOCKS5 authentication dengan clientIp undefined

### Security
- IP whitelist bypass hanya untuk TRUSTED_PROXY_IPS
- Password hashing dengan salt
- Secure connection ke master database dan Redis

### Performance
- Configurable Tor instances (1-50)
- Circuit breaker untuk prevent cascade failures
- Retry dengan backoff untuk transient errors
- Connection pooling untuk database

### Deployment
- Docker Compose untuk easy deployment
- Auto-installer script dengan interactive configuration
- Health check dan auto-restart
- Volume mount untuk persistent Tor data

### Requirements
- Docker 20.10+
- Docker Compose Plugin
- Ubuntu 20.04+ atau Debian 11+
- 2GB RAM minimum (4GB recommended)
- 2 CPU cores minimum (4 cores recommended)
- Network connectivity ke master server

### Known Issues
- None

### Upgrade Notes
- First release, no upgrade path needed

---

For support and documentation, visit admin panel or contact DevOps team.
