#!/bin/bash

# ==============================================================#
# Script: backup-home.sh
# Purpose:
#   Securely backs up the user's home directory using rsync.
#   All backups are encrypted with gpg. Optionally skips compression.
#
# Usage:
#   ./backup-home.sh [-d] [-n]
#
# Options:
#   -d  Dry run: Preview the backup without making changes.
#   -n  No compression: Skip tarball compression.
# ==============================================================#

set -euo pipefail # Improved error handling

# Constants
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
CONFIG_DIR="${SCRIPT_DIR}/config"
BACKUP_ROOT="$(<"${CONFIG_DIR}/backup-location.txt")"
BACKUP_DATE="$(date +%Y%m%d)"
BACKUP_DIR="${BACKUP_ROOT}/home-$(whoami)-${BACKUP_DATE}"
TARBALL="${BACKUP_ROOT}/home-$(whoami)-${BACKUP_DATE}.tar.gz"
ENCRYPTED_TARBALL="${TARBALL}.gpg"
LAST_BACKUP="${BACKUP_ROOT}/latest"
EXCLUDE_LIST="${CONFIG_DIR}/exclude-list.txt"
LOG_FILE="${BACKUP_ROOT}/backup-home.log"

# Flags
DRY_RUN=false
COMPRESS_BACKUP=true

# Output styling functions
echo_heading() { echo -e "\n\033[34m$1\033[0m"; }  # Blue
echo_success() { echo -e " \033[32m✔ $1\033[0m"; } # Green
echo_warning() { echo -e " \033[33m⚠ $1\033[0m"; } # Yellow
echo_failure() { echo -e " \033[31m✖ $1\033[0m"; } # Red

# Parse options
parse_options() {
  while getopts ":dn" opt; do
    case $opt in
    d) DRY_RUN=true ;;
    n) COMPRESS_BACKUP=false ;;
    *)
      echo_failure "Invalid option: -$OPTARG"
      exit 1
      ;;
    esac
  done
}

# Ensure the backup location exists
check_backup_root() {
  echo_heading "Checking backup location..."
  if [[ ! -d "$BACKUP_ROOT" ]]; then
    echo_warning "Backup location \"$BACKUP_ROOT\" not found. Creating..."
    mkdir -p "$BACKUP_ROOT" && echo_success "Backup location created." || {
      echo_failure "Failed to create $BACKUP_ROOT. Check config/backup-location.txt."
      exit 1
    }
  else
    echo_success "Backup location exists."
  fi
}

# Ensure required tools are installed
check_required_tools() {
  echo_heading "Checking required tools..."
  for tool in rsync tar gpg; do
    command -v "$tool" &>/dev/null || {
      echo_failure "Error: '$tool' not found."
      exit 1
    }
  done
  echo_success "All required tools are installed."
}

# Configure rsync options (restoring your original logic)
setup_rsync_options() {
  RSYNC_CMD=(
    rsync -avhPAX --delete --delete-excluded --backup --suffix=".${BACKUP_DATE}"
    --log-file="${BACKUP_ROOT}/rsync.log" --verbose
    --hard-links --no-compress --max-size=100M --progress
  )

  if [[ -d "${LAST_BACKUP}" ]]; then
    RSYNC_CMD+=("--link-dest=${LAST_BACKUP}")
  fi

  if [[ -f "${EXCLUDE_LIST}" ]]; then
    RSYNC_CMD+=("--exclude-from=${EXCLUDE_LIST}")
  fi

  if [[ "$DRY_RUN" == true ]]; then
    RSYNC_CMD+=("--dry-run")
  fi
}

# Display script settings
display_backup_config() {
  echo_heading "Backup Configuration"
  cat <<EOF
Backup Location: ${BACKUP_ROOT}
Exclude List: ${EXCLUDE_LIST}
Latest Backup: ${LAST_BACKUP}
Dry Run: ${DRY_RUN}
Compression: ${COMPRESS_BACKUP}
EOF
}

# Confirm before proceeding
confirm_backup() {
  read -rp "Proceed? (y/n): " CONFIRM
  CONFIRM=$(echo "$CONFIRM" | xargs) # Trim spaces
  if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Backup canceled."
    exit 0
  fi
}

# Perform the backup
perform_backup() {
  echo_heading "Starting backup..."
  "${RSYNC_CMD[@]}" "${HOME}/" "${BACKUP_DIR}/" || {
    echo_failure "Error: Rsync failed."
    exit 1
  }
  echo_success "Backup completed successfully."
  ln -sfn "${BACKUP_DIR}" "${LAST_BACKUP}"
}

# Compress and encrypt the backup
encrypt_backup() {
  if $COMPRESS_BACKUP; then
    echo_heading "Compressing..."
    tar -czf "${TARBALL}" -C "${BACKUP_ROOT}" "$(basename "${BACKUP_DIR}")"

    echo_heading "Encrypting..."
    gpg --symmetric --cipher-algo AES256 --output "${ENCRYPTED_TARBALL}" "${TARBALL}"

    rm -f "${TARBALL}"
    echo_success "Backup saved: ${ENCRYPTED_TARBALL}"
  fi
}

# Log the backup details
log_backup() {
  echo_heading "Logging backup details..."
  {
    echo "Backup Date: $(date)"
    echo "Backup Directory: ${BACKUP_DIR}"
    $COMPRESS_BACKUP && echo "Encrypted Archive: ${ENCRYPTED_TARBALL}"
    du -sh "${BACKUP_DIR}" "${ENCRYPTED_TARBALL}" 2>/dev/null | awk '{print $2 ": " $1}'
    echo "--------------------------------------------"
  } >>"${LOG_FILE}"
  echo_success "Backup details logged."
}

# Cleanup old backups
cleanup_old_backups() {
  echo_heading "Cleaning up old backups..."
  find "${BACKUP_ROOT}" -type d -o -type f -name "*.tar.gz.gpg" -mtime +180 -exec rm -rf {} +
  echo_success "Old backups cleaned up."
}

# Main execution
main() {
  parse_options "$@"
  check_backup_root
  check_required_tools
  setup_rsync_options
  display_backup_config
  confirm_backup
  perform_backup
  encrypt_backup
  log_backup
  cleanup_old_backups

  echo_heading "Backup Completed"
  echo "Backup directory: ${BACKUP_DIR}"
  $COMPRESS_BACKUP && echo "Encrypted archive: ${ENCRYPTED_TARBALL}"
  du -sh "${BACKUP_DIR}" "${ENCRYPTED_TARBALL}" 2>/dev/null | awk '{print $2 ": " $1}'
}

main "$@"
