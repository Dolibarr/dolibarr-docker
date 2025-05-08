# Adding a reverse proxy in front of Dolibarr such as Traefik

The Reverse proxy role is to handle the customer facing : SSL, load balancing, page caching, etc...
Traefik is a reverse proxy light, fast and reliable.
Here is the documentation for Traefik: https://doc.traefik.io/traefik/

## Networking
 - The proxy is facing the customer and providing the SSL support in front of Dolibarr.
 - The mysql server is isolated from the internet.
 - Dolibarr needs internet access for some feature (mail, update checks, SIRET checks, etc..)
