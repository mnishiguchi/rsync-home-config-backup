#!/bin/bash
set -e

SCRIPT_DIR=$(dirname "$(realpath "$0")")
CONFIG_DIR="${SCRIPT_DIR}/config"
BACKUP_ROOT=$(<"${CONFIG_DIR}/backup-location.txt")
TIMESTAMP=$(date +%Y%m%d)
BACKUP_DIR="${BACKUP_ROOT}/dpkg-backups-${TIMESTAMP}"
LOG_FILE="${BACKUP_DIR}/backup-dpkg.log"

mkdir -p "$BACKUP_DIR"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "Backing up Debian packages..."
dpkg --get-selections >"${BACKUP_DIR}/packages.list"
echo "Debian packages saved to: ${BACKUP_DIR}/packages.list"
