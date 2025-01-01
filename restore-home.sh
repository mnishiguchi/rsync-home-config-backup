#!/bin/bash

# ==============================================================#
# Script: restore-home.sh
# Purpose:
#   Restores the user's home directory from a specified backup snapshot.
#   Handles encrypted tarballs if available.
#
# Usage:
#   ./restore-home.sh
#
# ==============================================================#

set -e # Exit on errors

# Constants
SCRIPT_DIR=$(dirname "$(realpath "$0")")
CONFIG_DIR="${SCRIPT_DIR}/config"
BACKUP_ROOT=$(<"${CONFIG_DIR}/backup-location.txt")
RESTORE_DIR="${HOME}"
LOG_FILE="${BACKUP_ROOT}/restore-home.log"

# Ensure backup root directory exists
if [[ ! -d "${BACKUP_ROOT}" ]]; then
  echo "Backup root directory not found: ${BACKUP_ROOT}" | tee -a "$LOG_FILE"
  exit 1
fi

# List available backups
echo "Available Backups:"
echo "------------------"
BACKUPS=$(ls -1 "${BACKUP_ROOT}" | grep -E '^home-$(whoami)-[0-9]{8}.tar.gz.gpg$' || true)
if [[ -z "$BACKUPS" ]]; then
  echo "No encrypted backups found." | tee -a "$LOG_FILE"
  exit 1
fi
echo "$BACKUPS"

# Prompt user to select a backup
echo
read -rp "Enter the backup file name (e.g., home-$(whoami)-20241228.tar.gz.gpg): " SELECTED_BACKUP
ENCRYPTED_TARBALL="${BACKUP_ROOT}/${SELECTED_BACKUP}"
TARBALL="${ENCRYPTED_TARBALL%.gpg}"

# Ensure the selected backup exists
if [[ ! -f "${ENCRYPTED_TARBALL}" ]]; then
  echo "Encrypted backup file not found: ${ENCRYPTED_TARBALL}" | tee -a "$LOG_FILE"
  exit 1
fi

# Confirmation prompt
echo "You are about to restore from: ${ENCRYPTED_TARBALL}"
read -rp "Do you want to proceed? (y/n): " CONFIRM
if [[ "$CONFIRM" != "y" ]]; then
  echo "Restore canceled." | tee -a "$LOG_FILE"
  exit 0
fi

# Decrypt the tarball
echo "Decrypting the backup tarball..."
gpg --output "${TARBALL}" --decrypt "${ENCRYPTED_TARBALL}" || {
  echo "Decryption failed." | tee -a "$LOG_FILE"
  exit 1
}

# Extract the tarball
echo "Extracting the backup files..."
EXTRACTED_DIR="${BACKUP_ROOT}/extracted-home-$(whoami)-$(date +%Y%m%d)"
mkdir -p "${EXTRACTED_DIR}"
tar -xvzf "${TARBALL}" -C "${EXTRACTED_DIR}" || {
  echo "Failed to extract backup files." | tee -a "$LOG_FILE"
  rm -f "${TARBALL}" # Cleanup decrypted tarball
  exit 1
}

# Remove the decrypted tarball
rm -f "${TARBALL}"
echo "Decrypted tarball removed for security."

# Restore home directory
echo "Restoring home directory from extracted files..."
read -rp "This will overwrite existing files in your home directory. Continue? (y/n): " FINAL_CONFIRM
if [[ "$FINAL_CONFIRM" != "y" ]]; then
  echo "Home directory restore canceled." | tee -a "$LOG_FILE"
  rm -rf "${EXTRACTED_DIR}" # Cleanup extracted files
  exit 0
fi

rsync -avhPAX "${EXTRACTED_DIR}/home/" "${RESTORE_DIR}/" || {
  echo "Failed to restore home directory." | tee -a "$LOG_FILE"
  rm -rf "${EXTRACTED_DIR}" # Cleanup extracted files
  exit 1
}

# Cleanup extracted files
rm -rf "${EXTRACTED_DIR}"

echo "Home directory restored successfully." | tee -a "$LOG_FILE"
echo "Restore completed from: ${ENCRYPTED_TARBALL}" | tee -a "$LOG_FILE"
