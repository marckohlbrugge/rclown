# Backup Retention Strategy

> **Status: Implemented** - We chose Option 1 (`--backup-dir`) with date folders.

## Problem

A simple `rclone copy` or `rclone sync` doesn't handle deleted files well for backup purposes:

- **copy**: Additive only, never removes files. Deleted files remain in backup forever.
- **sync**: Makes destination identical to source. Deleted files are immediately removed from backup.

For proper backups, we want:
1. New files added immediately
2. Deleted files retained for a configurable period (e.g., 30 days) before removal

## Implemented Solution: `--backup-dir` with Date Folders

We use rclone's `--backup-dir` flag to move deleted/overwritten files to a separate directory organized by date.

### How it works

```bash
rclone sync source:bucket dest:bucket/path \
  --backup-dir dest:bucket/.deleted/backups/{backup_id}/{date}/path
```

- New files → copied to destination immediately
- Deleted files → moved to `.deleted/backups/{backup_id}/{date}/{path}/{filename}`
- Each backup has its own `.deleted` subdirectory (isolated retention periods)
- Date folders (not filename suffixes) for cleaner organization and browsing

### Directory Structure

```
bucket/
├── r2/
│   └── my-app/           # actual backup data
│       └── uploads/
│           └── photo.jpg
└── .deleted/
    └── backups/
        └── 5/            # backup ID
            ├── 2026-01-15/
            │   └── r2/my-app/uploads/
            │       └── old-photo.jpg
            └── 2026-01-19/
                └── r2/my-app/uploads/
                    └── deleted-file.jpg
```

### Cleanup

`CleanupDeletedFilesJob` runs periodically to purge old files:

```bash
rclone delete dest:.deleted/backups/{id}/ --min-age {retention_days}d
rclone rmdirs dest:.deleted/backups/{id}/ --leave-root
```

The `--min-age` flag uses actual file metadata (upload time), not folder names, so cleanup works correctly regardless of directory structure.

### Configuration

- `retention_days` per backup (default: 30)
- Cleanup job handles all enabled backups

## Why Date Folders over Filename Suffixes

Initially we used `--suffix -2026-01-19` which appends dates to filenames. We switched to date folders because:

1. **Cleaner browsing** - Can browse by date in any S3 UI
2. **Easier bulk operations** - Delete entire date folder vs filtering by suffix
3. **No filename pollution** - Original filenames preserved
4. **Simpler mental model** - "Files deleted on Jan 19" vs "files ending in -2026-01-19"
