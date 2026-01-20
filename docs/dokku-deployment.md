## Deploying with Dokku

This guide covers deploying Rclown to a server running [Dokku](https://dokku.com/).

### 1. Install Dokku

Follow the quick-start instructions [here](https://dokku.com/) to install Dokku on your server.

### 2. Create Rclown as a Dokku app

Run the following script which will create Rclown as a Dokku app, and make a fix to the permissions for the directory it runs in to make it compatible with Dokku:

```bash
dokku apps:create rclown

# Configure exposed ports - use any host-port you'd like. Mapping format is protocol:host-port:container-port
dokku ports:add rclown http:80:80

# Configure mounted storage
sudo -u dokku mkdir -p /var/lib/dokku/data/storage/rclown/rclown
dokku storage:mount rclown /var/lib/dokku/data/storage/rclown/rclown:/rails/storage

# IMPORTANT: Manually fix mounted dir permissions since Rclown uses uid 1000 for security reasons
sudo chown -R 1000:1000 /var/lib/dokku/data/storage/rclown/rclown
```

### 3. Configure required environment variables (and any others you'd like to change)
```
# Make sure to set these environment variables:
dokku config:set --no-restart rclown SECRET_KEY_BASE="$(openssl rand -hex 64)"
dokku config:set --no-restart rclown DISABLE_SSL="true"

# HTTP Basic Auth (required)
dokku config:set --no-restart rclown HTTP_AUTH_USERNAME="admin"
dokku config:set --no-restart rclown HTTP_AUTH_PASSWORD="your-secure-password"

# Optional: Email notifications
# dokku config:set --no-restart rclown NOTIFICATION_EMAIL="alerts@example.com"
```

### 4. Deploy

For the initial deployment:

```sh
dokku git:from-image rclown ghcr.io/marckohlbrugge/rclown:main
```

Configure Dokku to always pull the latest image when rebuilding:

```sh
dokku docker-options:add rclown build "--pull --no-cache"
```

### 5. Update to Latest Version

To update Rclown to the latest version:

```sh
dokku ps:rebuild rclown
```
