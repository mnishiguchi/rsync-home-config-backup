#!/bin/bash
set -e

SCRIPT_DIR=$(dirname "$(realpath "$0")")
CONFIG_DIR="${SCRIPT_DIR}/config"
BACKUP_ROOT=$(<"${CONFIG_DIR}/backup-location.txt")
LOG_FILE="${BACKUP_ROOT}/restore-dpkg.log"

mkdir -p "$(dirname "$LOG_FILE")"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "Available DPKG Backups:"
ls -1 "${BACKUP_ROOT}" | grep -E '^dpkg-backups-[0-9]{8}$' || { echo "No backups found."; exit 1; }

read -rp "Enter the backup folder name: " SELECTED_BACKUP
BACKUP_DIR="${BACKUP_ROOT}/${SELECTED_BACKUP}"

if [[ ! -f "${BACKUP_DIR}/packages.list" ]]; then
  echo "Debian package list not found in ${BACKUP_DIR}."
  exit 1
fi

echo "Restoring Debian packages..."
sudo dpkg --set-selections <"${BACKUP_DIR}/packages.list"
sudo apt-get dselect-upgrade -y
echo "Debian packages restored successfully."
