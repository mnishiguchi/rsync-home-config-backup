# Home Backup and Restore Scripts

## Overview

These scripts provide an easy and efficient way to back up and restore your home directory and essential system configurations on Linux. Designed for simplicity and modularity, the scripts are ideal for regular backups and disaster recovery.

### Features

- **Backup**:
  - Incremental backups using `rsync`.
  - Encryption and compression of backup archives.
  - Customizable include/exclude lists for precise control.
  - Logging of all operations for traceability.
  - Retention policy to manage backup storage.
- **Restore**:
  - Selective restoration of backups.
  - Interactive prompts for safety and control.
  - Modular design for restoring individual configurations (e.g., `dconf`, Debian packages, Flatpak apps).
- **Modular Design**:
  - Dedicated scripts for home directory, `dconf`, package management, and Flatpak applications.

---

## Getting Started

### Prerequisites

- **Operating System**:
  - Linux (tested on Linux Mint Debian Edition 6)
- **Dependencies**:
  - `rsync`: For efficient file synchronization
  - `gpg`: For encrypting and decrypting backups
  - `tar`: For creating compressed archives

### Setup

1. **Clone the Repository**:

   ```bash
   git clone https://github.com/your-username/home-backup-scripts.git
   cd home-backup-scripts
   ```

2. **Configure the Scripts**:
   Copy and customize the example configuration files:

   ```bash
   cp config/backup-location.example config/backup-location.txt
   cp config/exclude-list.example config/exclude-list.txt
   cp config/rsync-options.example config/rsync-options.txt
   ```

   - **`config/backup-location.txt`**: Specify the absolute path where backups will be stored, such as an external drive or a network share. Example:
     ```
     /media/username/backup-drive
     ```
   - **`config/exclude-list.txt`**: Define files and directories to exclude from the backup. Each line represents an exclusion pattern. Example:
     ```
     /.cache/
     /Downloads/
     /Videos/
     ```
   - **`config/rsync-options.txt`**: Add additional `rsync` options for customization, such as limiting file sizes or preserving hard links. Example:
     ```
     --hard-links
     --no-compress
     --max-size=100M
     --progress
     ```

3. **Verify the Configuration**:
   Ensure all configuration files are correctly set up before running the scripts. Missing or misconfigured files will prevent the scripts from functioning properly.

---

## Usage

### Backup Scripts

#### 1. Home Directory Backup

To back up your home directory:

```bash
./backup-home.sh
```

**Options**:

- `-d`: Dry run (preview without making changes).
- `-n`: Skip compression.

#### 2. Dconf Settings Backup

Backup GNOME/desktop settings:

```bash
./backup-dconf.sh
```

#### 3. Debian Packages Backup

Save a list of installed Debian packages:

```bash
./backup-dpkg.sh
```

#### 4. Flatpak Applications Backup

Save a list of installed Flatpak applications:

```bash
./backup-flatpak.sh
```

### Restore Scripts

#### 1. Home Directory Restore

Restore your home directory from a backup:

```bash
./restore-home.sh
```

#### 2. Dconf Settings Restore

Restore GNOME/desktop settings:

```bash
./restore-dconf.sh
```

#### 3. Debian Packages Restore

Reinstall saved Debian packages:

```bash
./restore-dpkg.sh
```

#### 4. Flatpak Applications Restore

Reinstall saved Flatpak applications:

```bash
./restore-flatpak.sh
```

---

## How It Works

### Backup

1. Reads configuration files for include/exclude lists and backup location.
2. Uses `rsync` for incremental backups, ensuring efficient storage.
3. Optionally compresses and encrypts backups for security.
4. Logs all operations for reference.
5. Applies a retention policy to delete backups older than six months.

### Restore

1. Lists available backups and prompts you to select one.
2. Optionally decrypts and extracts backup archives.
3. Restores files interactively to avoid overwriting unintended data.

---

## Advanced Options

### Backup Options

- **Dry Run**:
  Preview the backup process without making changes:

  ```bash
  ./backup-home.sh -d
  ```

- **Skip Compression**:
  Run the backup without compressing configuration files:
  ```bash
  ./backup-home.sh -n
  ```

### Restore Options

- Restore selectively by editing the include/exclude lists before running the restore script.

---

## Folder Structure

```sh
home-backup-scripts/
├── backup-home.sh              # Script to back up the home directory
├── view-home-backup.sh         # Script to view the contents of a home directory backup
├── restore-home.sh             # Script to restore the home directory from a backup
├── backup-dconf.sh             # Script to back up GNOME/dconf settings
├── restore-dconf.sh            # Script to restore GNOME/dconf settings
├── backup-dpkg.sh              # Script to back up installed Debian packages
├── restore-dpkg.sh             # Script to restore installed Debian packages
├── backup-flatpak.sh           # Script to back up Flatpak applications
├── restore-flatpak.sh          # Script to restore Flatpak applications
├── config/                     # Configuration directory
│   ├── backup-location.txt     # Defines the location for storing backups
│   ├── exclude-list.txt        # List of files/directories to exclude from backups
│   ├── rsync-options.txt       # Customizable rsync options
```

---

## Best Practices

1. **Test Restores Regularly**:
   Periodically test the restore process to ensure backups are functional.

2. **Store Backups Securely**:
   Use an external drive or network location for storing backups.

3. **Monitor Storage Usage**:
   Review backup storage periodically and adjust retention policies as needed.

4. **Keep Dependencies Updated**:
   Ensure `rsync` is up-to-date.

---

## Troubleshooting

- **Command Not Found**:
  Ensure `rsync` is installed and available in your `PATH`.

- **Permission Denied**:
  Run scripts with the necessary permissions (e.g., `sudo` for restoring system packages).

- **Broken Symlinks**:
  If the `latest` symlink is broken, remove it and let the backup script create a new one.
