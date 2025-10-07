#!/bin/bash -e

. "${BASE_DIR}/config"

on_chroot << EOF
echo "Enable services to start on boot"
systemctl enable pantry
systemctl enable pantry-backup.timer
systemctl enable nginx

EOF
