#!/bin/bash

# ==============================================================#
# Script: backup-dconf.sh
# Purpose:
#   Backup dconf settings to a specified directory.
#
# Usage:
#   ./backup-dconf.sh
#
# Requirements:
#   - `dconf` must be installed for dumping configuration settings.
#   - `config/backup-location.txt` must specify the backup root directory.
#
# Outputs:
#   - dconf-settings.ini: Dumped dconf configuration settings.
# ==============================================================#

set -e  # Exit on errors

# Constants
SCRIPT_DIR=$(dirname "$(realpath "$0")")
CONFIG_DIR="${SCRIPT_DIR}/config"
BACKUP_ROOT=$(<"${CONFIG_DIR}/backup-location.txt")
TIMESTAMP=$(date +%Y%m%d)
BACKUP_DIR="${BACKUP_ROOT}/dconf-backups-${TIMESTAMP}"
LOG_FILE="${BACKUP_DIR}/backup-dconf.log"

# Ensure backup root directory exists
mkdir -p "$BACKUP_DIR"

# Logging setup
exec > >(tee -a "$LOG_FILE") 2>&1

echo "========================================"
echo " Backup Dconf Settings"
echo "========================================"
echo "Backup Directory: $BACKUP_DIR"

# Backup dconf settings
if command -v dconf &>/dev/null; then
  echo "Backing up dconf settings..."
  dconf dump / >"${BACKUP_DIR}/dconf-settings.ini"
  echo "Dconf settings saved to: ${BACKUP_DIR}/dconf-settings.ini"
else
  echo "Error: 'dconf' is not installed. Cannot backup dconf settings." | tee -a "$LOG_FILE"
  exit 1
fi

echo "Backup completed successfully!"
echo "Log file: $LOG_FILE"
