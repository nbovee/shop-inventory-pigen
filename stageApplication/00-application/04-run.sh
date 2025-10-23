#!/bin/bash -e

. "${BASE_DIR}/config"

# Export certificate to DEPLOY_DIR for distribution (e.g., iPad installation)
# This runs OUTSIDE chroot, after all build operations are complete
# Similar to export-image/05-finalise/01-run.sh which copies files to DEPLOY_DIR

if [ "${ENABLE_SSL}" = "true" ]; then
  echo "Exporting SSL certificate to DEPLOY_DIR for distribution"
  mkdir -p "${DEPLOY_DIR}"

  if [ -f "${ROOTFS_DIR}/etc/nginx/ssl/${TARGET_HOSTNAME}.crt" ]; then
    cp "${ROOTFS_DIR}/etc/nginx/ssl/${TARGET_HOSTNAME}.crt" "${DEPLOY_DIR}/${TARGET_HOSTNAME}.crt"
    chmod 644 "${DEPLOY_DIR}/${TARGET_HOSTNAME}.crt"
    echo "Certificate exported to: ${DEPLOY_DIR}/${TARGET_HOSTNAME}.crt"
  else
    echo "WARNING: Certificate file not found at ${ROOTFS_DIR}/etc/nginx/ssl/${TARGET_HOSTNAME}.crt"
  fi
else
  echo "Skipping certificate export (ENABLE_SSL=false)"
fi
