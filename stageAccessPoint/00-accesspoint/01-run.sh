#!/bin/bash -e

. "${BASE_DIR}/config"

echo "Installing WiFi access point configuration files"
install -m 640 files/pantry-wifi-setup.service "${ROOTFS_DIR}/etc/systemd/system/"
install -m 640 files/dnsmasq.conf "${ROOTFS_DIR}/etc/dnsmasq.conf"

on_chroot << EOF
echo "Enabling WiFi hotspot and DNS services"
systemctl enable pantry-wifi-setup
systemctl enable dnsmasq
EOF
