
# PRD: Self-Hosted Object Storage Backup Dashboard (Rails + rclone)

## 1. Purpose

Build a **self-hosted Rails application** that allows a user to configure, run, and monitor **object storage backups** (Cloudflare R2, Backblaze B2, Amazon S3) using **rclone**.

The product is intentionally simple:

* One server
* One user
* One UI
* Clear visibility that backups are running correctly

A self-hosted alternative to cloud backup services for **bucket-to-bucket backups**, without recurring SaaS fees.

---

## 2. Scope (v1)

### In scope

* Configure storage providers (credentials)
* Discover buckets from providers on demand
* Create backups linking a source bucket to a destination bucket
* Run backups on a schedule or manually
* Execute backups via rclone
* Store and display logs
* Show backup history and status
* Email notifications on failure
* Basic instance health (CPU, memory)

### Out of scope

* Multi-tenant / user accounts
* SaaS integrations (GitHub, Notion, etc.)
* Restore UI
* Server-side copy
* Custom per-backup rclone flags
* Snapshot/archival backups (only mirror-style backups)

---

## 3. Terminology

Use **backup-first language**, not “sync”.

| Term           | Meaning                                                          |
| -------------- | ---------------------------------------------------------------- |
| **Provider**   | Credentials + config for a storage provider                      |
| **Storage**    | A specific bucket (and optional prefix) under a provider         |
| **Backup**     | A persistent backup definition (source → destination + schedule) |
| **Backup Run** | One execution of a backup                                        |

---

## 4. Architecture Overview

* Rails app (monolith)
* Solid Queue for background jobs
* rclone installed on the server
* PostgreSQL or SQLite
* Single VPS (Linux)

Rails **orchestrates** backups. rclone performs all data transfer as a separate OS process.

---

## 5. Data Models

### 5.1 Provider

Represents credentials and configuration for a storage provider.

**Fields**

* `id`
* `name` (string, e.g. “Cloudflare R2 (all buckets)”)
* `provider_type` (enum: `cloudflare_r2`, `backblaze_b2`, `amazon_s3`)
* `endpoint` (string, optional)
* `region` (string, optional)
* `access_key_id` (encrypted)
* `secret_access_key` (encrypted)
* `created_at`, `updated_at`

**Notes**

* One Provider can access multiple buckets
* Credentials are stored encrypted
* Providers are reused across many backups

---

### 5.2 Storage

Represents a bucket under a provider.

**Fields**

* `id`
* `provider_id`
* `bucket_name`
* `display_name` (optional, derived if empty)
* `usage_type` (enum: `source_only`, `destination_only`, or null for any)
* `created_at`, `updated_at`

**Notes**

* Storages do **not** store credentials
* Only storages explicitly imported/created are persisted
* Paths within buckets are configured on Backups, not Storages

---

### 5.3 Backup

Defines a backup configuration.

**Fields**

* `id`
* `name`
* `source_storage_id`
* `destination_storage_id`
* `source_path` (string, optional; path within source bucket)
* `destination_path` (string, optional; path within destination bucket)
* `schedule` (enum: `daily`, `weekly`)
* `enabled` (boolean)
* `retention_days` (integer, default: 30)
* `comparison_mode` (enum: `default`, `size_only`, `checksum`)
* `last_run_at`
* `created_at`, `updated_at`

**Constraints**

* Source and destination must be different
* Backups use rclone `sync` mode with `--backup-dir` for retention

---

### 5.4 BackupRun

Represents one execution of a backup.

**Fields**

* `id`
* `backup_id`
* `status` (enum: `pending`, `running`, `success`, `failed`)
* `started_at`
* `finished_at`
* `exit_code`
* `raw_log` (text)
* `rclone_pid` (integer, optional)
* `created_at`

**Derived**

* Duration
* Success/failure
* Used for history and alerts

---

## 6. Provider Bucket Discovery

### Behavior

* Buckets are **not stored** in the database unless imported
* Bucket lists are fetched **on demand**

### Implementation

* On Provider show page, load buckets via a lazy-loaded endpoint
* Use rclone to list buckets (e.g. `rclone lsd`)
* Cache results briefly (e.g. 10 minutes)
* Provide a “Refresh” button

### UI

For each bucket:

* If already imported → show “Imported”
* Else → show “Import” button

Importing a bucket creates a Storage record.

---

## 7. Backup Execution

### Scheduling

* Solid Queue schedules Backup Runs based on Backup schedule
* “Run backup now” enqueues immediately

### Execution model

* A background job launches rclone as a subprocess
* rclone runs independently of Ruby
* The job:

  * captures stdout/stderr
  * appends logs to `raw_log`
  * records PID
  * waits for completion
  * stores exit code and status

### rclone configuration

* Temporary rclone config generated from Provider credentials
* Deleted after run
* Fixed flags (v1), e.g.:

  * `--stats`
  * `--stats-one-line`
  * `--log-level INFO`
* **Server-side copy disabled**

---

## 8. Logging & Monitoring

### Logs

* Store full raw rclone output per Backup Run
* Display logs in UI (monospace, scrollable)

### Status

* Success determined by exit code = 0
* Failure otherwise

---

## 9. UI Requirements

### Main sections

* Providers
* Storages
* Backups
* Health

### Backups list

* Name
* Source → Destination
* Schedule
* Last run status
* Last run time
* Enable/disable toggle

### Backup detail

* Backup config
* “Run backup now” button
* Last 30 days run history (green/red)
* Recent Backup Runs list

### Backup Run detail

* Status
* Start/end time
* Exit code
* Full raw logs

---

## 10. Notifications

### v1

* Send email when a Backup Run fails
* One email per failure
* Single global notification address

---

## 11. Instance Health Panel

Display basic system health:

* CPU usage / load average
* Memory used / total
* Disk usage
* Uptime
* Number of running Backup Runs
* Queue depth (pending jobs)

If a Backup Run is active and has a PID:

* Show rclone process CPU and memory usage (best-effort)

---

## 12. Security

* Encrypt provider credentials at rest
* Never log secrets
* Delete temporary config files after runs
* No public endpoints

---

## 13. Deployment Assumptions

* Linux VPS
* rclone installed system-wide
* 1–2 GB RAM sufficient
* Expected cost: $5–15/month

---

## 14. Acceptance Criteria (MVP)

* Providers can be created and edited
* Buckets can be discovered and imported
* Backups can be created between storages
* Backups run on schedule and manually
* Logs are captured and viewable
* Failures trigger email notifications
* Backup history is visible
* Health panel loads and updates

---

## 15. Design Philosophy

* Prefer clarity over flexibility
* Prefer backup-centric language over technical jargon
* Avoid premature abstraction
* Make failure visible and understandable

