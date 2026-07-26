#!/bin/bash
# Changelog Generator - Phrolova Kernel
# Generates clean, structured changelog for GitHub releases

set -e

VERSION="${1:-unknown}"
TAG="${2:-$VERSION}"
VARIANT="${3:-nightly}"

# Map variant number to name
case "$VARIANT" in
    0) VARIANT_NAME="Nightly" ;;
    1) VARIANT_NAME="Stable" ;;
    2) VARIANT_NAME="Hotfix" ;;
    *) VARIANT_NAME="$VARIANT" ;;
esac

LAST_TAG=$(git describe --tags --abbrev=0 HEAD~1 2>/dev/null || git describe --tags --abbrev=0 2>/dev/null || echo "")
RANGE="${LAST_TAG:+$LAST_TAG..}HEAD"
DATE=$(date +"%d %B %Y")

# Collect commits by category
FEATURES=$(git log $RANGE --oneline --no-decorate --grep="^feat" -i 2>/dev/null | sed 's/^[a-f0-9]* //' || true)
FIXES=$(git log $RANGE --oneline --no-decorate --grep="^fix" -i 2>/dev/null | sed 's/^[a-f0-9]* //' || true)
IMPROVE=$(git log $RANGE --oneline --no-decorate --grep="^refactor\|^perf\|^impr\|wireguard\|defconfig\|zram\|bbr\|bfq\|ksm\|cpufreq\|wakelock\|ci:\|build:\|arch:" -i 2>/dev/null | sed 's/^[a-f0-9]* //' || true)
ALL_COMMITS=$(git log $RANGE --oneline --no-decorate 2>/dev/null || true)

cat << EOF
## Phrolova Kernel — ${VARIANT_NAME} Build (${VERSION})

Redmi 10 (selene) · Linux 4.14 Non-GKI · ${DATE}

**Download:** \`Phrolova-selene-${TAG}.zip\`

EOF

echo "### Changelog"
echo ""

HAS_CATEGORIZED=0

if [ -n "$FEATURES" ]; then
    echo "#### 🚀 Features"
    echo "$FEATURES" | while IFS= read -r line; do
        [ -n "$line" ] && echo "- $line"
    done
    echo ""
    HAS_CATEGORIZED=1
fi

if [ -n "$FIXES" ]; then
    echo "#### 🐛 Bug Fixes"
    echo "$FIXES" | while IFS= read -r line; do
        [ -n "$line" ] && echo "- $line"
    done
    echo ""
    HAS_CATEGORIZED=1
fi

if [ -n "$IMPROVE" ]; then
    echo "#### ⚡ Improvements & Configs"
    echo "$IMPROVE" | while IFS= read -r line; do
        [ -n "$line" ] && echo "- $line"
    done
    echo ""
    HAS_CATEGORIZED=1
fi

if [ "$HAS_CATEGORIZED" -eq 0 ] && [ -n "$ALL_COMMITS" ]; then
    echo "#### 📝 Changes in this release"
    echo "$ALL_COMMITS" | while IFS= read -r line; do
        [ -n "$line" ] && echo "- ${line#* }"
    done
    echo ""
elif [ -z "$ALL_COMMITS" ]; then
    echo "No notable changes."
    echo ""
fi

cat << EOF
---

**How to flash:**
1. Download \`Phrolova-selene-${TAG}.zip\`
2. Flash via custom recovery (TWRP / OrangeFox)
3. Reboot system
EOF
