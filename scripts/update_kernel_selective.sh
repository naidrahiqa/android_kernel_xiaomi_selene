#!/bin/bash
# update_kernel_selective.sh — Selective kernel update for 4.14.x
# Usage: bash scripts/update_kernel_selective.sh [repo_path] [target_version]
#
# Compares our tree vs vanilla 4.14.186. If identical → replace with target.
# If different (Xiaomi modified) → skip.
#
# Examples:
#   bash scripts/update_kernel_selective.sh . 4.14.349
#   bash scripts/update_kernel_selective.sh . 4.14.336
set -uo pipefail

REPO="${1:-.}"
TARGET="${2:-4.14.349}"

# Parse target
MAJOR=$(echo "$TARGET" | cut -d. -f1)
MINOR=$(echo "$TARGET" | cut -d. -f2)
SUBLEVEL=$(echo "$TARGET" | cut -d. -f3)

if [ "$MAJOR" != "4" ] || [ "$MINOR" != "14" ]; then
  echo "ERROR: Only 4.14.x versions are supported."
  exit 1
fi
if [ "$SUBLEVEL" -gt 350 ]; then
  echo "WARNING: 4.14.357+ has blank screen issue on MTK devices."
  echo "Recommended: use ≤4.14.349. Continue anyway? [y/N]"
  read -r ans
  [ "$ans" = "y" ] || exit 1
fi

WORKDIR="/tmp/kernel-update-work"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

OLD_TAR="linux-4.14.186.tar.xz"
OLD_DIR="linux-4.14.186"
REPO_ABS="$(cd "$REPO" && pwd)"

# ── Step 1: Download tarballs ──────────────────────────────────
echo "=== Step 1: Download kernel sources ==="
echo "  Target: Linux $TARGET"

if [ ! -f "$OLD_TAR" ]; then
  echo "  Downloading kernel.org 4.14.186..."
  curl -sL -o "$OLD_TAR" "https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-4.14.186.tar.xz"
fi
if [ ! -d "$OLD_DIR" ]; then
  echo "  Extracting 4.14.186..."
  tar xf "$OLD_TAR"
fi

if [ "$SUBLEVEL" -le 336 ]; then
  # Upstream kernel.org
  NEW_TAR="linux-${TARGET}.tar.xz"
  NEW_DIR="linux-${TARGET}"
  if [ ! -f "$NEW_TAR" ]; then
    echo "  Downloading kernel.org $TARGET..."
    curl -sL -o "$NEW_TAR" "https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-${TARGET}.tar.xz"
  fi
  if [ ! -d "$NEW_DIR" ]; then
    echo "  Extracting $TARGET..."
    tar xf "$NEW_TAR"
  fi
else
  # OpenELA LTS
  NEW_DIR="kernel-lts-linux-4.14.y"
  if [ ! -d "$NEW_DIR" ]; then
    echo "  Downloading OpenELA LTS 4.14.y..."
    curl -sL -o openela.tar.gz "https://codeload.github.com/openela/kernel-lts/tar.gz/refs/heads/linux-4.14.y"
    echo "  Extracting..."
    tar xzf openela.tar.gz
    rm -f openela.tar.gz
  fi
  ACTUAL=$(grep '^SUBLEVEL' "$NEW_DIR/Makefile" | awk '{print $3}')
  if [ "$ACTUAL" != "$SUBLEVEL" ]; then
    echo "  WARNING: OpenELA HEAD is 4.14.$ACTUAL, not $TARGET."
    echo "  Using HEAD version."
  fi
fi

echo "  OLD: $(head -1 $OLD_DIR/Makefile)"
echo "  NEW: $(head -1 $NEW_DIR/Makefile)"

# ── Step 2: Define skip patterns ───────────────────────────────
SKIP_PATTERNS=(
  "net/wireguard/"
  "backslash-ksu/"
  "fs/nomount.c"
  "fs/nomount.h"
  "lib/string.c"
  "arch/arm64/configs/selene_defconfig"
  "arch/arm64/lib/memcpy.S"
  "arch/arm64/lib/memmove.S"
  "arch/arm64/lib/memset.S"
  "arch/arm64/crypto/aes-modes.S"
  "include/uapi/linux/netfilter/xt_connmark.h"
  "include/uapi/linux/netfilter/xt_mark.h"
  "include/uapi/linux/netfilter/xt_dscp.h"
  "include/uapi/linux/netfilter/xt_DSCP.h"
  "drivers/goodix/"
  "drivers/fpc1020/"
  "drivers/misc/mediatek/"
  "drivers/misc/mediatek_l2/"
)

