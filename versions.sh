#!/bin/bash

set -e

# The list of version to build docker packages for
DOLIBARR_VERSIONS=("15.0.3" "16.0.5" "17.0.4" "18.0.5" "19.0.3" "develop")

# The version to use when installing dolibarr/dolibarr:latest
DOLIBARR_LATEST_TAG="19.0.3"

# The version to use to find the dump file for init of demo
DOLIBARR_VERSION_FOR_INIT_DEMO="20.0"
