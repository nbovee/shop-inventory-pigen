#!/bin/bash -e

. "${BASE_DIR}/config"

echo "Installing WiFi access point configuration files"
# Substitute AP network variables in pantry-wifi-setup.service
envsubst '$AP_GATEWAY_IP' < files/pantry-wifi-setup.service > "${ROOTFS_DIR}/etc/systemd/system/pantry-wifi-setup.service"
chmod 640 "${ROOTFS_DIR}/etc/systemd/system/pantry-wifi-setup.service"
# Substitute AP network variables in dnsmasq.conf
envsubst '$AP_GATEWAY_IP $AP_DHCP_START $AP_DHCP_END $AP_NETMASK' < files/dnsmasq.conf > "${ROOTFS_DIR}/etc/dnsmasq.conf"
chmod 640 "${ROOTFS_DIR}/etc/dnsmasq.conf"

on_chroot << EOF
echo "Enabling WiFi hotspot and DNS services"
systemctl enable pantry-wifi-setup
systemctl enable dnsmasq
EOF
