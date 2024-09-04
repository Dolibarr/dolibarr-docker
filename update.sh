#!/bin/bash
#
# Run this script to generate all files found into images directory, used for each image.
# The source files are the files into the root.
# 

set -e

DOCKER_BUILD=${DOCKER_BUILD:-0}
DOCKER_PUSH=${DOCKER_PUSH:-0}

BASE_DIR="$( cd "$(dirname "$0")" && pwd )"

source "${BASE_DIR}/versions.sh"

tags=""

rm -rf "${BASE_DIR}/images" "${BASE_DIR}/docker-compose-links"

if [ "${DOCKER_BUILD}" = "1" ] && [ "${DOCKER_PUSH}" = "1" ]; then
  docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
  docker buildx create --driver docker-container --use
  docker buildx inspect --bootstrap
fi

for dolibarrVersion in "${DOLIBARR_VERSIONS[@]}"; do
  echo "Generate Dockerfile for Dolibarr ${dolibarrVersion}"

  tags="${tags}\n\*"
  dolibarrMajor=$(echo ${dolibarrVersion} | cut -d. -f1)

  # Mapping version according https://wiki.dolibarr.org/index.php/Versions
  # Regarding PHP Supported version : https://www.php.net/supported-versions.php
  if [ "${dolibarrVersion}" = "develop" ] || [ "${dolibarrMajor}" -ge "19" ] || [ "${dolibarrMajor}" -ge "20" ]; then
    php_base_images=( "8.2-apache-buster" )
  elif [ "${dolibarrMajor}" -ge "16" ]; then
    php_base_images=( "8.1-apache-buster" )
  else
    php_base_images=( "7.4-apache-buster" )
  fi

  for php_base_image in "${php_base_images[@]}"; do
    php_version=$(echo "${php_base_image}" | cut -d\- -f1)

    if [ "${dolibarrVersion}" = "develop" ]; then
      currentTag="${dolibarrVersion}"
    else
      currentTag="${dolibarrVersion}-php${php_version}"
      tags="${tags} ${currentTag}"
    fi

    buildOptionTags="--tag dolibarr/dolibarr:${currentTag}"
    if [ "${dolibarrVersion}" != "develop" ]; then
      buildOptionTags="${buildOptionTags} --tag dolibarr/dolibarr:${dolibarrVersion} --tag dolibarr/dolibarr:${dolibarrMajor}"
    fi
    if [ "${dolibarrVersion}" = "${DOLIBARR_LATEST_TAG}" ]; then
      buildOptionTags="${buildOptionTags} --tag dolibarr/dolibarr:latest"
    fi

    dir="${BASE_DIR}/images/${currentTag}"

    mkdir -p "${dir}"
    sed 's/%PHP_BASE_IMAGE%/'"${php_base_image}"'/;' "${BASE_DIR}/Dockerfile.template" | \
    sed 's/%DOLI_VERSION%/'"${dolibarrVersion}"'/;' \
    > "${dir}/Dockerfile"

    cp -a "${BASE_DIR}/docker-init.php" "${dir}/docker-init.php"
    cp -a "${BASE_DIR}/docker-run.sh" "${dir}/docker-run.sh"

    if [ "${DOCKER_BUILD}" = "1" ]; then
      if [ "${DOCKER_PUSH}" = "1" ]; then
        docker buildx build \
          --push \
          --compress \
          --platform linux/arm/v7,linux/arm64,linux/amd64 \
          ${buildOptionTags} \
          "${dir}"
      else
        docker build \
          --compress \
          ${buildOptionTags} \
          "${dir}"
      fi
    fi
  done

  if [ "${dolibarrVersion}" = "develop" ]; then
    tags="${tags} develop"
  else
    tags="${tags} ${dolibarrVersion} ${dolibarrMajor}"
  fi
  if [ "${dolibarrVersion}" = "${DOLIBARR_LATEST_TAG}" ]; then
    tags="${tags} latest"
  fi
done

sed 's/%TAGS%/'"${tags}"'/' "${BASE_DIR}/README.template" > "${BASE_DIR}/README.md"
