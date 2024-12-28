#!/bin/bash

# ==============================================================#
# Script: restore.sh
# Purpose:
#   Restores the user's home directory and configurations
#   from a specified backup snapshot.
#
# Usage:
#   ./restore.sh
#
# Requirements:
#   - The backup must have been created using backup.sh.
#   - The `config/backup-location.txt` must specify the backup root directory.
#
# Features:
#   - Interactive confirmation prompts.
#   - Supports restoring dconf settings, package lists, and home directory.
#   - Allows selecting a specific backup snapshot to restore.
# ==============================================================#

set -e  # Exit on errors

# Constants
SCRIPT_DIR=$(dirname "$(realpath "$0")")
CONFIG_DIR="${SCRIPT_DIR}/config"
BACKUP_ROOT=$(<"${CONFIG_DIR}/backup-location.txt")
LOG_FILE="${BACKUP_ROOT}/restore.log"

# Ensure backup root directory exists
if [[ ! -d "${BACKUP_ROOT}" ]]; then
  echo "Backup root directory not found: ${BACKUP_ROOT}" | tee -a "$LOG_FILE"
  exit 1
fi

# List available backups
echo "Available Backups:"
echo "------------------"
BACKUPS=$(ls -1 "${BACKUP_ROOT}" | grep -E '^backup-home-config-[0-9]{8}$' || true)
if [[ -z "$BACKUPS" ]]; then
  echo "No backups found." | tee -a "$LOG_FILE"
  exit 1
fi

echo "$BACKUPS"

# Prompt user to select a backup
echo
read -rp "Enter the backup folder name (e.g., backup-home-config-20241228): " SELECTED_BACKUP
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

# Restore dconf settings
if [[ -f "${BACKUP_DIR}/dconf-settings.ini" ]]; then
  echo "Restoring dconf settings..." | tee -a "$LOG_FILE"
  dconf load / <"${BACKUP_DIR}/dconf-settings.ini" || {
    echo "Failed to restore dconf settings." | tee -a "$LOG_FILE"
  }
  echo "dconf settings restored." | tee -a "$LOG_FILE"
else
  echo "No dconf settings found in the backup." | tee -a "$LOG_FILE"
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

# Restore home directory
echo "Restoring home directory..." | tee -a "$LOG_FILE"
read -rp "This will overwrite existing files in your home directory. Continue? (y/n): " FINAL_CONFIRM
if [[ "$FINAL_CONFIRM" != "y" ]]; then
  echo "Home directory restore canceled." | tee -a "$LOG_FILE"
  exit 0
fi

rsync -avhPAX "${BACKUP_DIR}/home/" "${HOME}/" || {
  echo "Failed to restore home directory." | tee -a "$LOG_FILE"
  exit 1
}

echo "Home directory restored successfully." | tee -a "$LOG_FILE"

echo
echo "Restore completed successfully from: ${BACKUP_DIR}" | tee -a "$LOG_FILE"
