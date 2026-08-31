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

# Collect commits — KERNEL ONLY (no docs, no project files)
KERNEL_CHANGES=$(git log $RANGE --oneline --no-decorate 2>/dev/null | while IFS= read -r line; do
    hash=$(echo "$line" | awk '{print $1}')
    msg=$(echo "$line" | cut -d' ' -f2-)
    # Skip docs, changelog, roadmap, agents
    echo "$msg" | grep -qiE "^docs?[: ]|CHANGELOG|ROADMAP|AGENTS\.md|\.opencode/|\.agents/" && continue
    # Only include commits touching kernel code/config
    files=$(git diff-tree --no-commit-id --name-only -r "$hash" 2>/dev/null || true)
    echo "$files" | grep -qiE "defconfig|resukisu/|kernel/|fs/|mm/|net/|drivers/|arch/|block/|init/|lib/|security/|include/" || continue
    # Clean up prefix (feat:, fix:, kernel:, selene:, etc.) and version tags
    clean=$(echo "$msg" | sed -E 's/^(feat|fix|refactor|perf|impr|kernel|nomount|ci|build|arch|release|selene)[: ]*//i' | sed -E 's/^v[0-9]+\.[0-9]+\.[0-9]+[a-z]*[. ]*[-—]*[ ]*//')
    [ -n "$clean" ] && echo "$clean"
done | head -10 || true)

cat << EOF
## Phrolova Kernel — ${VARIANT_NAME} Build (${VERSION})

Redmi 10 (selene) · Linux 4.14 Non-GKI · ${DATE}

**Download:** \`Phrolova-selene-${TAG}.zip\`

EOF

echo "### changelog"
echo ""

if [ -n "$KERNEL_CHANGES" ]; then
    echo "$KERNEL_CHANGES" | while IFS= read -r line; do
        [ -n "$line" ] && echo "- $line"
    done
else
    echo "- no kernel changes"
fi

cat << EOF
---

**How to flash:**
1. Download \`Phrolova-selene-${TAG}.zip\`
2. Flash via custom recovery (TWRP / OrangeFox)
3. Reboot system
EOF
