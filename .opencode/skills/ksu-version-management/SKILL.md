---
name: ksu-version-management
description: Manage ReSukiSU driver version pins, update kernel source, and keep all documentation references in sync. Use when the user says "update KSU", "update ReSukiSU", "new KSU version", "bump KSU version", or when checking for upstream ReSukiSU releases.
---

# KSU Version Management

Handle ReSukiSU driver updates end-to-end: check upstream, sync source, update pins, update docs, verify CI.

## Current State

- **Driver:** ReSukiSU (`ReSukiSU/ReSukiSU`, fork SukiSU-Ultra)
- **Source:** `resukisu/kernel/` (direct copy, not submodule)
- **Hook mode:** Manual hook (`CONFIG_KSU_MANUAL_HOOK=y`, non-GKI 4.14)
- **Kbuild pin:** Fallback version in `resukisu/kernel/Kbuild` (no `.git` in vendored copy)

## Version Formula

```
KSU_VERSION = 30000 + KSU_LOCAL_VERSION + 700
```

`KSU_LOCAL_VERSION` = total commit count on `main` branch (`git rev-list --count HEAD`).

Example: 4393 commits → 30000 + 4393 + 700 = **35093**

## Update Workflow

### Step 1: Check Latest upstream

```bash
# Get latest main SHA
gh api repos/ReSukiSU/ReSukiSU/commits/main --jq '.sha'

# Count commits ahead of our current pin
gh api "repos/ReSukiSU/ReSukiSU/compare/{OLD_SHA}...{NEW_SHA}" --jq '.ahead_by'

# See what changed in kernel/
gh api "repos/ReSukiSU/ReSukiSU/compare/{OLD_SHA}...{NEW_SHA}" \
  --jq '.files[] | select(.filename | startswith("kernel/")) | "\(.filename) +\(.additions) -\(.deletions)"'
```

### Step 2: Sync Kernel Source

```bash
# Download latest
wget -q "https://github.com/ReSukiSU/ReSukiSU/archive/{NEW_SHA}.zip" -O /tmp/resukisu.zip
unzip -q /tmp/resukisu.zip -d /tmp/

# Diff current vs new (exclude Kbuild which we patch locally)
diff -rq resukisu/kernel/ /tmp/ReSukiSU-{SHA}/kernel/ --exclude=".git"

# Copy changed files (preserve our Kbuild patch)
cp /tmp/ReSukiSU-{SHA}/kernel/runtime/ksud_integration.c resukisu/kernel/runtime/
# ... copy other changed files as needed
```

**NEVER overwrite `resukisu/kernel/Kbuild`** — it has our local fallback pin patch.

### Step 3: Update Kbuild Pin

Edit `resukisu/kernel/Kbuild` — update these 4 values only:

```makefile
KSU_LOCAL_VERSION := {NEW_COMMIT_COUNT}
KSU_TAG_NAME    := {LATEST_TAG}        # e.g. v4.2.0-rc1
KSU_COMMIT_SHA  := {NEW_SHA_SHORT}     # e.g. 7bb6f0df
KSU_BRANCH_NAME := main
```

**Formula:** `KSU_VERSION = 30000 + KSU_LOCAL_VERSION + 700`

### Step 4: Update All Doc References

Search and replace across the repo (excluding CHANGELOG.md which is historical):

```bash
# Find all refs
grep -rn "{OLD_SHA}\|{OLD_VERSION}\|{OLD_LOCAL_VERSION}" \
  --include="*.md" --include="*.yml" --include="*.sh" --include="selene_defconfig" \
  | grep -v CHANGELOG.md | grep -v ".opencode/" | grep -v ".git/"
```

Files to update:
- `AGENTS.md` — Konteks Project, Source of Truth, CI Pipeline, ReSukiSU Integration gotcha
- `docs/HOOK_MODES.md` — all version refs
- `ROADMAP.md` — version refs + feature comparison table
- `FIX_PROMPT.md` — ReSukiSU step
- `arch/arm64/configs/selene_defconfig` — comment block
- `.github/scripts/append-root-section.sh` — hardcoded KSU_VERSION in release body

Batch replace:
```bash
sed -i 's/{OLD_SHA}/{NEW_SHA}/g' AGENTS.md docs/HOOK_MODES.md ROADMAP.md FIX_PROMPT.md selene_defconfig
sed -i 's/{OLD_VERSION}/{NEW_VERSION}/g' AGENTS.md docs/HOOK_MODES.md ROADMAP.md FIX_PROMPT.md append-root-section.sh selene_defconfig
sed -i 's/{OLD_LOCAL_VERSION}/{NEW_LOCAL_VERSION}/g' AGENTS.md docs/HOOK_MODES.md FIX_PROMPT.md
```

### Step 5: Verify Auto-Extract

```bash
bash .github/scripts/get_ksu_info.sh
# Should output:
# KSU_VERSION_NUM={NEW_VERSION}
# KSU_TAG={TAG}
# KSU_COMMIT={NEW_SHA}
# KSU_BRANCH=main
```

### Step 6: Commit + Push

```bash
git add resukisu/kernel/ AGENTS.md docs/ ROADMAP.md FIX_PROMPT.md \
  arch/arm64/configs/selene_defconfig .github/scripts/append-root-section.sh
git commit -m "kernel: ReSukiSU {TAG}+{N} (KSU_VERSION {VERSION}) — {CHANGE_SUMMARY}"
git push origin phrolova
```

CI will auto-build and create/update release with correct version in notification + release body.

## Files Touched Per Update

| File | What changes |
|---|---|
| `resukisu/kernel/Kbuild` | Pin values (LOCAL_VERSION, SHA) |
| `resukisu/kernel/runtime/ksud_integration.c` | Usually the kernel-side changes |
| `resukisu/kernel/selinux/*` | SELinux policy changes (rare) |
| `AGENTS.md` | Version refs in 5+ locations |
| `docs/HOOK_MODES.md` | Version refs in 7+ locations |
| `ROADMAP.md` | Version refs in 2 locations |
| `FIX_PROMPT.md` | Version refs in 2 locations |
| `arch/arm64/configs/selene_defconfig` | Comment block |
| `.github/scripts/append-root-section.sh` | Hardcoded KSU_VERSION |

## Gotchas

- **Kbuild is patched locally** — upstream uses `$(shell git ...)` which fails without `.git`. Our fallback hardcodes the values. NEVER replace with upstream Kbuild.
- **`+ N commits`** in docs = commits ahead of latest tag (not total). Update this number when the tag doesn't change but new commits land.
- **CHANGELOG.md is historical** — do NOT update old version refs there. Only add new entries.
- **Formula is fixed** — `30000 + LOCAL + 700`. If upstream changes the formula, update `get_ksu_info.sh` too.
- **Manager APK must match** — KSU_VERSION in kernel must match manager APK version. ReSukiSU manager (nightly.link) is recommended.
