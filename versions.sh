#!/bin/bash

set -e

# The list of version to build docker packages for
DOLIBARR_VERSIONS=("19.0.4" "20.0.4" "21.0.4" "22.0.5" "23.0.4" "24.0.4" "develop")

# The version to use when installing dolibarr/dolibarr:latest
# Derived automatically: the highest X.Y.Z entry of DOLIBARR_VERSIONS
DOLIBARR_LATEST_TAG="$(printf '%s\n' "${DOLIBARR_VERSIONS[@]}" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | sort -t. -k1,1n -k2,2n -k3,3n | tail -n1)"

# The version to use to find the dump file for the init of demo with branch "develop"
# Derived automatically: the X.Y of DOLIBARR_LATEST_TAG
DOLIBARR_VERSION_FOR_INIT_DEMO="${DOLIBARR_LATEST_TAG%.*}"
