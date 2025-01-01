#!/bin/bash
# Backup dconf settings

set -e

# Constants
SCRIPT_DIR=$(dirname "$(realpath "$0")")
CONFIG_DIR="${SCRIPT_DIR}/config"
BACKUP_ROOT=$(<"${CONFIG_DIR}/backup-location.txt")
BACKUP_DIR="${BACKUP_ROOT}/dconf-backups"
TIMESTAMP=$(date +%Y%m%d)
USER_NAME=$(whoami)
OUTPUT_FILE="${BACKUP_DIR}/dconf-${USER_NAME}-${TIMESTAMP}.ini"
LOG_FILE="${BACKUP_DIR}/backup-dconf.log"

# Ensure the backup directory exists
mkdir -p "$BACKUP_DIR"

# Logging setup
exec > >(tee -a "$LOG_FILE") 2>&1

# Start backup
echo "========================================"
echo " Backup Dconf Settings"
echo "========================================"
echo "Backup Directory: $BACKUP_DIR"

# Backup dconf settings
if command -v dconf >/dev/null 2>&1; then
  echo "Backing up dconf settings..."
  dconf dump / >"$OUTPUT_FILE"
  echo "Dconf settings saved to: $OUTPUT_FILE"
else
  echo "Error: 'dconf' command not found. Cannot backup settings."
  exit 1
fi

echo "Backup completed successfully!"
echo "Log file: $LOG_FILE"
