#!/bin/bash
# Backup installed Debian packages

set -e

# Constants
SCRIPT_DIR=$(dirname "$(realpath "$0")")
CONFIG_DIR="${SCRIPT_DIR}/config"
BACKUP_ROOT=$(<"${CONFIG_DIR}/backup-location.txt")
BACKUP_DIR="${BACKUP_ROOT}/dpkg-backups"
TIMESTAMP=$(date +%Y%m%d)
USER_NAME=$(whoami)
OUTPUT_FILE="${BACKUP_DIR}/dpkg-${USER_NAME}-${TIMESTAMP}.list"
LOG_FILE="${BACKUP_DIR}/backup-dpkg.log"

# Ensure the backup directory exists
mkdir -p "$BACKUP_DIR"

# Logging setup
exec > >(tee -a "$LOG_FILE") 2>&1

# Start backup
echo "========================================"
echo " Backup Debian Packages"
echo "========================================"
echo "Backup Directory: $BACKUP_DIR"

# Backup dpkg package selections
if command -v dpkg >/dev/null 2>&1; then
  echo "Backing up dpkg package selections..."
  dpkg --get-selections >"$OUTPUT_FILE"
  echo "Packages list saved to: $OUTPUT_FILE"
else
  echo "Error: 'dpkg' command not found. Cannot backup packages."
  exit 1
fi

echo "Backup completed successfully!"
echo "Log file: $LOG_FILE"
