#!/bin/bash

# Script to mount USB drives and run django backup command
set -e

# Load configuration
APP_ENV_DIR=${APP_ENV_DIR:-/etc/pantry}  # Default if not set by systemd
source ${APP_ENV_DIR}/config

# Create base mount directory with proper permissions
MOUNT_BASE="${BACKUP_MOUNT_DIR:-/tmp/pantry-backup-mounts}"
if [ ! -d "$MOUNT_BASE" ]; then
    mkdir -p "$MOUNT_BASE"
    chmod 755 "$MOUNT_BASE"
fi

# Get list of all available USB partitions (not whole disks)
for device in $(lsblk -rno NAME,TRAN | grep "sd[a|b][0-9]" | cut -d' ' -f1); do
    # Get device path
    dev_path="/dev/$device"

    # Create mount point if it doesn't exist
    mount_point="$MOUNT_BASE/$device"
    if [ ! -d "$mount_point" ]; then
        mkdir -p "$mount_point"
    fi

    # Check if already mounted
    if ! grep -q "$dev_path" /proc/mounts; then
        # Try to mount the device
        if mount "$dev_path" "$mount_point"; then
            echo "Mounted $dev_path to $mount_point"
        else
            echo "Failed to mount $dev_path"
        fi
    else
        echo "$dev_path is already mounted at $mount_point"
    fi
done




# Run the Django backup command
cd "${APP_INSTALL_DIR}${APP_SUB_PATH}"

# Activate virtual environment
source "${APP_INSTALL_DIR}/venv/bin/activate"

# Run the backup command
python manage.py backup_db

exit 0
