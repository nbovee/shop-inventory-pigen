# Rowan Shop & Pantry Inventory System

Offline-first inventory management system for Raspberry Pi with captive WiFi portal, automated USB backups, and live update capabilities.

## Features

- **📡 WiFi Access Point** - Pi creates standalone network (`10.42.0.1`) for client connections
- **📦 Django Inventory App** - Full-featured inventory management via local network
- **💾 USB Backup** - Automated database backups to USB drives with `.shopbackup` marker
- **🔄 Live Updates** - Deploy code changes via SSH/mosh without image rebuild

## Quick Start

```bash
# Clone and initialize
git clone --recursive https://github.com/nbovee/shop-inventory-pigen.git
cd shop-inventory-pigen
bash init.sh

# Configure (edit the generated config file)
# Required: DJANGO_SECRET_KEY, WIFI_PASS, DJANGO_ADMIN_PASSWORD

# Build Raspberry Pi image
bash build.sh
# Output: deploy/rowanPantry-*.img

# Or run development server (VSCode: "Simple Debug")
# Access at http://127.0.0.1:8000
```

## Architecture

**Stack:** Django + Gunicorn + Nginx + NetworkManager + systemd
**Config:** `/etc/pantry/config` (FHS-compliant, centralized environment variables)
**Tools:** UV, Docker, WSL, pi-gen

[![Build](https://github.com/nbovee/shop-inventory/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/nbovee/shop-inventory/actions/workflows/ci.yml)
[![Coverage Status](https://coveralls.io/repos/github/nbovee/shop-inventory/badge.svg?branch=main)](https://coveralls.io/github/nbovee/shop-inventory?branch=main)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

## Deployment

### Flash Image to Pi
1. Build produces `deploy/rowanPantry-*.img`
2. Flash using [Raspberry Pi Imager](https://www.raspberrypi.com/software/)
3. Power on - WiFi hotspot starts automatically
4. Connect to network (SSID from config) and access `http://10.42.0.1`

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

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development guidelines.

## Acknowledgements

**Sponsored by:** [NJ Office of the Secretary of Higher Education](https://www.nj.gov/highereducation/)
**Partner:** [Rowan University's The Shop Pantry & Resource Center](https://sites.rowan.edu/theshop/)
**Student Team:** Erick Ayala-Ortiz, Cole Cheman, Brian Dalmar, Allison Garfield, Nik Leckie, Layane Neves, Juan Palacios, Emmy Sagapolutele, Solimar Soto, James Sunbury, Anne-Marie Zamor

## License

MIT License - see [LICENSE](LICENSE) file
