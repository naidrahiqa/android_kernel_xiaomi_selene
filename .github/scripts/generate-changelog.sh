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

LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
DATE=$(date +"%d %B %Y")

# Collect commits by type
FEATURES=$(git log ${LAST_TAG:+$LAST_TAG..}HEAD --oneline --no-decorate --grep="^feat" -i 2>/dev/null | sed 's/^[a-f0-9]* //' || echo "")
FIXES=$(git log ${LAST_TAG:+$LAST_TAG..}HEAD --oneline --no-decorate --grep="^fix" -i 2>/dev/null | sed 's/^[a-f0-9]* //' || echo "")
IMPROVE=$(git log ${LAST_TAG:+$LAST_TAG..}HEAD --oneline --no-decorate --grep="wireguard\|defconfig\|zram\|bbr\|bfq\|ksm\|cpufreq\|wakelock\|ci:" -i 2>/dev/null | sed 's/^[a-f0-9]* //' || echo "")

cat << EOF
## Phrolova Kernel — ${VARIANT_NAME} Build

| | |
|---|---|
| **Device** | Redmi 10 (selene) · MediaTek Helio G88 |
| **Kernel** | Linux 4.14 · Non-GKI |
| **Toolchain** | Greenforce Clang 23.0.0 |
| **Root** | KernelSU (backslashxx) · Syscall Table Hook |
| **Build Type** | ${VARIANT_NAME} |
| **Date** | ${DATE} |

### Download

\`Phrolova-selene-${TAG}.zip\`

EOF

# Changelog section
if [ -n "$FEATURES" ] || [ -n "$FIXES" ] || [ -n "$IMPROVE" ]; then
echo "### Changelog"
echo ""
if [ -n "$FEATURES" ]; then
    echo "**Features:**"
    echo "$FEATURES" | while IFS= read -r line; do
        echo "- $line"
    done
    echo ""
fi
if [ -n "$FIXES" ]; then
    echo "**Fixes:**"
    echo "$FIXES" | while IFS= read -r line; do
        echo "- $line"
    done
    echo ""
fi
if [ -n "$IMPROVE" ]; then
    echo "**Improvements:**"
    echo "$IMPROVE" | while IFS= read -r line; do
        echo "- $line"
    done
    echo ""
fi
else
echo "### Changelog"
echo ""
echo "No notable changes."
fi

cat << EOF

---

**How to flash:**
1. Download the zip for your ROM type
2. Flash via custom recovery (TWRP / OrangeFox)
3. Reboot and profit
EOF
