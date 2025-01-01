#!/bin/bash

# ==============================================================#
# Script: view-home-backup.sh
# Purpose:
#   Decrypt and view the contents of an encrypted home backup tarball.
#   This script does not modify the backup file or extract it permanently.
# ==============================================================#

set -e # Exit on errors

# Constants
SCRIPT_DIR=$(dirname "$(realpath "$0")")
CONFIG_DIR="${SCRIPT_DIR}/config"
BACKUP_ROOT=$(<"${CONFIG_DIR}/backup-location.txt")
LOG_FILE="${BACKUP_ROOT}/view-home-backup.log"

# Ensure backup root directory exists
if [[ ! -d "${BACKUP_ROOT}" ]]; then
  echo "Backup root directory not found: ${BACKUP_ROOT}" | tee -a "$LOG_FILE"
  exit 1
fi

# List available backups
echo "Available Encrypted Home Backups:"
echo "---------------------------------"
BACKUPS=$(ls -1 "${BACKUP_ROOT}"/home-*.tar.gz.gpg 2>/dev/null || true)
if [[ -z "$BACKUPS" ]]; then
  echo "No encrypted home backups found." | tee -a "$LOG_FILE"
  exit 1
fi
echo "$BACKUPS"

# Prompt user to select a backup
echo
read -rp "Enter the backup file name (e.g., home-$(whoami)-20241228.tar.gz.gpg): " SELECTED_BACKUP
ENCRYPTED_TARBALL="${BACKUP_ROOT}/${SELECTED_BACKUP}"

# Ensure the selected backup exists
if [[ ! -f "${ENCRYPTED_TARBALL}" ]]; then
  echo "Encrypted home backup file not found: ${ENCRYPTED_TARBALL}" | tee -a "$LOG_FILE"
  exit 1
fi

# Confirmation prompt
echo "You are about to view the contents of: ${ENCRYPTED_TARBALL}"
read -rp "Do you want to proceed? (y/n): " CONFIRM
if [[ "$CONFIRM" != "y" ]]; then
  echo "Operation canceled." | tee -a "$LOG_FILE"
  exit 0
fi

# Temporary directory for decrypted backup
TEMP_DIR=$(mktemp -d)
TARBALL="${TEMP_DIR}/$(basename "${ENCRYPTED_TARBALL%.gpg}")"

# Decrypt the tarball
echo "Decrypting the home backup tarball..."
gpg --output "${TARBALL}" --decrypt "${ENCRYPTED_TARBALL}" || {
  echo "Decryption failed." | tee -a "$LOG_FILE"
  rm -rf "${TEMP_DIR}" # Cleanup temporary directory
  exit 1
}

# View contents of the tarball
echo "Listing the contents of the home backup..."
tar -tvzf "${TARBALL}"

# Cleanup
rm -rf "${TEMP_DIR}"
echo "Temporary files removed."
echo "Home backup content listed successfully."
