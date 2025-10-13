#!/bin/bash
set -e

# Load configuration
APP_ENV_DIR=${APP_ENV_DIR:-/etc/pantry}  # Default if not set by systemd
source ${APP_ENV_DIR}/config

# Validate required variables
if [ -z "$WIFI_SSID" ] || [ -z "$WIFI_PASS" ]; then
    echo "ERROR: WIFI_SSID and WIFI_PASS must be set in config"
    exit 1
fi

echo "WiFi Hotspot Configuration:"
echo "  SSID: $WIFI_SSID"
echo "  Gateway IP: $AP_GATEWAY_IP"

# Wait for wlan0 to be available
echo "Waiting for wlan0 to be available..."
for i in {1..30}; do
    if nmcli dev status | grep -q "^wlan0"; then
        echo "wlan0 is available"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "ERROR: wlan0 not available after 30 seconds"
        exit 1
    fi
    sleep 1
done

# Create or activate hotspot
if ! nmcli c show "Hotspot" > /dev/null 2>&1; then
    echo "Creating new hotspot..."
    nmcli dev wifi hotspot ifname wlan0 ssid "$WIFI_SSID" password "$WIFI_PASS"
else
    echo "Activating existing hotspot..."
    nmcli c up "Hotspot"
fi

# Wait for IP to be assigned
sleep 3

# Verify IP is set
if ip addr show wlan0 | grep -q "$AP_GATEWAY_IP"; then
    echo "Hotspot ready with IP $AP_GATEWAY_IP"
else
    echo "WARNING: Expected IP $AP_GATEWAY_IP not found on wlan0"
    ip addr show wlan0
    exit 1
fi

exit 0
