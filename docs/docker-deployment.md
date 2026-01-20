## Deploying with Docker

We provide pre-built Docker images that can be used to run Rclown on your own server.

If you don't need to change the source code, and just want the out-of-the-box Rclown experience, this can be a great way to get started.

You'll find the latest version of Rclown's Docker image at `ghcr.io/marckohlbrugge/rclown:main`.
To run it you'll need three things: a machine that runs Docker; a mounted volume (so that your database is stored somewhere that is kept around between restarts); and some environment variables for configuration.

### Mounting a storage volume

The standard Rclown setup keeps all of its storage inside the path `/rails/storage`.
By default Docker containers don't persist storage between runs, so you'll want to mount a persistent volume into that location.

The simplest way to do this is with the `--volume` flag with `docker run`. For example:

```sh
docker run --volume rclown:/rails/storage ghcr.io/marckohlbrugge/rclown:main
```

That will create a named volume (called `rclown`) and mount it into the correct path.
Docker will manage where that volume is actually stored on your server.

You can also specify the data location yourself, mount a network drive, and more.
Check the Docker documentation to find out more about what's available.

### Configuring with environment variables

To configure your Rclown installation, you can use environment variables.
Many of these are optional, but at a minimum you'll want to configure your secret key.

#### Secret Key Base

Various features inside Rclown rely on cryptography to work.
To set this up, you need to provide a secret value that will be used as the basis of those secrets.
This value can be anything, but it should be unguessable, and specific to your instance.

You can generate a random key with:

```sh
openssl rand -hex 64
```

Once you have one, set it in the `SECRET_KEY_BASE` environment variable:

```sh
docker run --environment SECRET_KEY_BASE=abcdefabcdef ...
```

#### SSL

By default, Rclown assumes it's running behind an SSL-terminating proxy and enforces HTTPS.

If you're running Rclown behind a reverse proxy that handles SSL (like Cloudflare, nginx, or Caddy), you don't need to change anything.

If you aren't using SSL at all (for example, if you want to run it locally on your laptop) then you should specify `DISABLE_SSL=true`:

```sh
docker run --publish 80:80 --environment DISABLE_SSL=true ...
```

#### HTTP Basic Auth

Rclown should be protected with HTTP Basic Authentication. This is required for production deployments to prevent unauthorized access to your backup configurations and credentials.

Set the `HTTP_AUTH_USERNAME` and `HTTP_AUTH_PASSWORD` environment variables:

```sh
docker run \
  --environment HTTP_AUTH_USERNAME=admin \
  --environment HTTP_AUTH_PASSWORD=your-secure-password \
  ...
```

When both variables are set, Rclown will require authentication to access the dashboard.

#### Email Notifications

Rclown can send email notifications when backups fail. Configure SMTP settings via Rails credentials or environment variables:

```sh
docker run \
  --environment NOTIFICATION_EMAIL=alerts@example.com \
  ...
```

SMTP settings should be configured in your Rails credentials file.

## Example

Here's an example of a `docker-compose.yml` that you could use to run Rclown via `docker compose up`:

```yaml
services:
  web:
    image: ghcr.io/marckohlbrugge/rclown:main
    restart: unless-stopped
    ports:
      - "80:80"
    environment:
      - SECRET_KEY_BASE=your-secret-key-here
      - HTTP_AUTH_USERNAME=admin
      - HTTP_AUTH_PASSWORD=your-secure-password
      - DISABLE_SSL=true
    volumes:
      - rclown:/rails/storage

volumes:
  rclown:
```

For production with SSL handled by a reverse proxy:

```yaml
services:
  web:
    image: ghcr.io/marckohlbrugge/rclown:main
    restart: unless-stopped
    ports:
      - "80:80"
    environment:
      - SECRET_KEY_BASE=your-secret-key-here
      - HTTP_AUTH_USERNAME=admin
      - HTTP_AUTH_PASSWORD=your-secure-password
    volumes:
      - rclown:/rails/storage

volumes:
  rclown:
```
