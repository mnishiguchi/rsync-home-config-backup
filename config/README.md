# Rsync Backup Configuration

This directory contains configuration files for **rsync-based home directory backups**.

---

## 📌 Configuration Files

| File                      | Description                                                                           |
| ------------------------- | ------------------------------------------------------------------------------------- |
| `backup-location.example` | Example file showing how to set the backup destination path.                          |
| `backup-location.txt`     | **Actual backup location file** (ignored in version control).                         |
| `exclude-list.example`    | Example exclusion list for `rsync` (use this as a template).                          |
| `exclude-list.txt`        | **Active exclusion list** defining which files and directories to skip during backup. |

---

## 🚀 **Setup Guide**

### 1️⃣ **Set the Backup Location**

1. **Create `backup-location.txt`** by copying the example file:
   ```bash
   cp config/backup-location.example config/backup-location.txt
   ```
2. **Edit `backup-location.txt`** and set the absolute path to your backup destination:
   ```
   /mnt/backup-drive/home-backup
   ```
3. Verify that the path exists:
   ```bash
   cat config/backup-location.txt
   ```

---

### 2️⃣ **Customize the Exclusion List**

- The file **`exclude-list.txt`** contains directories and files that **should not be backed up**.
- To start with the default exclusions, copy the example file:
  ```bash
  cp config/exclude-list.example config/exclude-list.txt
  ```
- Edit `exclude-list.txt` to **add/remove exclusions** based on your needs.

---

## ✅ **How to Test the Exclusion List**

Before running the actual backup, **always test** your exclusions using `rsync --dry-run`.

### **🔹 Run a Dry-Run Backup**

```bash
rsync -avhPAX --dry-run --exclude-from=config/exclude-list.txt ~ /tmp/test-backup
```

- This simulates the backup **without copying files**, allowing you to verify that exclusions are working.

### **🔍 Check If Specific Files Are Excluded**

- Example: Check if `node_modules/` is properly excluded:
  ```bash
  rsync -avhPAX --dry-run --exclude-from=config/exclude-list.txt ~ /tmp/test-backup | grep node_modules
  ```
- Example: Check if all `tmp` and `cache` directories are skipped:
  ```bash
  rsync -avhPAX --dry-run --exclude-from=config/exclude-list.txt ~ /tmp/test-backup | grep -E "tmp|cache"
  ```
- If files appear in the output that **should be excluded**, update `exclude-list.txt` accordingly.

---

## 🚀 **Run the Actual Backup**

Once you've tested the exclusions, perform the real backup:

```bash
rsync -avhPAX --exclude-from=config/exclude-list.txt ~ "$(cat config/backup-location.txt)"
```

---

## ⚠️ **Important Notes**

- **`backup-location.txt` should NOT be committed** to version control.
- Always **run `rsync --dry-run` before an actual backup** to avoid unexpected results.
- Modify `exclude-list.txt` as needed to **fine-tune what gets backed up**.
