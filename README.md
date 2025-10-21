# Rowan Shop & Pantry Inventory System

Offline-first inventory management system for Raspberry Pi with HTTPS, captive WiFi portal, automated USB backups, and live update capabilities.

## Features

- **🔒 HTTPS by Default** - Self-signed certificates for secure communication
- **📡 WiFi Access Point** - Pi creates standalone network (`10.42.0.1`) for client connections
- **🌐 Captive Portal Detection** - Seamless device connectivity without popup interruptions
- **📦 Django Inventory App** - Full-featured inventory management via local network
- **💾 USB Backup** - Automated database backups to USB drives with `.shopbackup` marker
- **🔄 Live Updates** - Deploy code changes via SSH/mosh without image rebuild
- **🛡️ Firewall Protection** - Isolated network with no internet passthrough

## Quick Start

```bash
# Clone and initialize
git clone --recursive https://github.com/nbovee/shop-inventory-pigen.git
cd shop-inventory-pigen
bash scripts/setup.sh

# Configure (copy and edit config.example)
cp config.example config
# Required: DJANGO_SECRET_KEY, WIFI_PASS, DJANGO_ADMIN_USERNAME, DJANGO_ADMIN_PASSWORD

# Build Raspberry Pi image
bash build.sh
# Output: deploy/pantry-base-*.img

# Or run development server (VSCode: "Simple Debug")
# Access at http://127.0.0.1:8000
```

## Architecture

**Stack:** Django + Gunicorn + Nginx (HTTPS) + NetworkManager + systemd
**Security:** Self-signed SSL certificates, secure cookies, firewall isolation
**Config:** `/etc/pantry/config` (FHS-compliant, centralized environment variables)
**Tools:** UV, Docker, WSL, pi-gen

### Network Architecture
- **HTTPS (443):** Main application access with SSL/TLS encryption
- **HTTP (80):** Captive portal detection only (redirects app traffic to HTTPS)
- **DNS:** dnsmasq for local DNS resolution
- **DHCP:** 10.42.0.2 - 10.42.0.254 range
- **Firewall:** iptables blocks internet passthrough, allows local network only

### Directory Structure
```
/var/www/pantry/              # Application root
  └── src/shop-inventory/     # Django application
      ├── _core/              # Authentication, settings, base views
      ├── inventory/          # Product management
      └── checkout/           # Cart and orders
/etc/pantry/config            # Runtime configuration
/etc/nginx/ssl/               # SSL certificates (auto-generated)
/var/log/pantry/              # Application logs
/run/pantry/                  # Unix socket for Gunicorn
```

