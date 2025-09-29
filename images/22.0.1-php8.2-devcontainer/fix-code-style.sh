#!/bin/bash
# Fix code style issues
echo "🔧 Fixing code style issues..."
docker exec dolibarr-dev-app dolibarr-dev cs-fix
