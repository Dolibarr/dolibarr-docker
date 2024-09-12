#!/bin/bash
#
# Run this script to generate all files found into images directory, used for each image.
# The source files are the files into the root.
#

set -e

DOCKER_BUILD=${DOCKER_BUILD:-0}
DOCKER_PUSH=${DOCKER_PUSH:-0}

BASE_DIR="$( cd "$(dirname "$0")" && pwd )"

VARIANTS=( apache-buster fpm )
DEFAULT_VARIANT="apache-buster"
declare -A VARIANTS_EXTRAS=(
  [apache-buster]="RUN sed -i \
-e 's/^\(ServerSignature On\)\$/#\1/g' \
-e 's/^#\(ServerSignature Off\)\$/\1/g' \
-e 's/^\(ServerTokens\) OS\$/\1 Prod/g' \
/etc/apache2/conf-available/security.conf"
  [fpm]=""
)
declare -A VARIANTS_CMD=(
  [apache-buster]=apache2-foreground
  [fpm]=php-fpm
)
declare -A VARIANTS_EXPOSE=(
  [apache-buster]="80"
  [fpm]="9000"
)

source "${BASE_DIR}/versions.sh"

tags=""

# First, clean the directory /images
if [ -f "${BASE_DIR}/images/README.md" ]; then
	mv "${BASE_DIR}/images/README.md" "/tmp/tmp-README.md"
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

  # Mapping version according https://wiki.dolibarr.org/index.php/Versions
  # Regarding PHP Supported version : https://www.php.net/supported-versions.php
  if [ "${dolibarrVersion}" = "develop" ] || [ "${dolibarrMajor}" -ge "19" ] || [ "${dolibarrMajor}" -ge "20" ]; then
    phpVersions=( "8.2" )
  elif [ "${dolibarrMajor}" -ge "16" ]; then
    phpVersions=( "8.1" )
  else
    phpVersions=( "7.4" )
  fi

  for phpVersion in "${phpVersions[@]}"; do
    for imageVariant in "${VARIANTS[@]}"; do
      echo "- Variant $imageVariant"
      phpBaseImage="$phpVersion-$imageVariant"

      if [ "${dolibarrVersion}" = "develop" ]; then
        currentTag="${dolibarrVersion}"
      else
        currentTag="${dolibarrVersion}-php${phpVersion}"

        if [ "$imageVariant" != "$DEFAULT_VARIANT" ]; then
          currentTag+="-$imageVariant"
        fi

        tags="${tags} ${currentTag}"
      fi

      buildOptionTags="--tag dolibarr/dolibarr:${currentTag}"
      if [ "${dolibarrVersion}" != "develop" ]; then
        if [ "$imageVariant" = "$DEFAULT_VARIANT" ]; then
          buildOptionTags="${buildOptionTags} --tag dolibarr/dolibarr:${dolibarrVersion} --tag dolibarr/dolibarr:${dolibarrMajor}"
        else
          buildOptionTags="${buildOptionTags} --tag dolibarr/dolibarr:${dolibarrVersion}-${imageVariant} --tag dolibarr/dolibarr:${dolibarrMajor}-${imageVariant}"
        fi
      fi
      if [ "${dolibarrVersion}" = "${DOLIBARR_LATEST_TAG}" ]; then
        if [ "$imageVariant" = "$DEFAULT_VARIANT" ]; then
          buildOptionTags="${buildOptionTags} --tag dolibarr/dolibarr:latest"
        else
          buildOptionTags="${buildOptionTags} --tag dolibarr/dolibarr:latest-${imageVariant}"
        fi
      fi

      dir="${BASE_DIR}/images/${dolibarrVersion}/${imageVariant}"

      mkdir -p "${dir}"
      sed 's/%PHP_BASE_IMAGE%/'"${phpBaseImage}"'/;' "${BASE_DIR}/Dockerfile.template" | \
      sed 's/%DOLI_VERSION%/'"${dolibarrVersion}"'/;' | \
      sed 's~%EXTRAS%~'"$(sed 's/[&/\]/\\&/g' <<< "${VARIANTS_EXTRAS[$imageVariant]}")"'~;' | \
      sed 's/%EXPOSE%/'"${VARIANTS_EXPOSE[$imageVariant]}"'/;' | \
      sed 's/%CMD%/'"${VARIANTS_CMD[$imageVariant]}"'/;' \
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


sed 's/%TAGS%/'"${tags}"'/' "${BASE_DIR}/README.template" > "${BASE_DIR}/README.md"
