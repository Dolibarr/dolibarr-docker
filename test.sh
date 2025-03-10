#!/bin/bash
# Script to build and tests Dolibarr Docker images.
#
# Usage:
# sudo test.sh develop
# sudo test.sh 18.0.5 php8.1
#

set -e

BASE_DIR="$( cd "$(dirname "$0")" && pwd )"

DOLI_VER=${1}
PHP_VER=${2:-""}

if [ "${DOLI_VER}" = "" ]; then
	echo "Usage:   sudo test.sh dolversion [phpversion]"
	echo "         The couple dolversion/phpversion must be an existing couple into /images directory."
	echo "Example: sudo test.sh develop"
	echo "         sudo test.sh 18.0.5 8.1"
	exit
fi

rm -rf "${BASE_DIR}/docker-compose-links/" && mkdir "${BASE_DIR}/docker-compose-links"

# shellcheck disable=SC2044
for directory in $(find "${BASE_DIR}/images" -maxdepth 1 -mindepth 1 -type d -printf '%f\n'); do
  dolibarrVersion=$(echo "${directory}" | cut -d\- -f1)
  phpVersion=$(echo "${directory}" | cut -d\- -f2)

  #dolibarrMajor=$(echo "${dolibarrVersion}" | cut -d. -f1)
  phpMajor=$(echo "${phpVersion}" | cut -d. -f1)

  ln -nfs "${BASE_DIR}/images/${directory}" "${BASE_DIR}/docker-compose-links/${directory}"
  if [ "${phpMajor}" = "php7" ]; then
    ln -nfs "${BASE_DIR}/images/${directory}" "${BASE_DIR}/docker-compose-links/${dolibarrVersion}"
  fi
done

if which docker-compose > /dev/null; then
  dockerComposeBin="docker-compose"
else
  dockerComposeBin="docker compose"
fi

echo "Testing for:"
echo " - Dolibarr ${DOLI_VER}"
if [ "${PHP_VER}" = "" ]; then
  echo " - PHP most recent"
  echo "Stopping existing image (if exists) ..."
  echo "DOLI_VERSION=${DOLI_VER} PHP_VERSION='' $dockerComposeBin -f '${BASE_DIR}/docker-compose.yml' [down|...]"
  DOLI_VERSION=${DOLI_VER} PHP_VERSION="" $dockerComposeBin -f "${BASE_DIR}/docker-compose.yml" down 1>/dev/null
  echo "Building image ..."
  DOLI_VERSION=${DOLI_VER} PHP_VERSION="" $dockerComposeBin -f "${BASE_DIR}/docker-compose.yml" build web
  echo "Starting image ..."
  DOLI_VERSION=${DOLI_VER} PHP_VERSION="" $dockerComposeBin -f "${BASE_DIR}/docker-compose.yml" up --force-recreate web cron
  echo "Stopping image ..."
  DOLI_VERSION=${DOLI_VER} PHP_VERSION="" $dockerComposeBin -f "${BASE_DIR}/docker-compose.yml" down
else
  echo " - PHP ${PHP_VER}"
  echo "Stopping existing image (if exists) ..."
  DOLI_VERSION=${DOLI_VER} PHP_VERSION="-php${PHP_VER}" $dockerComposeBin -f "${BASE_DIR}/docker-compose.yml" down 1>/dev/null
  echo "Building image ..."
  DOLI_VERSION=${DOLI_VER} PHP_VERSION="-php${PHP_VER}" $dockerComposeBin -f "${BASE_DIR}/docker-compose.yml" build web
  echo "Starting image ..."
  DOLI_VERSION=${DOLI_VER} PHP_VERSION="-php${PHP_VER}" $dockerComposeBin -f "${BASE_DIR}/docker-compose.yml" up --force-recreate web cron
  echo "Stopping image ..."
  DOLI_VERSION=${DOLI_VER} PHP_VERSION="-php${PHP_VER}" $dockerComposeBin -f "${BASE_DIR}/docker-compose.yml" down
fi
