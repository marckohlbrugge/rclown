# Rclown 🤡

A friendly web UI for backing up your object storage buckets.

Rclown wraps the battle-tested [rclone](https://rclone.org/) in a simple interface. Schedule backups, see what's happening, get notified when something breaks. Supports Cloudflare R2, Backblaze B2, Amazon S3, and other S3-compatible providers.

## Features

- **Multi-provider support**: Cloudflare R2, Backblaze B2, Amazon S3
- **Bucket discovery**: Automatically find and import buckets from your providers
- **Scheduled backups**: Daily or weekly, with dry-run support
- **Live logs**: Stream backup progress in real-time
- **Failure notifications**: Email alerts when backups fail
- **System health**: Monitor CPU, memory, disk usage, and queue status

## Deployment

Rclown is a Rails application designed for self-hosting. You'll need:
- Ruby 3.3+
- SQLite
- [rclone](https://rclone.org/) installed on the server

### Environment Variables

```bash
# Required: Active Record Encryption keys (generate with: bin/rails db:encryption:init)
ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=your-primary-key
ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=your-deterministic-key
ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=your-salt

# Required: HTTP Basic Auth
ADMIN_USERNAME=admin
ADMIN_PASSWORD=your-secure-password

# Optional: Email notifications
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_USERNAME=your-username
SMTP_PASSWORD=your-password
NOTIFICATION_EMAIL=alerts@example.com
```

### Docker

Coming soon.

### Kamal

Coming soon.

## Development

```bash
git clone https://github.com/marckohlbrugge/rclown.git
cd rclown
bundle install
bin/rails db:setup
bin/dev
```

## Contributing

Bug fixes and small improvements are welcome as pull requests. For larger changes or new features, please open an issue first to discuss the approach.

## License

See [LICENSE](LICENSE) for details.
