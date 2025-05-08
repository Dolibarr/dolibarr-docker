# Dolibarr with PostgreSQL

This example demonstrates how to run a **Dolibarr** instance connected to a **PostgreSQL** server using Docker Compose. Unlike the default MySQL setup, PostgreSQL support is relatively new and requires manual installation during the first run.

## First-Time Setup Instructions

When using the `pgsql` database driver, Dolibarr cannot auto-install on startup. You must complete the installation manually:

1. Open your browser and navigate to:
   `http://0.0.0.0/install`
2. Follow the on-screen installation steps.
3. After installation, create the `install.lock` file inside the container to prevent reinstall prompts:

   ```bash
   docker-compose exec services-data_dolibarr_1 /bin/bash -c "touch /var/www/html/documents/install.lock"
   ```

## Environment Variables

To ensure the setup works correctly, you must configure the `.env` file in this directory. Below are the environment variables that must be changed:

```env
# Add a random 16-character ASCII string
DOLI_CRON_KEY=

# Add a unique 16-character ASCII string for this instance
DOLI_INSTANCE_UNIQUE_ID=

# Root password for the MySQL database (use a secure value)
ROOT_DB_PASSWORD=
```

> [!IMPORTANT]
> The `.env` file must be populated before running `docker-compose up`, otherwise the containers may fail to initialize properly.