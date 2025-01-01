#!/bin/bash

# ==============================================================#
# Script: backup-home.sh
# Purpose:
#   Simplified home directory backup using rsync.
#
# Usage:
#   ./backup-home.sh [-d] [-n]
#
# Options:
#   -d  Dry run: Preview the backup without making changes.
#   -n  No compression: Skip tarball compression.
#
# ==============================================================#

set -e # Exit on errors

# Constants
SCRIPT_DIR=$(dirname "$(realpath "$0")")
CONFIG_DIR="${SCRIPT_DIR}/config"
BACKUP_ROOT=$(<"${CONFIG_DIR}/backup-location.txt") # Root backup directory
BACKUP_DIR="${BACKUP_ROOT}/home-$(whoami)-$(date +%Y%m%d)"
BACKUP_ARCHIVE="${BACKUP_ROOT}/home-$(whoami)-$(date +%Y%m%d).tar.gz"
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

# Compress backup if enabled
if $COMPRESS_BACKUP; then
  echo "Compressing backup directory..."
  tar --ignore-failed-read -cvzf "${BACKUP_ARCHIVE}" -C "${BACKUP_ROOT}" "$(basename "${BACKUP_DIR}")"
fi

# Log backup details
echo "Logging backup details..."
{
  echo "Backup Date: $(date)"
  echo "Backup Directory: ${BACKUP_DIR}"
  [ "$COMPRESS_BACKUP" == true ] && echo "Compressed Archive: ${BACKUP_ARCHIVE}"
  du -sh "${BACKUP_DIR}" "${BACKUP_ARCHIVE}" 2>/dev/null | awk '{print $2 ": " $1}'
  echo "--------------------------------------------"
} >>"${LOG_FILE}"

# Retention policy: Clean up backups older than six months
echo "Cleaning up old backups..."
find "${BACKUP_ROOT}" -maxdepth 1 -type d -name "home-$(whoami)-*" -mtime +180 -exec rm -rf {} \;
find "${BACKUP_ROOT}" -maxdepth 1 -type f -name "home-$(whoami)-*.tar.gz" -mtime +180 -exec rm -f {} \;

echo
echo "Backup completed successfully!"
echo "Backup location: ${BACKUP_DIR}"
[ "$COMPRESS_BACKUP" == true ] && echo "Compressed archive: ${BACKUP_ARCHIVE}"
du -sh "${BACKUP_DIR}" "${BACKUP_ARCHIVE}" 2>/dev/null | awk '{print $2 ": " $1}'
