---
name: resukisu-manager-link
description: Use when updating ReSukiSU manager links in CI scripts, release notifications, or documentation. Handles the4 architecture variants and link strategy.
---

# ReSukiSU Manager Link

## Variants

Each ReSukiSU build produces 4 manager APKs:

| Variant | Arch | Size | Use Case |
|---------|------|------|----------|
| `arm64-v8a-release.apk` | 64-bit ARM | ~8MB | Most modern phones (recommended) |
| `armeabi-v7a-release.apk` | 32-bit ARM | ~7MB | Older/budget phones |
| `universal-release.apk` | All archs | ~13MB | Safe fallback (bigger) |
| `debug.apk` | Debug | ~35MB | Debugging only |

## Link Strategy

**Static Telegram post** — user picks their own variant:
```
https://t.me/ReSukiSU/{topic}/{post_id}
```

**Nightly link (always latest)** — but defaults to universal (13MB):
```
https://nightly.link/ReSukiSU/ReSukiSU/workflows/build-manager/main/Manager-release.zip
```

## Decision

Use Telegram link in CI notifications. Add note: "Download `arm64-v8a` for most phones."

## When Updating

1. Get new Telegram post URL from t.me/ReSukiSU channel
2. Update in:
   - `.github/scripts/append-root-section.sh` (release body)
   - `.github/scripts/notify-telegram.sh` (Telegram notification)
3. Update `KSU_VERSION` in same files
4. Commit: `release: ReSukiSU {version} ({short_sha})`
5. Also update: `resukisu/kernel/Kbuild`, `AGENTS.md`, `docs/HOOK_MODES.md`, `ROADMAP.md`, `FIX_PROMPT.md`, `arch/arm64/configs/selene_defconfig`

## Full Update Checklist

When ReSukiSU releases new version:

- [ ] `resukisu/kernel/Kbuild`: `KSU_LOCAL_VERSION` (commits count), `KSU_COMMIT_SHA` (first7 chars)
- [ ] `AGENTS.md`: `ReSukiSU @ SHA` + `KSU_VERSION {num}`
- [ ] `docs/HOOK_MODES.md`: KSU version refs
- [ ] `ROADMAP.md`: KSU version refs
- [ ] `FIX_PROMPT.md`: KSU version refs
- [ ] `arch/arm64/configs/selene_defconfig`: ReSukiSU comment
- [ ] `.github/scripts/append-root-section.sh`: KSU_VERSION + manager link
- [ ] `.github/scripts/notify-telegram.sh`: KSU_VERSION + manager link
- [ ] Commit all + push