should_skip() {
  local file="$1"
  for pat in "${SKIP_PATTERNS[@]}"; do
    if [[ "$file" == $pat || "$file" == */$pat ]]; then
      return 0
    fi
  done
  return 1
}

# ── Step 3: Compare and replace ────────────────────────────────
echo ""
echo "=== Step 2: Comparing files ==="

REPLACED=0
SKIPPED_XIAOMI=0
SKIPPED_NO_VANILLA=0
DELETED=0
TOTAL=0
REPLACED_LIST=""
SKIPPED_LIST=""

UPDATE_DIRS="block certs crypto Documentation drivers fs include init ipc kernel lib mm net samples scripts security sound tools usr virt"
ARM64_DIRS="arch/arm64/lib arch/arm64/crypto arch/arm64/kernel arch/arm64/mm arch/arm64/net arch/arm64/sound"

process_dir() {
  local dir="$1"
  [ -d "$OLD_DIR/$dir" ] || return
  [ -d "$NEW_DIR/$dir" ] || return

  while IFS= read -r -d '' vanilla_file; do
    rel="${vanilla_file#$OLD_DIR/}"
    TOTAL=$((TOTAL + 1))

    [ -f "$REPO_ABS/$rel" ] || { SKIPPED_NO_VANILLA=$((SKIPPED_NO_VANILLA + 1)); continue; }
    should_skip "$rel" && { SKIPPED_XIAOMI=$((SKIPPED_XIAOMI + 1)); continue; }

    diff_result=$(diff <(tr -d '\r' < "$REPO_ABS/$rel") <(tr -d '\r' < "$vanilla_file") 2>/dev/null || true)

    if [ -z "$diff_result" ]; then
      if [ -f "$NEW_DIR/$rel" ]; then
        cp "$NEW_DIR/$rel" "$REPO_ABS/$rel"
        REPLACED=$((REPLACED + 1))
        REPLACED_LIST="$REPLACED_LIST\n  $rel"
      else
        rm -f "$REPO_ABS/$rel"
        DELETED=$((DELETED + 1))
        REPLACED_LIST="$REPLACED_LIST\n  DELETED: $rel"
      fi
    else
      SKIPPED_XIAOMI=$((SKIPPED_XIAOMI + 1))
      SKIPPED_LIST="$SKIPPED_LIST\n  $rel"
    fi
  done < <(find "$OLD_DIR/$dir" -type f -print0 2>/dev/null)
}

for dir in $UPDATE_DIRS; do
  process_dir "$dir"
done
for dir in $ARM64_DIRS; do
  process_dir "$dir"
done

# ── Step 4: Update Makefile SUBLEVEL ───────────────────────────
echo ""
echo "=== Step 3: Update Makefile ==="
sed -i "s/^SUBLEVEL = 186/SUBLEVEL = $SUBLEVEL/" "$REPO_ABS/Makefile"
echo "  $(grep '^SUBLEVEL' "$REPO_ABS/Makefile")"

# ── Step 5: Report ─────────────────────────────────────────────
echo ""
echo "=== RESULTS ==="
echo "  Target version: $TARGET"
echo "  Total files compared: $TOTAL"
echo "  Replaced (identical to vanilla): $REPLACED"
echo "  Deleted (removed upstream): $DELETED"
echo "  Skipped (Xiaomi modified): $SKIPPED_XIAOMI"
echo "  Skipped (not in repo): $SKIPPED_NO_VANILLA"

if [ "$REPLACED" -gt 0 ]; then
  echo ""
  echo "=== Files replaced ==="
  echo -e "$REPLACED_LIST" | head -50
  if [ "$(echo -e "$REPLACED_LIST" | wc -l)" -gt 50 ]; then
    echo "  ... and more"
  fi
fi

echo ""
echo "=== DONE ==="
echo "Review changes: cd $REPO_ABS && git diff --stat"
