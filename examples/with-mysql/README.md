# Dolibarr with MySQL

This example demonstrates how to run a **Dolibarr** instance alongside a **MySQL** server using Docker Compose. This setup reflects a typical deployment architecture.

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