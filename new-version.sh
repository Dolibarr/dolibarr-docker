#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./new-version.sh 22.0.4

NEW_VERSION="${1:-}"
FILE="versions.sh"

if [[ -z "${NEW_VERSION}" ]]; then
	echo "Usage: $0 <semver-version>" >&2
	exit 1
fi

# Basic semver check: X.Y.Z (digits only)
if [[ ! "${NEW_VERSION}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
	echo "Error: version must be in semver format X.Y.Z (digits only), got '${NEW_VERSION}'" >&2
	exit 1
fi

# Load the current values from the file (we trust this file)
# shellcheck disable=SC1090
source "${FILE}"

# Parse provided version
NEW_MAJOR="$(cut -d. -f1 <<< "${NEW_VERSION}")"
NEW_MINOR="$(cut -d. -f2 <<< "${NEW_VERSION}")"
NEW_PATCH="$(cut -d. -f3 <<< "${NEW_VERSION}")"

# Parse current latest for comparison
CUR_MAJOR="$(cut -d. -f1 <<< "${DOLIBARR_LATEST_TAG}")"
CUR_MINOR="$(cut -d. -f2 <<< "${DOLIBARR_LATEST_TAG}")"
CUR_PATCH="$(cut -d. -f3 <<< "${DOLIBARR_LATEST_TAG}")"

# Define DOLIBARR_LATEST_TAG/DOLIBARR_VERSION_FOR_INIT_DEMO
NEW_DOLIBARR_LATEST_TAG="${DOLIBARR_LATEST_TAG}"
NEW_DOLIBARR_VERSION_FOR_INIT_DEMO="${CUR_MAJOR}.${CUR_MINOR}"

# Decide whether we need to update LATEST_TAG + INIT_DEMO
if (( NEW_MAJOR > CUR_MAJOR )); then
  NEW_DOLIBARR_LATEST_TAG="${NEW_VERSION}"
  NEW_DOLIBARR_VERSION_FOR_INIT_DEMO="${NEW_MAJOR}.${NEW_MINOR}"
elif (( NEW_MAJOR == CUR_MAJOR && NEW_MINOR > CUR_MINOR )); then
  NEW_DOLIBARR_LATEST_TAG="${NEW_VERSION}"
  NEW_DOLIBARR_VERSION_FOR_INIT_DEMO="${NEW_MAJOR}.${NEW_MINOR}"
elif (( NEW_MAJOR == CUR_MAJOR && NEW_MINOR == CUR_MINOR && NEW_PATCH >= CUR_PATCH )); then
  NEW_DOLIBARR_LATEST_TAG="${NEW_VERSION}"
  NEW_DOLIBARR_VERSION_FOR_INIT_DEMO="${NEW_MAJOR}.${NEW_MINOR}"
fi

# Find an existing entry in DOLIBARR_VERSIONS with the same major (XX.*.*)
existing_index=-1
develop_index=-1

for i in "${!DOLIBARR_VERSIONS[@]}"; do
	v="${DOLIBARR_VERSIONS[$i]}"
	if [[ "${v}" == "develop" ]]; then
		develop_index="${i}"
		continue
	fi

	v_major="${v%%.*}"
	if [[ "${v_major}" == "${NEW_MAJOR}" ]]; then
		existing_index="${i}"
		break
	fi
done

# Build a new array with updated / inserted version
declare -a NEW_DOLIBARR_VERSIONS=()

if [[ "${existing_index}" -ge 0 ]]; then
	# Replace the version with the same major
	for i in "${!DOLIBARR_VERSIONS[@]}"; do
		if [[ "${i}" -eq "${existing_index}" ]]; then
			NEW_DOLIBARR_VERSIONS+=("${NEW_VERSION}")
		else
			NEW_DOLIBARR_VERSIONS+=("${DOLIBARR_VERSIONS[$i]}")
		fi
	done
else
	# No existing major: insert NEW_VERSION before "develop"
	for i in "${!DOLIBARR_VERSIONS[@]}"; do
		if [[ "${i}" -eq "${develop_index}" ]]; then
			# Insert new version before "develop"
			NEW_DOLIBARR_VERSIONS+=("${NEW_VERSION}")
		fi
		NEW_DOLIBARR_VERSIONS+=("${DOLIBARR_VERSIONS[$i]}")
	done
fi

# Build the line for DOLIBARR_VERSIONS=(...)
versions_line='DOLIBARR_VERSIONS=('
for v in "${NEW_DOLIBARR_VERSIONS[@]}"; do
	versions_line+='"'"${v}"'" '
done
versions_line=${versions_line%" "} # trim trailing space
versions_line+=')'

# Now output the file
while IFS= read -r line; do
	case "${line}" in
	DOLIBARR_VERSIONS=\(*)
		echo "${versions_line}"
		;;
	DOLIBARR_LATEST_TAG=*)
		echo "DOLIBARR_LATEST_TAG=\"${NEW_DOLIBARR_LATEST_TAG}\""
		;;
	DOLIBARR_VERSION_FOR_INIT_DEMO=*)
		echo "DOLIBARR_VERSION_FOR_INIT_DEMO=\"${NEW_DOLIBARR_VERSION_FOR_INIT_DEMO}\""
		;;
	*)
		echo "${line}"
		;;
	esac
done <"${FILE}"
