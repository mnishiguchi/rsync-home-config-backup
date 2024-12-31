#!/bin/bash

# ==============================================================#
# Script: restore-packages.sh
# Purpose:
#   Restores lists of installed Debian and Flatpak packages
#   from a specified backup snapshot.
#
# Usage:
#   ./restore-packages.sh
#
# Requirements:
#   - The backup must have been created using backup-packages.sh.
#   - The `config/backup-location.txt` must specify the backup root directory.
#
# Features:
#   - Interactive confirmation prompts.
#   - Allows selecting a specific backup snapshot to restore.
# ==============================================================#

set -e # Exit on errors

# Constants
SCRIPT_DIR=$(dirname "$(realpath "$0")")
CONFIG_DIR="${SCRIPT_DIR}/config"
BACKUP_ROOT=$(<"${CONFIG_DIR}/backup-location.txt")
LOG_FILE="${BACKUP_ROOT}/restore-packages.log"

# Ensure backup root directory exists
if [[ ! -d "${BACKUP_ROOT}" ]]; then
  echo "Backup root directory not found: ${BACKUP_ROOT}" | tee -a "$LOG_FILE"
  exit 1
fi

# List available backups
echo "Available Backups:"
echo "------------------"
BACKUPS=$(ls -1 "${BACKUP_ROOT}" | grep -E '^package-backups-[0-9]{8}$' || true)
if [[ -z "$BACKUPS" ]]; then
  echo "No backups found." | tee -a "$LOG_FILE"
  exit 1
fi

echo "$BACKUPS"

# Prompt user to select a backup
echo
read -rp "Enter the backup folder name (e.g., package-backups-20241228): " SELECTED_BACKUP
BACKUP_DIR="${BACKUP_ROOT}/${SELECTED_BACKUP}"

if [[ ! -d "${BACKUP_DIR}" ]]; then
  echo "Backup not found: ${BACKUP_DIR}" | tee -a "$LOG_FILE"
  exit 1
fi

# Confirmation prompt
echo "You are about to restore from: ${BACKUP_DIR}"
read -rp "Do you want to proceed? (y/n): " CONFIRM
if [[ "$CONFIRM" != "y" ]]; then
  echo "Restore canceled." | tee -a "$LOG_FILE"
  exit 0
fi

# Restore Debian packages
if [[ -f "${BACKUP_DIR}/packages.list" ]]; then
  echo "Restoring Debian packages..." | tee -a "$LOG_FILE"
  sudo dpkg --set-selections <"${BACKUP_DIR}/packages.list" || {
    echo "Failed to restore Debian package selections." | tee -a "$LOG_FILE"
  }
  sudo apt-get dselect-upgrade -y || {
    echo "Failed to install Debian packages." | tee -a "$LOG_FILE"
  }
  echo "Debian packages restored." | tee -a "$LOG_FILE"
else
  echo "No Debian package list found in the backup." | tee -a "$LOG_FILE"
fi

# Restore Flatpak packages
if [[ -f "${BACKUP_DIR}/flatpak.list" ]]; then
  echo "Restoring Flatpak packages..." | tee -a "$LOG_FILE"
  while IFS= read -r package; do
    flatpak install -y flathub "$package" || {
      echo "Failed to install Flatpak package: $package" | tee -a "$LOG_FILE"
    }
  done <"${BACKUP_DIR}/flatpak.list"
  echo "Flatpak packages restored." | tee -a "$LOG_FILE"
else
  echo "No Flatpak package list found in the backup." | tee -a "$LOG_FILE"
fi

echo "Restore completed successfully from: ${BACKUP_DIR}" | tee -a "$LOG_FILE"
