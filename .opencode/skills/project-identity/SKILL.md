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

## Notification Routing & Format

### Target Destinations
1. **Gambar Kiri — Supergroup Naidrahiqa Stuff (`TELEGRAM_GROUP_ID` = `-1004414006944`)**:
   - **Topic `⁉️ Selene CI` (`TELEGRAM_TOPIC_CI` = `47`)**: HANYA NOTIFIKASI (Start & Success), **TANPA FILE ZIP**.
   - **Topic `🔍 log` (`TELEGRAM_TOPIC_LOG` = `8`)**: Cuplikan error log build jika gagal.
2. **Gambar Kanan — Private Channels**:
   - **Channel `Nai project update` (`TELEGRAM_CHANNEL_ID` = `-1003752197403`)**: Mengirim **file kernel `.zip` AnyKernel3** via `sendDocument` + caption rilis lengkap.
   - **Channel `Nai Error Dump` (`TELEGRAM_ERROR_CHANNEL_ID` = `-1003945405514`)**: Full error dump.

### 1. Topic `⁉️ Selene CI` #47 (Gambar Kiri — Notif Only)
* **Build Start:**
```html
🎻 <b>Phrolova</b> · <code>{version}</code>
━━━━━━━━━━━━━━━━━━━━
🔨 <b>Building...</b>
<code>{commit_hash}</code> {commit_message}
<a href='{build_url}'>Build Log</a>
```
* **Build Success:**
```html
🎻 <b>Phrolova</b> · <code>{version}</code>
━━━━━━━━━━━━━━━━━━━━
<b>Redmi 10</b> · selene · MT6768 · Non-GKI
⚠️ ReSukiSU <code>{ksu_tag}</code> · NoMount v2.0.0

Changelog:
- {change_1}
- {change_2}

📦 <i>File kernel telah dikirim ke channel rilis.</i>
<a href='{changelog_url}'>Full Changelog</a>

[📱 ReSukiSU APK]
[⬇ GitHub Release]
[📦 NoMount]
```

### 2. Channel `Nai project update` (Gambar Kanan — File .ZIP Document)
* **Dokumen AnyKernel3:** Lampiran file `selene-{tag}-{hash}.zip`
* **Caption:**
```html
🎻 <b>Phrolova Kernel</b> · <code>{version}</code>
━━━━━━━━━━━━━━━━━━━━
<b>Device:</b> Redmi 10 (selene) · MT6768 · Non-GKI
<b>Root:</b> ReSukiSU <code>{ksu_tag}</code>
<b>Redirection:</b> NoMount v2.0.0
<b>Size:</b> {file_size}
<b>Commit:</b> <code>{commit_hash}</code> {commit_message}

Changelog:
- {change_1}
- {change_2}

⚠️ <i>Flash via AnyKernel3 recovery (TWRP/OrangeFox).</i>
```

### 3. Error Handling
* **Topic `⁉️ Selene CI` #47:** Pesan singkat `❌ ERROR_TYPE` + link log.
* **Topic `🔍 log` #8:** Cuplikan 3000 karakter terakhir `build.log`.
* **Channel `Nai Error Dump`:** Pesan detail dengan block `<pre><code>...error_context...</code></pre>`.


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
