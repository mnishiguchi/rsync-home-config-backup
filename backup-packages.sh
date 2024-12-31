#!/bin/bash

# ==============================================================#
# Script: backup-packages.sh
# Purpose:
#   Backup lists of installed Debian and Flatpak packages.
#
# Usage:
#   ./backup-packages.sh
#
# Requirements:
#   - `dpkg` must be installed for Debian package management.
#   - `flatpak` must be installed for Flatpak package management.
#   - `config/backup-location.txt` must specify the backup root directory.
#
# Outputs:
#   - packages.list: List of installed Debian packages.
#   - flatpak.list: List of installed Flatpak applications.
# ==============================================================#

set -e  # Exit on error

# Constants
SCRIPT_DIR=$(dirname "$(realpath "$0")")
CONFIG_DIR="${SCRIPT_DIR}/config"
BACKUP_ROOT=$(<"${CONFIG_DIR}/backup-location.txt")
TIMESTAMP=$(date +%Y%m%d)
BACKUP_DIR="${BACKUP_ROOT}/package-backups-${TIMESTAMP}"
LOG_FILE="${BACKUP_DIR}/backup-packages.log"

# Ensure backup root directory exists
mkdir -p "$BACKUP_DIR"

# Logging setup
exec > >(tee -a "$LOG_FILE") 2>&1

echo "========================================"
echo " Backup Installed Packages"
echo "========================================"
echo "Backup Directory: $BACKUP_DIR"

# Backup Debian packages
if command -v dpkg &>/dev/null; then
  echo "Backing up Debian packages..."
  dpkg --get-selections >"${BACKUP_DIR}/packages.list"
  echo "Debian packages saved to: ${BACKUP_DIR}/packages.list"
else
  echo "Warning: 'dpkg' not found. Skipping Debian packages backup."
fi

# Backup Flatpak packages
if command -v flatpak &>/dev/null; then
  echo "Backing up Flatpak packages..."
  flatpak list --app --columns=app >"${BACKUP_DIR}/flatpak.list"
  echo "Flatpak packages saved to: ${BACKUP_DIR}/flatpak.list"
else
  echo "Warning: 'flatpak' not found. Skipping Flatpak packages backup."
fi

echo "Backup completed successfully!"
echo "Log file: $LOG_FILE"
