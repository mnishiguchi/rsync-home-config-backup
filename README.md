# **Home Backup and Restore Script**

## **Overview**

This project provides scripts to backup and restore your home directory and essential configurations on Linux. It supports incremental backups, selective inclusion and exclusion, and easy restoration of specific configurations such as `dconf` settings or installed packages.

### **Features**

- **Backup**:

  - Incremental backups using `rsync`.
  - Compression of critical configuration files.
  - Customizable include/exclude lists.
  - Retention policy for old backups.
  - Logging of backup operations.

- **Restore**:

  - Selective restoration of backups.
  - Interactive prompts for user confirmation.
  - Logs restore operations for troubleshooting.

- **Modular Scripts**:
  - Dedicated scripts for backing up and restoring `dconf` settings and installed packages (Debian and Flatpak).

---

## **Getting Started**

### **1. Clone the Repository**

```bash
git clone https://github.com/your-username/rsync-home-config-backup.git
cd rsync-home-config-backup
```

### **2. Set Up Configuration Files**

Copy and customize the example configuration files:

```bash
cp config/backup-location.example config/backup-location.txt
cp config/include-list.example config/include-list.txt
cp config/exclude-list.example config/exclude-list.txt
cp config/rsync-options.example config/rsync-options.txt
```

#### **Configuration Files**

- `backup-location.txt`: Specify the directory where backups will be stored (e.g., external drive or network share).
- `exclude-list.txt`: List files and directories to exclude from the backup.
- `rsync-options.txt`: Additional `rsync` options (optional).

### **3. Run the Backup Script**

To back up your home directory:

```bash
./backup-home.sh
```

### **4. Run the Restore Script**

To restore your home directory from a backup:

```bash
./restore-home.sh
```

### **5. Run Modular Scripts**

For `dconf` settings:

- Backup:
  ```bash
  ./backup-dconf.sh
  ```
- Restore:
  ```bash
  ./restore-dconf.sh
  ```

For package management:

- Debian Packages:

  - Backup:
    ```bash
    ./backup-dpkg.sh
    ```
  - Restore:
    ```bash
    ./restore-dpkg.sh
    ```

- Flatpak Applications:
  - Backup:
    ```bash
    ./backup-flatpak.sh
    ```
  - Restore:
    ```bash
    ./restore-flatpak.sh
    ```

---

## **How It Works**

### **Backup**

1. Reads configuration files for include/exclude lists and backup location.
2. Uses `rsync` to create incremental backups, optionally compressing configuration files.
3. Logs backup details and applies a retention policy to remove backups older than six months.

### **Restore**

1. Lists available backups and prompts the user to select one.
2. Uses `rsync` to restore the home directory interactively.

---

## **Advanced Options**

### **Backup Options**

- **Dry Run**:
  Preview the backup process without making any changes:

  ```bash
  ./backup-home.sh -d
  ```

- **Skip Compression**:
  Run the backup without compressing configuration files:
  ```bash
  ./backup-home.sh -n
  ```

### **Restore Options**

- Restore selectively by modifying the include/exclude lists before running the script.

---

## **Folder Structure**

```
rsync-home-config-backup/
├── backup-home.sh              # Backup script
├── restore-home.sh             # Restore script
├── backup-dconf.sh             # Backup dconf settings
├── restore-dconf.sh            # Restore dconf settings
├── backup-dpkg.sh              # Backup Debian packages
├── restore-dpkg.sh             # Restore Debian packages
├── backup-flatpak.sh           # Backup Flatpak applications
├── restore-flatpak.sh          # Restore Flatpak applications
├── config/                     # Configuration directory
│   ├── backup-location.example  # Example backup location
│   ├── exclude-list.example     # Example exclude list
│   ├── rsync-options.example    # Example rsync options
```

---

## **Relevant Environment and Software**

This project is developed and tested on the following environment:

- **Operating System**: Linux Mint Debian Edition 6 (LMDE 6) - based on Debian.
- **Shell**: Bash 5.2.15.
- **Backup Tools**: `rsync`, `tar`, and `dconf`.
- **Package Managers**: `dpkg` for Debian packages and `flatpak` for Flatpak applications.
