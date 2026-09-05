#!/bin/bash
# asb/triage.sh — helper apply-1-patch buat Phrolova-ASB
# Usage: asb/triage.sh <patch-file-atau-branch> [sumber]
#   sumber: openela|ack|cip|mainline|axp (default: manual)
#
# Apa yang dia lakukan:
#   1. git apply --check dulu (nggak ngerusak working tree)
#   2. Apply kalau clean, atau stop dengan pesan konflik
#   3. Print template baris STATUS.md yang siap di-paste
#
# Patch TIDAK otomatis di-commit — commit manual setelah CI + device test.

set -euo pipefail

PATCH="$1"
SOURCE="${2:-manual}"
MONTH_DIR="$(dirname "$PATCH")"

if [[ ! -f "$PATCH" ]]; then
    echo "❌ patch tidak ada: $PATCH"
    echo "   Ambil dulu, contoh:"
    echo "   git format-patch -1 <sha> --output=asb/2026-MM/<cve-id>.patch"
    echo "   (atau format-patch dari remote CIP/ACK: git fetch cip linux-4.19.y-cip dst.)"
    exit 1
fi

echo "==> --check $PATCH"
if git apply --check "$PATCH" 2>/dev/null; then
    echo "==> apply $PATCH"
    git apply --index "$PATCH"
    APPLIED=1
else
    echo "❌ --check GAGAL — patch butuh adaptasi manual (3-way atau port):"
    echo "   git apply --3way $PATCH"
    exit 2
fi

FILES=$(git diff --cached --name-only)
echo ""
echo "==> Files yang berubah:"
echo "$FILES"
echo ""
echo "==> Paste ke asb/$(basename "$MONTH_DIR")/STATUS.md:"
echo "| $(basename "$PATCH" .patch) | $SOURCE | applied | $(git diff --cached --stat | tail -1) |"
echo ""
echo "⏭  Lanjutan wajib:"
echo "   1. make O=out ARCH=arm64 CC=clang HOSTCC=gcc CROSS_COMPILE=aarch64-linux-gnu- -j\$(nproc)"
echo "   2. CI hijau + boot test di selene (ADB: uname -r, dmesg bersih)"
echo "   3. Commit: kernel: backport <CVE-id> from <source>"
echo "   4. Update docs/CVE-INVENTORY.md + CHANGELOG.md"
