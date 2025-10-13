#!/bin/bash -e

. "${BASE_DIR}/config"

# Export variables for envsubst
export APP_ENV_DIR
export AP_GATEWAY_IP AP_DHCP_START AP_DHCP_END AP_NETMASK

echo "Installing WiFi access point configuration files"
# Substitute variables in pantry-wifi-setup.sh
envsubst '$APP_ENV_DIR' < files/pantry-wifi-setup.sh > "${ROOTFS_DIR}/usr/local/bin/pantry-wifi-setup.sh"
chmod 755 "${ROOTFS_DIR}/usr/local/bin/pantry-wifi-setup.sh"
# Substitute AP network variables in pantry-wifi-setup.service
envsubst '$APP_ENV_DIR' < files/pantry-wifi-setup.service > "${ROOTFS_DIR}/etc/systemd/system/pantry-wifi-setup.service"
chmod 640 "${ROOTFS_DIR}/etc/systemd/system/pantry-wifi-setup.service"
# Substitute AP network variables in dnsmasq.conf
envsubst '$AP_GATEWAY_IP $AP_DHCP_START $AP_DHCP_END $AP_NETMASK' < files/dnsmasq.conf > "${ROOTFS_DIR}/etc/dnsmasq.conf"
chmod 640 "${ROOTFS_DIR}/etc/dnsmasq.conf"

on_chroot << EOF
echo "Enabling WiFi hotspot and DNS services"
systemctl enable pantry-wifi-setup
systemctl enable dnsmasq
EOF
