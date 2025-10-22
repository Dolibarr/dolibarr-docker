#!/bin/bash
# Run Dolibarr tests
echo "Running PHPUnit tests..."
docker exec dolibarr-dev-app bash -c "cd /var/www/html && phpunit --configuration phpunit.xml"
