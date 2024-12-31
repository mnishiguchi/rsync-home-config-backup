#!/bin/bash

# ==============================================================#
# Script: restore-home.sh
# Purpose:
#   Restores the user's home directory from a specified backup snapshot.
#
# Usage:
#   ./restore-home.sh
#
# Requirements:
#   - The backup must have been created using backup-home.sh.
#   - The `config/backup-location.txt` must specify the backup root directory.
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
LOG_FILE="${BACKUP_ROOT}/restore-home.log"

# Ensure backup root directory exists
if [[ ! -d "${BACKUP_ROOT}" ]]; then
  echo "Backup root directory not found: ${BACKUP_ROOT}" | tee -a "$LOG_FILE"
  exit 1
fi

# List available backups
echo "Available Backups:"
echo "------------------"
BACKUPS=$(ls -1 "${BACKUP_ROOT}" | grep -E '^home-$(whoami)-[0-9]{8}$' || true)
if [[ -z "$BACKUPS" ]]; then
  echo "No backups found." | tee -a "$LOG_FILE"
  exit 1
fi

echo "$BACKUPS"

# Prompt user to select a backup
echo
read -rp "Enter the backup folder name (e.g., home-$(whoami)-20241228): " SELECTED_BACKUP
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
