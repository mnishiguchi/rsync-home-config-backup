#!/bin/bash
# Backup installed Flatpak applications

set -e

# Constants
SCRIPT_DIR=$(dirname "$(realpath "$0")")
CONFIG_DIR="${SCRIPT_DIR}/config"
BACKUP_ROOT=$(<"${CONFIG_DIR}/backup-location.txt")
BACKUP_DIR="${BACKUP_ROOT}/flatpak-backups"
TIMESTAMP=$(date +%Y%m%d)
USER_NAME=$(whoami)
OUTPUT_FILE="${BACKUP_DIR}/flatpak-${USER_NAME}-${TIMESTAMP}.list"
LOG_FILE="${BACKUP_DIR}/backup-flatpak.log"

# Ensure the backup directory exists
mkdir -p "$BACKUP_DIR"

# Logging setup
exec > >(tee -a "$LOG_FILE") 2>&1

# Start backup
echo "========================================"
echo " Backup Flatpak Applications"
echo "========================================"
echo "Backup Directory: $BACKUP_DIR"

# Backup Flatpak installed applications
if command -v flatpak >/dev/null 2>&1; then
  echo "Backing up installed Flatpak applications..."
  flatpak list --app --columns=app >"$OUTPUT_FILE"
  echo "Flatpak applications list saved to: $OUTPUT_FILE"
else
  echo "Error: 'flatpak' command not found. Cannot backup applications."
  exit 1
fi

echo "Backup completed successfully!"
echo "Log file: $LOG_FILE"
