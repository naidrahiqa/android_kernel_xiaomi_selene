#!/bin/bash
# Extract ReSukiSU version info from Kbuild
# Usage: source get_ksu_info.sh
# Exports: KSU_VERSION_NUM, KSU_TAG, KSU_COMMIT, KSU_BRANCH

KBUILD="resukisu/kernel/Kbuild"

if [ ! -f "$KBUILD" ]; then
	KBUILD="$(dirname "$0")/../../resukisu/kernel/Kbuild"
fi

if [ ! -f "$KBUILD" ]; then
	echo "ERROR: Kbuild not found" >&2
	KSU_VERSION_NUM=0
	KSU_TAG="unknown"
	KSU_COMMIT="unknown"
	KSU_BRANCH="unknown"
	return 1 2>/dev/null || exit 1
fi

# Extract values
KSU_LOCAL_VER=$(grep '^KSU_LOCAL_VERSION' "$KBUILD" | head -1 | sed 's/.*:= *//')
KSU_TAG=$(grep '^KSU_TAG_NAME' "$KBUILD" | head -1 | sed 's/.*:= *//')
KSU_COMMIT=$(grep '^KSU_COMMIT_SHA' "$KBUILD" | head -1 | sed 's/.*:= *//')
KSU_BRANCH=$(grep '^KSU_BRANCH_NAME' "$KBUILD" | head -1 | sed 's/.*:= *//')

# Calculate KSU_VERSION = 30000 + LOCAL + 700
if [ -n "$KSU_LOCAL_VER" ]; then
	KSU_VERSION_NUM=$((30000 + KSU_LOCAL_VER + 700))
else
	KSU_VERSION_NUM=0
fi

export KSU_VERSION_NUM
export KSU_TAG
export KSU_COMMIT
export KSU_BRANCH

echo "KSU_VERSION_NUM=$KSU_VERSION_NUM"
echo "KSU_TAG=$KSU_TAG"
echo "KSU_COMMIT=$KSU_COMMIT"
echo "KSU_BRANCH=$KSU_BRANCH"
