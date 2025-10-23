#!/bin/bash -e

. "${BASE_DIR}/config"

# Export variables for envsubst
export APP_USER APP_GROUP APP_INSTALL_DIR APP_SUB_PATH APP_ENV_DIR
export TARGET_HOSTNAME APP_LOG_DIR APP_RUN_DIR
export AP_GATEWAY_IP AP_DHCP_START AP_DHCP_END AP_NETMASK
export DJANGO_SQLITE_DIR DJANGO_STATIC_ROOT DJANGO_MEDIA_ROOT

on_chroot << EOF
echo " adding user:"${APP_USER}" to group:"${APP_GROUP}""
usermod -aG "${APP_GROUP}" "${APP_USER}"
echo "add user:root to the group:"${APP_GROUP}""
usermod -aG ${APP_GROUP} root

echo "Configure hostname"
echo "${TARGET_HOSTNAME}" > /etc/hostname
sed -i "s/127.0.1.1.*/127.0.1.1\t${TARGET_HOSTNAME}.local/" /etc/hosts
# Add entries for the domain that clients will use
echo "${AP_GATEWAY_IP}\tpantry.local" >> /etc/hosts
echo "127.0.0.1\tpantry.local" >> /etc/hosts

echo "Create required directories"
mkdir -p "${APP_INSTALL_DIR}"
mkdir -p "${APP_INSTALL_DIR}${APP_SUB_PATH}/${DJANGO_SQLITE_DIR}"
mkdir -p "${APP_INSTALL_DIR}${APP_SUB_PATH}/${DJANGO_STATIC_ROOT}"
mkdir -p "${APP_INSTALL_DIR}${APP_SUB_PATH}/${DJANGO_MEDIA_ROOT}"
mkdir -p "${APP_ENV_DIR}"
mkdir -p "${APP_LOG_DIR}"
mkdir -p "${APP_RUN_DIR}"
mkdir -p "/etc/nginx/ssl"

if [ "${ENABLE_SSL}" = "true" ]; then
  echo "Generating self-signed SSL certificate..."
  openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
    -keyout "/etc/nginx/ssl/${TARGET_HOSTNAME}.key" \
    -out "/etc/nginx/ssl/${TARGET_HOSTNAME}.crt" \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=${TARGET_HOSTNAME}" \
    -addext "subjectAltName=DNS:${TARGET_HOSTNAME},DNS:www.${TARGET_HOSTNAME},DNS:${TARGET_HOSTNAME}.local,IP:${AP_GATEWAY_IP}"

  chmod 600 "/etc/nginx/ssl/${TARGET_HOSTNAME}.key"
  chmod 644 "/etc/nginx/ssl/${TARGET_HOSTNAME}.crt"
else
  echo "Skipping SSL certificate generation (ENABLE_SSL=false)"
fi
EOF

