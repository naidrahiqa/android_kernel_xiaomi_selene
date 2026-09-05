# Phrolova-ASB Baseline — per 2026-09-05

Baseline keamanan sebelum project ASB dimulai. Hasil scan sistematis pertama
(commit `bc6700f3f3`), detail lengkap di [docs/CVE-INVENTORY.md](../docs/CVE-INVENTORY.md).

## Scan Range

`a76b6a6556` (LTS: Update to 4.14.356) → `1e6347375d` (LTS: Update to 4.14.357 = OpenELA HEAD)

## Hasil: 5/5 patch ter-account — delta vs upstream = 0

| Commit | Komponen | Klasifikasi | Status | Catatan |
|---|---|---|---|---|
| `70649db160` | ima: UAF dentry dname.name | Security (UAF) | ✅ APPLIED | via `28578b90c3` (v0.9.10) |
| `81cba5e105` | inet_defrag: sk release UAF | Security (UAF) | 🔄 REVERTED | `skb->cb` move → WiFi GSO crash ~14 min uptime (device-tested) |
| `30c9d27783` | clk: slab-OOB devm_clk_release | Security (OOB) | ⏭ SKIPPED | impl beda di tree kita |
| `a7cd6312e4` | clk: pointer casting oops | Stability | ⏭ SKIPPED | file sama dengan atas |
| `b418fc71a9` | ocfs2: slab-UAF dqi_priv | Security (UAF) | ⏭ SKIPPED | `CONFIG_OCFS2_FS` not set |

## CVE yang Sudah Ditangani (pra-baseline)

| CVE / Issue | Mitigasi | Status |
|---|---|---|
| CVE-2026-31431 (CopyFail, algif_aead, CVSS 7.8) | `CONFIG_CRYPTO_USER_API_AEAD` not set → modul tidak dikompilasi | ✅ MITIGATED |
| CVE-2017-5715 (Spectre v2) | `HARDEN_BRANCH_PREDICTOR` off (perf-first, deferred) | ⏭ DEFERRED |
| CVE-2018-3639 (SSBD) | `ARM64_SSBD` off (perf-first, deferred) | ⏭ DEFERRED |

## Exposure Surface (audit defconfig, 2026-09-05)

| Config | State | Catatan |
|---|---|---|
| `USERFAULTFD` | ✅ off | Disabled in v0.9.13 (prevents unprivileged local UAF/race condition exploits) |
| `NF_TABLES` | ✅ off | Disabled in v0.9.13 (Android netd uses legacy iptables/xtables) |
| `DEVMEM`, `BPF_SYSCALL`, `KEXEC`, `STRICT_DEVMEM` | ✅ off | — |
| `COMPAT=y` | keep | wajib buat app 32-bit di arm64 |

## Upstream EOL (eksternal, terverifikasi)

- kernel.org: EOL @ .336 (Jan 2024)
- OpenELA: frozen @ .357 (commit terakhir = sublevel bump)
- Google ACK: `deprecated/android-4.14-stable` frozen @ .336, tanpa ASB merges pasca-Jan 2024
- Komunitas (.358–.360 di XDA/Telegram): cherry-pick individual, non-canonical

**Kesimpulan: 4.14.357 = ujung upstream. Semua patch ke depan = manual backport (project ini).**
