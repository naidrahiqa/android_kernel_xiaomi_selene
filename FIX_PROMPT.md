# FIX PROMPT — Phrolova Selene Kernel Build Repair

## Context

This is a Redmi 10 (selene) MediaTek Helio G88 kernel project. Base source is MiCode `selene-r-oss-update` (Linux 4.14.186, non-GKI, heavily Mediatek-customized).

**The problem:** A previous attempt did a "selective update" from 4.14.186 → 4.14.336. The script compared each file to vanilla 4.14.186 — if identical, replaced with 4.14.336 version; if Xiaomi-modified, preserved. This created massive API mismatches between updated headers and preserved .c files. Building produces 20+ errors.

**User's request:** Scrap the broken selective update. Go back to the working 4.14.186 base. Apply security fixes PROPERLY (CIP-style: maintain API, only backport security patches).

## Current State

The `phrolova` branch has been reset to commit `9e7545944` ("fix: landscape banner"), which is the last known-good build state (4.14.186, working CI). On top of that, the following commits were cherry-picked (all safe, non-update):

```
f7779c81e refactor: flexible kernel update workflow + AGENTS.md orchestrator
91e9945f5 feat: add release banner
6c205832f fix: update-kernel.yml YAML syntax
02931a208 fix: Telegram banner
```

The branch is behind `origin/phrolova` by 9 commits — those are the reverted update commits.

## What To Do

### Step 1: Reset + Force Push

Branch: `phrolova`
Checkout `9e7545944`, cherry-pick safe commits as above, then:

```bash
git push --force origin phrolova
```

This restores a clean, BUILDING state.

### Step 2: Stabilize Build

Verify CI green. Current state should build successfully at 4.14.186.

### Step 3: Security-Only Updates (CIP Style)

Do NOT use the selective update script. Instead:

1. Clone CIP kernel: `https://git.kernel.org/pub/scm/linux/kernel/git/cip/linux-cip.git` branch `linux-4.14.y-cip`
2. Identify security patches between 4.14.186 and the latest CIP tag
3. Apply ONLY patches that do NOT change kernel API (no struct renames, no function signature changes, no new/deleted EXPORT_SYMBOL)
4. Skip any patch that touches files in: `arch/arm64/` (board-specific), `drivers/` (MTK-specific), `sound/soc/mediatek/`, `drivers/misc/mediatek/`

### Step 4: Known Gotchas For This Kernel

| Issue | Fix |
|---|---|
| Clang IAS `.weak` → `.globl` | `arch/arm64/lib/memcpy.S`, `memmove.S`, `memset.S` — change `.weak` to `.globl` |
| Clang 23 `stpcpy` optimization | Add `#include <linux/string.h>` declaration + `lib/string.c` implementation |
| VDSO named macro args | `clock_gettime_return` must use positional arg (not named) |
| AES 68-bit literal | `arch/arm64/crypto/aes-modes.S` — use `mov/dup` instead of literal |
| `CONFIG_GOODIX_FINGERPRINT` | Keep disabled (prebuilt dep on `__stack_chk_guard`) |
| `CONFIG_FPC_FINGERPRINT` | Keep disabled (depends on Goodix symbols) |
| Reserved NTFS filenames | `aux.c`/`aux.h` in nouveau/soc/arc — sparse checkout or WSL |
| `UL()` macro undeclared | `BIT_MASK(nr)` in Clang — add `#include <linux/types.h>` before `bits.h` usage |

### Step 5: KernelSU + NoMount

- KernelSU: ReSukiSU (multi-manager), source at `resukisu/kernel/`, symlink at `drivers/kernelsu`
- Hook mode: `CONFIG_KSU_MANUAL_HOOK=y` (manual hooks in fs/ and kernel/)
- NoMount: `fs/nomount.c` + `fs/nomount.h`, VFS hooks in dcache/namei/readdir/stat/statfs/proc
- Both work fine at 4.14.186 — no update needed

### Step 6: CI Pipeline

GitHub Actions workflow at `.github/workflows/build.yml`:
- Greenforce Clang 24.0.0
- `CC=clang HOSTCC=gcc CROSS_COMPILE=aarch64-linux-gnu-`
- Single universal build (1 zip fits MIUI + AOSP)
- Version scheme: `version.sh` (nightly/stable/hotfix)
- AnyKernel3 packaging (Image.gz-dtb preferred)

## Files Reference

| Path | Purpose |
|---|---|
| `.github/workflows/build.yml` | Main CI build |
| `.github/scripts/version.sh` | Versioning |
| `.github/scripts/generate-changelog.sh` | Release changelog |
| `.github/scripts/notify-telegram.sh` | Telegram notifications |
| `resukisu/kernel/` | ReSukiSU source |
| `fs/nomount.c`, `fs/nomount.h` | NoMount source |
| `scripts/anykernel.sh` | AnyKernel3 config |
| `arch/arm64/configs/selene_defconfig` | Kernel config |
| `.opencode/skills/selene-kernel/` | Full project skill reference |

## Contact

If unsure, check `.opencode/skills/selene-kernel/references/` for detailed docs on each subsystem.

Naidra can answer escalation questions about:
- MiCode vs Ronald826 patch conflicts
- Vendor MIUI 12.5.20 vermagic requirements
- Toolchain decisions
