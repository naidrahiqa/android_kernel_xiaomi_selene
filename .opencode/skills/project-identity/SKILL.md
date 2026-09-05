---
name: project-identity
description: Project identity and branding rules. Use when generating commit messages, notifications, release notes, or any user-facing text. NEVER forget these.
---

# Project Identity — Phrolova Kernel

## CRITICAL: Author Identity

**Author:** `naidrahiqa` (NOT "naidra", NOT "Naidra", NOT "Naidrahiqa")
- GitHub: [github.com/naidrahiqa](https://github.com/naidrahiqa)
- Full display: `naidrahiqa`

## Project Name

**Phrolova Kernel** (with capital P and K)

## Branding

- Emoji: 🎻 (always use in notifications/headers)
- Hashtags: `#selene #Redmi10 #mt6768 #kernel #PhrolovaKernel`

## Notification Format (Telegram Channel)

### Build Start
```
🎻 Phrolova · {version}
━━━━━━━━━━━━━━━━━━━━
Building...
{commit_hash} {commit_message}
Build Log
```

### Build Success
```
🎻 Phrolova · {version}
━━━━━━━━━━━━━━━━━━━━
Redmi 10 · selene · MT6768 · Non-GKI
⚠️ ReSukiSU {ksu_tag} · NoMount v2.0.0

Changelog:
+{change_1}
+{change_2}
+{change_3}

Full Changelog

[📱 ReSukiSU APK]
[⬇ Kernel Download]
[📦 NoMount (mandatory)]
```

### Build Failed
```
🎻 Phrolova · {version}
━━━━━━━━━━━━━━━━━━━━
❌ {ERROR_TYPE}
Check Log
```

## Changelog Format (CHANGELOG.md)

Use `+` prefix for each item, write what changed for the user, NOT git commit messages:

```
+arm64: Use optimized memcmp.
+mm/slub.c: branch optimization in free slowpath
+binder: Set binder_debug_mask=0 to suppress logging
+fs: dcache: reduce sysctl_vfs_cache_pressure to 50
+sched/fair: Consider all running tasks in cpu for load balance
```

**DO:**
- Write what the change does for the user
- Use technical but understandable terms
- Group related changes

**DON'T:**
- Copy git commit messages (e.g. "fix: simple_lmk v1.0.5")
- Use conventional commit prefixes (feat:, fix:, etc.)
- Write "update" or "improve" without specifics

## Buttons (Inline Keyboard)

Stack vertically, NOT side by side:
```
[📱 ReSukiSU APK]
[⬇ Kernel Download]
[📦 NoMount (mandatory)]
```

## Git Identity (CI)

- Author name: `Phrolova CI`
- Author email: `phrolova-bot@users.noreply.github.com`
- KBUILD_BUILD_USER: `Phrolova🎻`
- KBUILD_BUILD_HOST: `selene`

## Never Forget

- It's **naidrahiqa**, not naidra
- It's **Phrolova Kernel**, not Phrolova kernel
- Always use 🎻 emoji in notifications
- Changelog = user-facing changes, not git commits
- Buttons stacked vertically
- No credits section in notifications
