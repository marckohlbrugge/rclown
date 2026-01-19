# Backup Retention Strategy

## Problem

A simple `rclone copy` or `rclone sync` doesn't handle deleted files well for backup purposes:

- **copy**: Additive only, never removes files. Deleted files remain in backup forever.
- **sync**: Makes destination identical to source. Deleted files are immediately removed from backup.

For proper backups, we want:
1. New files added immediately
2. Deleted files retained for a configurable period (e.g., 30 days) before removal
3. (Future) Modified files could keep previous versions

## Option 1: rclone `--backup-dir`

rclone's `--backup-dir` flag moves deleted/overwritten files to a separate directory instead of deleting them.

### How it works

```bash
rclone sync source: dest: --backup-dir dest:.deleted --suffix -2026-01-06
```

- New files → copied to destination immediately
- Deleted files → moved to `dest:.deleted/original/path/file.txt-2026-01-06`
- Original path structure preserved in `.deleted/`

### Cleanup

A scheduled job deletes old files from `.deleted/`:

```bash
rclone delete dest:.deleted --min-age 30d
rclone rmdirs dest:.deleted --leave-root  # remove empty directories
```

### Implementation

```ruby
# In Rclone::Executor#build_command
cmd = [
  "rclone",
  "sync",
  source_path,
  dest_path,
  "--backup-dir", "#{dest_path}/.deleted",
  "--suffix", "-#{Date.current.iso8601}",
  "--config", config_file.path,
  ...
]
```

```ruby
# New job: CleanupDeletedFilesJob
class CleanupDeletedFilesJob < ApplicationJob
  def perform(backup)
    # rclone delete dest:.deleted --min-age #{backup.retention_days}d
    # rclone rmdirs dest:.deleted --leave-root
  end
end
```

### Schema changes

```ruby
# Add to backups table
add_column :backups, :retention_days, :integer, default: 30
```

### Pros
- Full control within the app
- Visibility into what's pending deletion
- Can expose `.deleted/` contents in UI for manual restore
- Works with any storage provider

### Cons
- More complex than simple copy/sync
- Requires separate cleanup job
- Suffix-based dating means one "version" per day max

---

## Option 2: Bucket-level versioning

S3, B2, and R2 all support object versioning at the storage level.

### How it works

1. Enable versioning on the bucket (one-time setup)
2. Use `rclone sync` normally
3. When files are deleted, storage creates a "delete marker" but retains the data
4. Lifecycle rules auto-expire old versions after N days

### Setup examples

**Cloudflare R2:**
```bash
# Via Cloudflare dashboard or API
# Enable versioning on bucket, set lifecycle rule
```

**Backblaze B2:**
```bash
b2 update-bucket --lifecycle-rules '[{
  "daysFromHidingToDeleting": 30,
  "fileNamePrefix": ""
}]' bucketName
```

**Amazon S3:**
```bash
aws s3api put-bucket-versioning --bucket bucketName --versioning-configuration Status=Enabled
aws s3api put-bucket-lifecycle-configuration --bucket bucketName --lifecycle-configuration '{
  "Rules": [{
    "ID": "DeleteOldVersions",
    "Status": "Enabled",
    "NoncurrentVersionExpiration": { "NoncurrentDays": 30 }
  }]
}'
```

### Pros
- Zero rclone complexity
- Storage provider handles retention automatically
- Multiple versions per day possible
- Restore through provider's interface
- Battle-tested infrastructure

### Cons
- Configuration lives outside the app
- Less visibility (can't easily show pending deletions in UI)
- Slightly different setup per provider
- May have cost implications (storing versions)

---

## Comparison

| Aspect | `--backup-dir` | Bucket versioning |
|--------|----------------|-------------------|
| Setup complexity | Medium (code changes) | Low (one-time bucket config) |
| Ongoing maintenance | Cleanup job needed | None |
| Control | Full | Limited |
| UI integration | Easy | Harder |
| Multi-version per day | No (date suffix) | Yes |
| Provider support | Universal | Most providers |
| Cost | Storage for .deleted | Storage for versions |

---

## Recommendation

For a backup dashboard that wants to provide visibility and control, **Option 1 (`--backup-dir`)** is more suitable:

1. Keeps everything within the app's control
2. Can show users what's pending deletion
3. Allows manual restore from UI
4. Consistent behavior across all providers

However, **Option 2 (bucket versioning)** is simpler if:
1. Users are comfortable configuring their buckets
2. Less UI control is acceptable
3. You want to minimize code complexity

A hybrid approach is also possible: document bucket versioning as "recommended setup" while using `rclone copy` (additive) in the app, letting the bucket handle retention.
