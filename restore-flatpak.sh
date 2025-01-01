#!/bin/bash
# Restore installed Flatpak applications

set -e

# Constants
SCRIPT_DIR=$(dirname "$(realpath "$0")")
CONFIG_DIR="${SCRIPT_DIR}/config"
BACKUP_ROOT=$(<"${CONFIG_DIR}/backup-location.txt")
BACKUP_DIR="${BACKUP_ROOT}/flatpak-backups"
LOG_FILE="${BACKUP_DIR}/restore-flatpak.log"

# Ensure backup directory exists
if [[ ! -d "$BACKUP_DIR" ]]; then
  echo "Error: Backup directory not found: $BACKUP_DIR" | tee -a "$LOG_FILE"
  exit 1
fi

# List available backup files
echo "Available Flatpak Backup Files:"
echo "-------------------------------"
BACKUP_FILES=$(ls -1 "${BACKUP_DIR}/flatpak-*.list" 2>/dev/null || true)
if [[ -z "$BACKUP_FILES" ]]; then
  echo "No Flatpak backup files found in $BACKUP_DIR." | tee -a "$LOG_FILE"
  exit 1
fi
echo "$BACKUP_FILES"

# Prompt user to select a backup file
echo
read -rp "Enter the backup file name (e.g., flatpak-username-20250101.list): " SELECTED_FILE
SELECTED_PATH="${BACKUP_DIR}/${SELECTED_FILE}"

# Validate selected file
if [[ ! -f "$SELECTED_PATH" ]]; then
  echo "Error: Backup file not found: $SELECTED_PATH" | tee -a "$LOG_FILE"
  exit 1
fi

# Confirmation prompt
echo "You are about to restore Flatpak applications from: $SELECTED_PATH"
read -rp "Do you want to proceed? (y/n): " CONFIRM
if [[ "$CONFIRM" != "y" ]]; then
  echo "Restore canceled." | tee -a "$LOG_FILE"
  exit 0
fi

# Restore Flatpak applications
echo "Restoring Flatpak applications from $SELECTED_PATH..." | tee -a "$LOG_FILE"
while IFS= read -r package; do
  flatpak install -y flathub "$package" || {
    echo "Failed to install Flatpak package: $package" | tee -a "$LOG_FILE"
  }
done <"$SELECTED_PATH"
echo "Flatpak applications restored successfully from $SELECTED_PATH." | tee -a "$LOG_FILE"
