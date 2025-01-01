#!/bin/bash
# Restore installed Debian packages

set -e

# Constants
SCRIPT_DIR=$(dirname "$(realpath "$0")")
CONFIG_DIR="${SCRIPT_DIR}/config"
BACKUP_ROOT=$(<"${CONFIG_DIR}/backup-location.txt")
BACKUP_DIR="${BACKUP_ROOT}/dpkg-backups"
LOG_FILE="${BACKUP_DIR}/restore-dpkg.log"

# Ensure backup directory exists
if [[ ! -d "$BACKUP_DIR" ]]; then
  echo "Error: Backup directory not found: $BACKUP_DIR" | tee -a "$LOG_FILE"
  exit 1
fi

# List available backup files
echo "Available DPKG Backup Files:"
echo "----------------------------"
BACKUP_FILES=$(ls -1 "${BACKUP_DIR}/dpkg-*.list" 2>/dev/null || true)
if [[ -z "$BACKUP_FILES" ]]; then
  echo "No DPKG backup files found in $BACKUP_DIR." | tee -a "$LOG_FILE"
  exit 1
fi
echo "$BACKUP_FILES"

# Prompt user to select a backup file
echo
read -rp "Enter the backup file name (e.g., dpkg-username-20250101.list): " SELECTED_FILE
SELECTED_PATH="${BACKUP_DIR}/${SELECTED_FILE}"

# Validate selected file
if [[ ! -f "$SELECTED_PATH" ]]; then
  echo "Error: Backup file not found: $SELECTED_PATH" | tee -a "$LOG_FILE"
  exit 1
fi

# Confirmation prompt
echo "You are about to restore packages from: $SELECTED_PATH"
read -rp "Do you want to proceed? (y/n): " CONFIRM
if [[ "$CONFIRM" != "y" ]]; then
  echo "Restore canceled." | tee -a "$LOG_FILE"
  exit 0
fi

# Restore packages
echo "Restoring Debian packages from $SELECTED_PATH..." | tee -a "$LOG_FILE"
sudo dpkg --set-selections <"$SELECTED_PATH"
sudo apt-get dselect-upgrade -y
echo "Debian packages restored successfully from $SELECTED_PATH." | tee -a "$LOG_FILE"
