#!/bin/bash
#
# Run this script to generate all files (Dockerfile, docker-init.php, docker-run.php) found into images directory, 
# used for each image. The source files are the files into the root.
#

set -e

DOCKER_BUILD=${DOCKER_BUILD:-0}
DOCKER_PUSH=${DOCKER_PUSH:-0}

BASE_DIR="$( cd "$(dirname "$0")" && pwd )"

source "${BASE_DIR}/versions.sh"

tags=""

# First, clean the directory /images
if [ -f "${BASE_DIR}/images/README.md" ]; then
	cp -f "${BASE_DIR}/images/README.md" "/tmp/tmp-README.md"
fi
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

  # Mapping PHP version according to Dolibarr version (See https://wiki.dolibarr.org/index.php/Versions)
  # Regarding PHP Supported version : https://www.php.net/supported-versions.php
  if [ "${dolibarrVersion}" = "develop" ] || [ "${dolibarrMajor}" -ge "19" ] || [ "${dolibarrMajor}" -ge "20" ] || [ "${dolibarrMajor}" -ge "21" ]; then
    php_base_images=( "8.2-apache-bullseye" )
  elif [ "${dolibarrMajor}" -ge "16" ]; then
    php_base_images=( "8.1-apache-bullseye" )
  else
    php_base_images=( "7.4-apache-bullseye" )
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

	# Set DOLI_VERSION_FOR_INIT_DEMO to x.y version
	if [ ${dolibarrVersion} != "develop" ]; then
		DOLI_VERSION_FOR_INIT_DEMO=$(echo "${dolibarrVersion}" | sed 's/\(\.[^\.]*\)\.[^\.]*$/\1/')
	else
		DOLI_VERSION_FOR_INIT_DEMO=$DOLIBARR_VERSION_FOR_INIT_DEMO
	fi

	echo "Replace Dockerfile.template with DOLI_VERSION_FOR_INIT_DEMO=$DOLI_VERSION_FOR_INIT_DEMO"
    mkdir -p "${dir}"
    sed 's/%PHP_BASE_IMAGE%/'"${php_base_image}"'/;' "${BASE_DIR}/Dockerfile.template" | \
    sed 's/%DOLI_VERSION%/'"${dolibarrVersion}"'/;' | \
    sed 's/%DOLI_VERSION_FOR_INIT_DEMO%/'"${DOLI_VERSION_FOR_INIT_DEMO}"'/;' \
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


if [ -f "/tmp/tmp-README.md" ]; then
	mv "/tmp/tmp-README.md" "${BASE_DIR}/images/README.md"
fi
