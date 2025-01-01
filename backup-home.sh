#!/bin/bash

# ==============================================================#
# Script: backup-home.sh
# Purpose:
#   Simplified home directory backup using rsync with encryption.
#
# Usage:
#   ./backup-home.sh [-d] [-n]
#
# Options:
#   -d  Dry run: Preview the backup without making changes.
#   -n  No compression: Skip tarball compression.
# ==============================================================#

set -e # Exit on errors

# Constants
SCRIPT_DIR=$(dirname "$(realpath "$0")")
CONFIG_DIR="${SCRIPT_DIR}/config"
BACKUP_ROOT=$(<"${CONFIG_DIR}/backup-location.txt") # Root backup directory
BACKUP_DIR="${BACKUP_ROOT}/home-$(whoami)-$(date +%Y%m%d)"
TARBALL="${BACKUP_ROOT}/home-$(whoami)-$(date +%Y%m%d).tar.gz"
ENCRYPTED_TARBALL="${TARBALL}.gpg"
LAST_BACKUP="${BACKUP_ROOT}/latest"
EXCLUDE_LIST="${CONFIG_DIR}/exclude-list.txt"
RSYNC_OPTIONS="${CONFIG_DIR}/rsync-options.txt"
LOG_FILE="${BACKUP_ROOT}/backup-home.log"

# Flags
DRY_RUN=false
COMPRESS_BACKUP=true

# Parse options
while getopts "dn" opt; do
  case $opt in
  d) DRY_RUN=true ;;
  n) COMPRESS_BACKUP=false ;;
  *)
    echo "Invalid option: -$OPTARG"
    exit 1
    ;;
  esac
done

# Ensure backup root directory exists
mkdir -p "${BACKUP_ROOT}"

# Display script settings
echo "========================="
echo " Home Directory Backup"
echo "========================="
echo "Backup Location: ${BACKUP_ROOT}"
echo "Exclude List: ${EXCLUDE_LIST}"
echo "Latest Backup (for incremental): ${LAST_BACKUP}"
[ "$DRY_RUN" == true ] && echo "Dry Run: Enabled"
[ "$COMPRESS_BACKUP" == false ] && echo "Compression: Skipped"
echo

read -rp "Do you want to proceed? (y/n): " CONFIRM
if [[ "$CONFIRM" != "y" ]]; then
  echo "Backup canceled."
  exit 0
fi

# Rsync options
RSYNC_CMD=(
  rsync -avhPAX --delete --delete-excluded --backup --suffix="$(date +%Y%m%d)"
  --log-file="${BACKUP_ROOT}/rsync.log" --inplace --verbose
)

# Include incremental backup with --link-dest
if [[ -d "${LAST_BACKUP}" ]]; then
  RSYNC_CMD+=(--link-dest="${LAST_BACKUP}")
  echo "Using incremental backup with previous snapshot: ${LAST_BACKUP}"
fi

# Add custom rsync options
if [[ -f "${RSYNC_OPTIONS}" ]]; then
  while IFS= read -r option; do
    RSYNC_CMD+=("$option")
  done <"${RSYNC_OPTIONS}"
fi

# Exclude list
if [[ -f "${EXCLUDE_LIST}" ]]; then
  RSYNC_CMD+=(--exclude-from="${EXCLUDE_LIST}")
  echo "Using exclude list: ${EXCLUDE_LIST}"
fi

# Add dry-run mode if enabled
[ "$DRY_RUN" == true ] && RSYNC_CMD+=(--dry-run)

# Final confirmation before starting backup
echo
echo "Ready to start backup to: ${BACKUP_DIR}"
read -rp "Proceed with backup? (y/n): " FINAL_CONFIRM
if [[ "$FINAL_CONFIRM" != "y" ]]; then
  echo "Backup canceled."
  exit 0
fi

# Perform the backup
echo "Starting backup..."
"${RSYNC_CMD[@]}" "${HOME}/" "${BACKUP_DIR}/" || {
  echo "Error: Rsync backup failed."
  exit 1
}

# Update latest symlink
ln -sfn "${BACKUP_DIR}" "${BACKUP_ROOT}/latest"

# Compress and encrypt the backup directory
if $COMPRESS_BACKUP; then
  echo "Compressing backup files..."
  tar -cvzf "${TARBALL}" -C "${BACKUP_ROOT}" "$(basename "${BACKUP_DIR}")"

  echo "Encrypting the backup tarball..."
  gpg --symmetric --cipher-algo AES256 --output "${ENCRYPTED_TARBALL}" "${TARBALL}"

  # Remove the unencrypted tarball
  rm -f "${TARBALL}"
  echo "Backup encrypted and saved at: ${ENCRYPTED_TARBALL}"
fi

# Log backup details
echo "Logging backup details..."
{
  echo "Backup Date: $(date)"
  echo "Backup Directory: ${BACKUP_DIR}"
  [ "$COMPRESS_BACKUP" == true ] && echo "Encrypted Archive: ${ENCRYPTED_TARBALL}"
  du -sh "${BACKUP_DIR}" "${ENCRYPTED_TARBALL}" 2>/dev/null | awk '{print $2 ": " $1}'
  echo "--------------------------------------------"
} >>"${LOG_FILE}"

# Retention policy: Clean up backups older than six months
echo "Cleaning up old backups..."
find "${BACKUP_ROOT}" -type d -name "home-$(whoami)-*" -mtime +180 -exec rm -rf {} \;
find "${BACKUP_ROOT}" -type f -name "*.tar.gz.gpg" -mtime +180 -exec rm -f {} \;

echo
echo "Backup completed successfully!"
echo "Backup location: ${BACKUP_DIR}"
[ "$COMPRESS_BACKUP" == true ] && echo "Encrypted archive: ${ENCRYPTED_TARBALL}"
du -sh "${BACKUP_DIR}" "${ENCRYPTED_TARBALL}" 2>/dev/null | awk '{print $2 ": " $1}'