echo "Copy project files from the files directory"
# /pi-gen/work/rowanPantry/rootfs/
cp -r shop-inventory/* "${ROOTFS_DIR}${APP_INSTALL_DIR}"
install -m 640 shop-inventory/requirements.txt "${ROOTFS_DIR}${APP_INSTALL_DIR}"
echo "Copying systemd service & configuration files"
# Substitute APP_* variables in pantry.service
envsubst '$APP_USER $APP_GROUP $APP_INSTALL_DIR $APP_SUB_PATH $APP_ENV_DIR' < files/pantry.service > "${ROOTFS_DIR}/etc/systemd/system/pantry.service"
chmod 640 "${ROOTFS_DIR}/etc/systemd/system/pantry.service"
# Substitute variables in nginx config (use SSL or HTTP-only version based on ENABLE_SSL)
if [ "${ENABLE_SSL}" = "true" ]; then
  echo "Using HTTPS nginx configuration (ENABLE_SSL=true)"
  envsubst '$TARGET_HOSTNAME $APP_LOG_DIR $APP_INSTALL_DIR $APP_SUB_PATH $APP_RUN_DIR $DJANGO_STATIC_ROOT' < files/nginx-pantry-https.conf > "${ROOTFS_DIR}/etc/nginx/sites-available/nginx-pantry.conf"
else
  echo "Using HTTP-only nginx configuration (ENABLE_SSL=false)"
  envsubst '$TARGET_HOSTNAME $APP_LOG_DIR $APP_INSTALL_DIR $APP_SUB_PATH $APP_RUN_DIR $DJANGO_STATIC_ROOT' < files/nginx-pantry-http.conf > "${ROOTFS_DIR}/etc/nginx/sites-available/nginx-pantry.conf"
fi
chmod 640 "${ROOTFS_DIR}/etc/nginx/sites-available/nginx-pantry.conf"
# Substitute variables in pantry-backup.service
envsubst '$APP_ENV_DIR' < files/pantry-backup.service > "${ROOTFS_DIR}/etc/systemd/system/pantry-backup.service"
chmod 640 "${ROOTFS_DIR}/etc/systemd/system/pantry-backup.service"
install -m 640 files/pantry-backup.timer "${ROOTFS_DIR}/etc/systemd/system/"
# Substitute variables in tmpfiles.d configs
envsubst '$APP_RUN_DIR $APP_USER $APP_GROUP' < files/pantry-socket.conf > "${ROOTFS_DIR}/usr/lib/tmpfiles.d/pantry-socket.conf"
chmod 640 "${ROOTFS_DIR}/usr/lib/tmpfiles.d/pantry-socket.conf"
envsubst '$APP_LOG_DIR $APP_USER $APP_GROUP' < files/pantry-logs.conf > "${ROOTFS_DIR}/usr/lib/tmpfiles.d/pantry-logs.conf"
chmod 640 "${ROOTFS_DIR}/usr/lib/tmpfiles.d/pantry-logs.conf"
install -m 755 files/pantry-backup.sh "${ROOTFS_DIR}/usr/local/bin/"

echo "Copying config file"
install -m 640 "${BASE_DIR}/config" "${ROOTFS_DIR}${APP_ENV_DIR}/config"

on_chroot << EOF
chown -R root:${APP_GROUP} "${APP_ENV_DIR}"

echo "Set up Python virtual environment"
python3 -m venv "${APP_INSTALL_DIR}/venv"
"${APP_INSTALL_DIR}/venv/bin/pip" install --upgrade pip
"${APP_INSTALL_DIR}/venv/bin/pip" install -r "${APP_INSTALL_DIR}/requirements.txt"

echo "Set up permissions"
chown -R ${APP_USER}:${APP_GROUP} "${APP_INSTALL_DIR}"
chown -R ${APP_USER}:${APP_GROUP} "${APP_LOG_DIR}"
chown -R ${APP_USER}:${APP_GROUP} "${APP_RUN_DIR}"
chmod +x "${APP_INSTALL_DIR}${APP_SUB_PATH}/start.sh"
chmod +x "${APP_INSTALL_DIR}${APP_SUB_PATH}/manage.py"
# Ensure Django runtime directories are writable
chmod 775 "${APP_INSTALL_DIR}${APP_SUB_PATH}/${DJANGO_SQLITE_DIR}"
chmod 775 "${APP_INSTALL_DIR}${APP_SUB_PATH}/${DJANGO_STATIC_ROOT}"
chmod 775 "${APP_INSTALL_DIR}${APP_SUB_PATH}/${DJANGO_MEDIA_ROOT}"

echo "Configure nginx"
ln -sf /etc/nginx/sites-available/nginx-pantry.conf /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

echo "Checking for and removing existing test database file if present"
if [ -f "${APP_INSTALL_DIR}${APP_SUB_PATH}/${DJANGO_SQLITE_DIR}/testdb.sqlite3" ]; then
    echo "Removing existing database file"
    rm -f "${APP_INSTALL_DIR}${APP_SUB_PATH}/${DJANGO_SQLITE_DIR}/testdb.sqlite3"
fi

EOF
