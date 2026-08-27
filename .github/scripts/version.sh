#!/bin/bash
# Version Management - Phrolova Kernel
# Usage: source version.sh [variant] [base_version]
#
# Variants:
#   0 = nightly  → v{base}-nightly.YYYYMMDD  (base defaults to 0.1.0)
#   1 = stable   → v{base}
#   2 = hotfix   → v{base+1}
#
# base_version: bump when adding features (e.g. 0.2.0, 0.3.0, 1.0.0)

VARIANT="${1%% *}"  # Strip trailing text from workflow_dispatch choice (e.g. "0 — Nightly" -> "0")
VARIANT="${VARIANT:-0}"
BASE_VERSION="${2:-0.9.5}"
DATE_TAG=$(date +%Y%m%d)

case "$VARIANT" in
	0)
		PHROLOVA_VERSION="v${BASE_VERSION}-nightly.${DATE_TAG}"
		PHROLOVA_VARIANT_NAME="nightly"
		;;
	1)
		PHROLOVA_VERSION="v${BASE_VERSION}"
		PHROLOVA_VARIANT_NAME="stable"
		;;
	2)
		MAJOR=$(echo "$BASE_VERSION" | cut -d. -f1)
		MINOR=$(echo "$BASE_VERSION" | cut -d. -f2)
		PATCH=$(echo "$BASE_VERSION" | cut -d. -f3)
		PHROLOVA_VERSION="v${MAJOR}.${MINOR}.$((PATCH + 1))"
		PHROLOVA_VARIANT_NAME="hotfix"
		;;
	*)
		echo "Unknown variant: $VARIANT (0=nightly, 1=stable, 2=hotfix)"
		exit 1
		;;
esac

PHROLOVA_TAG="${PHROLOVA_VERSION}"

export PHROLOVA_VERSION
export PHROLOVA_TAG
export PHROLOVA_VARIANT_NAME
export PHROLOVA_BASE="4.14"
export PHROLOVA_CODENAME="Phrolova"

export LOCALVERSION="-Phrolova-${PHROLOVA_VERSION}"
export RELEASE_DATE=$(date +"%d %B %Y")
export RELEASE_TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
