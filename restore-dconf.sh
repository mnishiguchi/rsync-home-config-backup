#!/bin/bash

# ==============================================================#
# Script: restore-dconf.sh
# Purpose:
#   Restore dconf settings from a specified backup snapshot.
#
# Usage:
#   ./restore-dconf.sh
#
# Requirements:
#   - `dconf` must be installed for loading configuration settings.
#   - `config/backup-location.txt` must specify the backup root directory.
#
# Features:
#   - Interactive confirmation prompts.
#   - Allows selecting a specific backup snapshot to restore.
# ==============================================================#

set -e  # Exit on errors

# Constants
SCRIPT_DIR=$(dirname "$(realpath "$0")")
CONFIG_DIR="${SCRIPT_DIR}/config"
BACKUP_ROOT=$(<"${CONFIG_DIR}/backup-location.txt")
LOG_FILE="${BACKUP_ROOT}/restore-dconf.log"

# Ensure backup root directory exists
if [[ ! -d "${BACKUP_ROOT}" ]]; then
  echo "Backup root directory not found: ${BACKUP_ROOT}" | tee -a "$LOG_FILE"
  exit 1
fi

# List available backups
echo "Available Backups:"
echo "------------------"
BACKUPS=$(ls -1 "${BACKUP_ROOT}" | grep -E '^dconf-backups-[0-9]{8}$' || true)
if [[ -z "$BACKUPS" ]]; then
  echo "No dconf backups found." | tee -a "$LOG_FILE"
  exit 1
fi

echo "$BACKUPS"

# Prompt user to select a backup
echo
read -rp "Enter the backup folder name (e.g., dconf-backups-20241228): " SELECTED_BACKUP
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
    exit 1
  }
  echo "Dconf settings restored successfully." | tee -a "$LOG_FILE"
else
  echo "No dconf settings file found in the backup." | tee -a "$LOG_FILE"
  exit 1
fi

echo "Restore completed successfully from: ${BACKUP_DIR}" | tee -a "$LOG_FILE"
