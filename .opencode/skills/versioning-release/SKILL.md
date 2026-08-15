---
name: versioning-release
description: "Master authority for version bumping, release body changelog, Telegram notifications, and version decisions - Skill for versioning-release"
---

# Versioning & Release Management — Phrolova Kernel

Master skill untuk **seluruh logika penomoran versi, rilis, notifikasi, dan penentuan kenaikan versi**.

### Tanggung Jawab Skill Ini (Central Authority)
1. **Penentu Versi (Version Decision Authority):** Menentukan versi target berikutnya (`MAJOR.MINOR.PATCH`) berdasarkan jenis perubahan:
   - `MAJOR` bump (`1.0.0`): Rilis stabil final / perombakan arsitektur besar.
   - `MINOR` bump (`0.9.0` -> `0.10.0`): Fitur baru besar (misal migrasi root solution, implementasi subsistem baru).
   - `PATCH` bump (`0.9.0` -> `0.9.1`): Tuning performa, defconfig tweaks, bugfix kecil.
2. **Sinkronisasi Versi 4-Titik (Wajib Serentak):**
   - [CHANGELOG.md](file:///home/naidrahiqa/Projects/Project-Coding/2026/7Juli/android_kernel_xiaomi_selene/CHANGELOG.md) (Header versi baru)
   - `.github/workflows/build.yml` (`PHROLOVA_BASE` & input `base_version`)
   - `.github/scripts/version.sh` (`BASE_VERSION` default fallback)
   - [ROADMAP.md](file:///home/naidrahiqa/Projects/Project-Coding/2026/7Juli/android_kernel_xiaomi_selene/ROADMAP.md) ("Versi Saat Ini")
3. **Format Rilis & GitHub Release:** Mengatur generator changelog (`generate-changelog.sh`) dan template release body (`append-root-section.sh`).
4. **Notifikasi Telegram:** Menjamin tag versi, varian, dan link manager yang dikirim ke bot Telegram (`notify-telegram.sh`) match 100% dengan versi kernel yang di-build.

## Version Scheme

Script: `.github/scripts/version.sh`

| Variant | Trigger | Output |
|---|---|---|
| **Nightly** (0) | `workflow_dispatch` atau push ke branch | `v{base}-nightly.YYYYMMDD` |
| **Stable** (1) | `workflow_dispatch` manual | `v{base}` |
| **Hotfix** (2) | `workflow_dispatch` manual | `v{base+1}` — patch bump |

`base_version` default: `0.9.1`. Bisa di-set via `workflow_dispatch` input.
Bump `base_version` di `.github/workflows/build.yml` dan `.github/scripts/version.sh` tiap ada fitur/tuning baru.

Variabel yang di-export:
- `PHROLOVA_VERSION` — full version string
- `PHROLOVA_TAG` — git tag (sama dengan version)
- `LOCALVERSION` — embedded kernel version (`-Phrolova-v0.6.0-...`)

## Changelog Generator

Script: `.github/scripts/generate-changelog.sh`

Arguments: `generate-changelog.sh <version> <tag> <variant>`

### Cara kerja
1. `git describe --tags` untuk cari tag terakhir
2. Collect commits antara tag terakhir..HEAD
3. Kategorisasi berdasarkan keyword di commit message:

| Kategori | Keyword grep |
|---|---|
| 🚀 Features | `^feat` |
| 🐛 Bug Fixes | `^fix` |
| ⚡ Improvements | `^refactor`, `^perf`, `^impr`, `wireguard`, `defconfig`, `zram`, `bbr`, `bfq`, `ksm`, `cpufreq`, `wakelock`, `ci:`, `build:`, `arch:` |

### Kalau changelog kosong
1. Cek `git describe --tags` — pastikan ada tag sebelumnya
2. Cek range commit: `LAST_TAG..HEAD`
3. Pastikan commit messages pake format yang di-grep (lihat tabel di atas)
4. Kalau commit ga cocok kategori manapun, dia bakal masuk sebagai "Changes" (fallback)
5. Kalau bener-bener ga ada commit di range, muncul "No notable changes."

### Nambah kategori
Edit `generate-changelog.sh` — tambah keyword ke variable `IMPROVE`:
```bash
IMPROVE=$(git log ... --grep="^keyword1\|keyword2" -i ...)
```

## Release Body (CI)

Di `build.yml`:
1. `generate-changelog.sh` → `changelog.md`
2. `cp changelog.md release_body.md`
3. `softprops/action-gh-release` — pakai `release_body.md` sebagai body

Isi release body otomatis include:
- Tabel info device/kernel/root
- Changelog dari commits
- Flash instructions

## Version Bump Workflow

### Nightly (otomatis)
Push ke `phrolova` → CI jalan → `v0.6.0-nightly.20260726`

### Stable (manual)
1. `workflow_dispatch` di GitHub Actions
2. Isi `variant = 1 — Stable`, `base_version` sesuai (misal `0.6.0`)
3. CI jalan → `v0.6.0` → GitHub Release dibuat

### Hotfix (manual)
1. `workflow_dispatch` di GitHub Actions
2. Isi `variant = 2 — Hotfix`, `base_version` sesuai
3. CI jalan → patch version di-bump (`0.6.0` → `0.6.1`)

## Troubleshooting

### Changelog muncul "No notable changes."
→ Commit messages tidak cocok keyword grep. Cek pake:
```bash
git log LAST_TAG..HEAD --oneline
```
Terus pastikan commit messages pake prefix `feat:`, `fix:`, dll.

### Version tag bentrok
Kalau `workflow_dispatch` pake tag yang udah ada, release creation gagal.
Ganti `base_version` di input.