[![Build](https://github.com/nbovee/shop-inventory/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/nbovee/shop-inventory/actions/workflows/ci.yml)
[![Coverage Status](https://coveralls.io/repos/github/nbovee/shop-inventory/badge.svg?branch=main)](https://coveralls.io/github/nbovee/shop-inventory?branch=main)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

## Deployment

### Flash Image to Pi
1. Build produces `deploy/pantry-base-*.img`
2. Flash using [Raspberry Pi Imager](https://www.raspberrypi.com/software/)
3. Power on - WiFi hotspot starts automatically
4. Connect to network (SSID from config)
5. Access `https://10.42.0.1` or `https://pantry`
6. **First visit:** Accept the self-signed certificate warning in your browser
   - Click "Advanced" → "Proceed to 10.42.0.1 (unsafe)"
   - This is expected behavior for self-signed certificates

### HTTPS Certificate Notes
- **Auto-generated:** 10-year self-signed certificate created during image build
- **Browser warning:** All devices will show certificate warning on first visit
- **Security:** Despite the warning, traffic is encrypted with TLS 1.2/1.3
- **CN/SAN:** Certificate includes `pantry`, `www.pantry`, `pantry.local`, and `10.42.0.1`
- **Regeneration:** Rebuild image to generate new certificate (expires 2035)
- **Certificate Export:** Certificate is automatically exported to `deploy/pantry.crt` (or your configured hostname) for installation on client devices

#### Installing Certificate on iPads/iOS Devices
To avoid certificate warnings on iPads, install the certificate profile:

1. **Transfer certificate to iPad:**
   - AirDrop the `deploy/pantry.crt` file to the iPad, OR
   - Email the `.crt` file as an attachment, OR
   - Host it on a web server and download via Safari

2. **Install the profile:**
   - Tap the `.crt` file when prompted
   - Go to **Settings > General > VPN & Device Management**
   - Tap the profile (e.g., "pantry") and tap **Install**
   - Enter device passcode if prompted
   - Tap **Install** again to confirm

3. **Enable full trust:**
   - Go to **Settings > General > About > Certificate Trust Settings**
   - Enable the toggle for your certificate (e.g., "pantry")
   - Tap **Continue** to confirm

After these steps, Safari and other apps will trust the HTTPS connection without warnings.

### USB Backups
Create `.shopbackup` file on USB drive root. Pi automatically backs up database to any connected drive with this marker file (scheduled via systemd timer).

## Live Updates

Update deployed Pi without rebuilding the full image:

```bash
./deploy_update.sh [HOSTNAME] [USERNAME]  # Defaults: 10.42.0.1, pantry user
```

**Features:**
- Syncs code via rsync over SSH/mosh
- Auto-detects dependency/config changes
- Creates local + remote backups before deploy
- Runs migrations and collects static files
- Health checks with automatic rollback on failure

**Setup:** Copy SSH key (`ssh-copy-id user@10.42.0.1`) or install `sshpass` for password auth

## Configuration Reference

The `config` file contains all build-time and runtime settings. Key variables:

### Build-Time (Baked into Image)
- `TARGET_HOSTNAME`: System hostname (default: `pantry`)
- `FIRST_USER_NAME`: Primary user account
- `APP_INSTALL_DIR`: Application installation directory
- `IMG_NAME`: Output image filename prefix

### Runtime (Modifiable After Build)
- `WIFI_SSID`: WiFi access point name
- `WIFI_PASS`: WiFi password
- `DJANGO_SECRET_KEY`: Django cryptographic key (required)
- `DJANGO_ADMIN_USERNAME`: Admin account username (auto-created on first boot)
- `DJANGO_ADMIN_PASSWORD`: Admin account password (auto-created on first boot)
- `DJANGO_SESSION_COOKIE_SECURE`: Set to `true` for HTTPS (default)
- `DJANGO_CSRF_COOKIE_SECURE`: Set to `true` for HTTPS (default)

**Note:** The admin user is automatically created when migrations run on first boot, using the credentials from `DJANGO_ADMIN_USERNAME` and `DJANGO_ADMIN_PASSWORD`.

To modify runtime settings after deployment, edit `/etc/pantry/config` on the Pi and restart services.

## Troubleshooting

### Build Issues
- **Docker permission denied:** Add user to docker group: `sudo usermod -aG docker $USER`
- **Submodule errors:** Ensure submodules initialized: `git submodule update --init --recursive`
- **Build fails midway:** Run `bash build.sh` again - it will continue from last checkpoint

### Deployment Issues
- **Can't connect to WiFi:** Check SSID/password in config, verify WiFi enabled on Pi
- **Certificate warnings:** Expected for self-signed certs - click "Advanced" and proceed
- **Application won't load:** SSH into Pi, check services: `systemctl status pantry nginx`
- **No internet on connected devices:** Intentional - firewall blocks passthrough for security

### SSH Access
Default credentials (change in config):
- **Username:** `rowan` (from `FIRST_USER_NAME`)
- **Password:** `pantry2025` (from `FIRST_USER_PASS`)
- **IP Address:** `10.42.0.1` (from `AP_GATEWAY_IP`)

```bash
ssh rowan@10.42.0.1
# View application logs
sudo journalctl -u pantry -f
# View nginx logs
sudo tail -f /var/log/pantry/nginx-error.log
# Restart services
sudo systemctl restart pantry nginx
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development guidelines.

## Acknowledgements

**Sponsored by:** [NJ Office of the Secretary of Higher Education](https://www.nj.gov/highereducation/)
**Partner:** [Rowan University's The Shop Pantry & Resource Center](https://sites.rowan.edu/theshop/)
**Student Team:** Erick Ayala-Ortiz, Cole Cheman, Brian Dalmar, Allison Garfield, Nik Leckie, Layane Neves, Juan Palacios, Emmy Sagapolutele, Solimar Soto, James Sunbury, Anne-Marie Zamor

## License

MIT License - see [LICENSE](LICENSE) file
