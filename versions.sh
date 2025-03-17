#!/bin/bash

set -e

# The list of version to build docker packages for
DOLIBARR_VERSIONS=("21.0.0")

# The version to use when installing dolibarr/dolibarr:latest
DOLIBARR_LATEST_TAG="21.0.0"

# The version to use to find the dump file for the init of demo with branch "develop"
DOLIBARR_VERSION_FOR_INIT_DEMO="21.0"
