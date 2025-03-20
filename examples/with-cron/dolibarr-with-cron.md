# Dolibarr with cron

To ensure that the "Scheduled Tasks" module works properly, it's essential to enable cron on the Dolibarr container. This requires two Dolibarr instances: the primary Dolibarr container and an additional container dedicated solely to running cron jobs. Use the provided `docker-compose.yml` to easily set up this architecture.