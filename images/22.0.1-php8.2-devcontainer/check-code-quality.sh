#!/bin/bash
# Check code quality for Dolibarr
echo "Running code quality checks..."

echo "Running PHPCS (Code Sniffer)..."
docker exec dolibarr-dev-app dolibarr-dev cs-check

echo "Running PHPStan (Static Analysis)..."
docker exec dolibarr-dev-app dolibarr-dev stan
