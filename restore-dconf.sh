#!/bin/bash
# Restore dconf settings

set -e

# Constants
SCRIPT_DIR=$(dirname "$(realpath "$0")")
CONFIG_DIR="${SCRIPT_DIR}/config"
BACKUP_ROOT=$(<"${CONFIG_DIR}/backup-location.txt")
BACKUP_DIR="${BACKUP_ROOT}/dconf-backups"
LOG_FILE="${BACKUP_DIR}/restore-dconf.log"

# Ensure backup directory exists
if [[ ! -d "$BACKUP_DIR" ]]; then
  echo "Error: Backup directory not found: $BACKUP_DIR" | tee -a "$LOG_FILE"
  exit 1
fi

# List available backup files
echo "Available Dconf Backup Files:"
echo "-----------------------------"
BACKUP_FILES=$(ls -1 "${BACKUP_DIR}/dconf-*.ini" 2>/dev/null || true)
if [[ -z "$BACKUP_FILES" ]]; then
  echo "No dconf backup files found in $BACKUP_DIR." | tee -a "$LOG_FILE"
  exit 1
fi
echo "$BACKUP_FILES"

# Prompt user to select a backup file
echo
read -rp "Enter the backup file name (e.g., dconf-username-20250101.ini): " SELECTED_FILE
SELECTED_PATH="${BACKUP_DIR}/${SELECTED_FILE}"

# Validate selected file
if [[ ! -f "$SELECTED_PATH" ]]; then
  echo "Error: Backup file not found: $SELECTED_PATH" | tee -a "$LOG_FILE"
  exit 1
fi

# Confirmation prompt
echo "You are about to restore dconf settings from: $SELECTED_PATH"
read -rp "Do you want to proceed? (y/n): " CONFIRM
if [[ "$CONFIRM" != "y" ]]; then
  echo "Restore canceled." | tee -a "$LOG_FILE"
  exit 0
fi

# Restore dconf settings
if command -v dconf >/dev/null 2>&1; then
  echo "Restoring dconf settings from $SELECTED_PATH..." | tee -a "$LOG_FILE"
  dconf load / <"$SELECTED_PATH"
  echo "Dconf settings restored successfully from $SELECTED_PATH." | tee -a "$LOG_FILE"
else
  echo "Error: 'dconf' command not found. Cannot restore settings." | tee -a "$LOG_FILE"
  exit 1
fi
