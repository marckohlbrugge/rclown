# Technical Decisions

This document captures implementation decisions made for rclown v1.

---

## Stack

| Component | Choice | Notes |
|-----------|--------|-------|
| Database | SQLite | Simple, no separate server, fits single-user model |
| Background Jobs | Solid Queue | Rails default, backed by SQLite |
| Frontend | Hotwire (Turbo + Stimulus) | Server-rendered with interactive sprinkles |
| CSS | Tailwind CSS | Utility-first styling |
| Deployment | Kamal | Docker-based, zero-downtime deploys |

---

## Authentication

**HTTP Basic Auth**

- Single username/password via browser prompt
- Configured via environment variables or Rails credentials
- Simple to set up, works well behind reverse proxy

---

## Security

**Credential Encryption**: Active Record Encryption (Rails 7+)

- Provider credentials (`access_key_id`, `secret_access_key`) encrypted at rest
- Uses Rails master key for encryption
- No external gems required

---

## Backup Execution

### Concurrency

- If a scheduled backup triggers while the same backup is already running: **skip and log**
- Prevents duplicate runs and resource contention
- Logged as a skipped run for visibility

### Cancellation

- Users can cancel running backups from the UI
- Sends `SIGTERM` to rclone process via stored PID
- Run marked as `cancelled` status

### Timeout

- **Global timeout: 12 hours**
- Applies to all backups
- Kills rclone process if exceeded, marks run as `failed`

### Dry Run

- Backups support dry-run mode using `rclone --dry-run`
- Shows what would transfer without actually syncing
- Useful for validating new backup configurations

### Scheduling

- Simple enum: `daily`, `weekly`
- No cron expressions in v1
- Solid Queue handles scheduling

### Retention

- Uses rclone's `--backup-dir` flag
- Deleted/overwritten files moved to `.deleted/backups/{backup_id}/{date}/`
- Date folders (not filename suffixes) for cleaner organization
- Configurable `retention_days` per backup (default: 30)
- `CleanupDeletedFilesJob` runs `rclone delete --min-age` to purge old files

### Comparison Mode

- Configurable per backup: `default`, `size_only`, `checksum`
- `default`: size + modification time (rclone standard)
- `size_only`: compare by size only (useful for migrations)
- `checksum`: compare by hash (thorough but slower)

---

## Dependencies

### rclone

- **Fail at boot** if rclone is not installed or incompatible version
- App checks for rclone on startup
- Prevents confusing runtime errors

---

## Provider & Storage Behavior

### Credential Changes

- When Provider credentials are updated, existing Storages and Backups are **kept**
- Assumes user knows new credentials still have access
- Backups may fail if access is revoked (visible in run history)

### Bucket Discovery

- **In-memory cache** via `Rails.cache`
- ~10 minute TTL
- Clears on app restart
- "Refresh" button for manual invalidation

---

## UI

### History Visualization

- **Timeline with dots** showing last 30 days
- Each dot represents a backup run
- Color indicates success (green) or failure (red)

### Process Monitoring

- Health panel shows rclone CPU/memory for running backups
- Uses `ps` command (cross-platform: macOS + Linux)
- Best-effort accuracy

---

## Email Notifications

- SMTP configuration stored in **Rails credentials**
- Single global notification address
- Email sent on backup failure only

---

## Testing

- **Model tests** for all models
- **Integration tests** for critical paths (backup execution flow)
- Not aiming for full system test coverage in v1

---

## Reference

- See `../sessy` for auth and Kamal deployment patterns
