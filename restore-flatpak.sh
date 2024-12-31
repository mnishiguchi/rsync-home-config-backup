#!/bin/bash
set -e

SCRIPT_DIR=$(dirname "$(realpath "$0")")
CONFIG_DIR="${SCRIPT_DIR}/config"
BACKUP_ROOT=$(<"${CONFIG_DIR}/backup-location.txt")
LOG_FILE="${BACKUP_ROOT}/restore-flatpak.log"

mkdir -p "$(dirname "$LOG_FILE")"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "Available Flatpak Backups:"
ls -1 "${BACKUP_ROOT}" | grep -E '^flatpak-backups-[0-9]{8}$' || {
  echo "No backups found."
  exit 1
}

read -rp "Enter the backup folder name: " SELECTED_BACKUP
BACKUP_DIR="${BACKUP_ROOT}/${SELECTED_BACKUP}"

if [[ ! -f "${BACKUP_DIR}/flatpak.list" ]]; then
  echo "Flatpak package list not found in ${BACKUP_DIR}."
  exit 1
fi

echo "Restoring Flatpak packages..."
while IFS= read -r package; do
  flatpak install -y flathub "$package"
done <"${BACKUP_DIR}/flatpak.list"
echo "Flatpak packages restored successfully."
