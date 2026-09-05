# Phrolova-ASB — Android Security Bulletin Backport Project

**Device:** Redmi 10 2022 (selene) · **Kernel:** 4.14.357 (the last 4.14 that exists from
any upstream source) · **Maintainer:** Naidra (naidrahiqa)

## Kenapa Project Ini Ada

Semua sumber upstream 4.14 sudah mati (diverifikasi 2026-09-05):

| Sumber | Kernel terakhir | Status |
|---|---|---|
| kernel.org stable | 4.14.336 | EOL Jan 2024 |
| OpenELA kernel-lts | 4.14.357 | Frozen — commit terakhir = sublevel bump .357 |
| Google ACK `deprecated/android-4.14-stable` | 4.14.336 | Nggak pernah dapat ASB merge lagi setelah Jan 2024 |
| CIP SLTS | — | 4.14 **nggak pernah** jadi SLTS CIP (mereka: 4.4/4.19/5.10/6.1/6.12) |

Mulai Januari 2024, security fix kernel buat 4.14 cuma bisa didapet lewat **manual
backport** dari branch yang masih hidup (ACK 4.19/5.4, mainline, CIP 4.19-cip).

Project ini ngadopsi model **CVE-Patcher** (DivestOS → dilanjutkan AXP.OS): patch
per-bulan per-CVE, tiap patch punya status eksplisit. Nggak ada silent merge, nggak
ada fake sublevel.

## Struktur

```
asb/
├── README.md                  ← charter (file ini)
├── BASELINE.md                ← hasil scan OpenELA lengkap (356→357) + EOL status
├── triage.sh                  ← helper: apply-1-patch dengan template status
└── 2026-MM/                   ← satu folder per bulan ASB yang ditriage
    ├── STATUS.md              ← tabel CVE → keputusan
    └── *.patch                ← patch file (dari ACK/mainline/CIP), optional
```

## Vokabulari Status (WAJIB dipakai di tiap STATUS.md)

| Status | Arti |
|---|---|
| `applied` | Patch sudah masuk tree (dicatat juga di CHANGELOG.md) |
| `n.a.` | Kode yang divulnan tidak dikompilasi di selene_defconfig → tidak relevan |
| `skip:<alasan>` | Relevan tapi tidak di-backport (impl beda, terlalu invasif, dsb) — alasan wajib konkret |
| `reverted` | Sudah dicoba tapi menimbulkan regresi di device (contoh preseden: inet_defrag → WiFi GSO crash) |
| `open` | Relevan, belum dievaluasi |

## Sumber Patch (urutan preferensi)

1. **CIP 4.19-cip / 5.10-cip** — fix sudah divalidasi jangka panjang, biasanya apply bersih ke 4.14
2. **ACK android-4.19-stable / android-5.4-stable** — yang dikutip ASB `+ kernel` section
3. **Mainline** — kalau belum ada di stable mana pun; risk paling tinggi, wajib review `patch-analysis`
4. **AXP.OS / DivestOS CVE-Patcher patch sets** — mining langsung, patch yang sudah "dipelintir" buat legacy kernels

## Workflow Bulanan

1. ASB baru rilis (perhatian: sejak Juli 2025 banyak yang jadi **quarterly**) →
   buat folder `asb/2026-MM/`
2. Daftar semua CVE di section **Kernel** bulletin
3. Tandai eksposur kita: cek apakah file/subsystem yang divulnan dikompilasi di
   `selene_defconfig` (grep dulu, jangan asal diff)
4. Buat `STATUS.md` — boleh semua `open` dulu, tapi jangan pernah kosong
5. Evaluasi satu-satu: `n.a.` cepat; yang relevan → coba apply → CI → **device test**
   (build merah / bootloop = jangan merge)
6. Update `docs/CVE-INVENTORY.md` + `CHANGELOG.md` tiap ada `applied`

## Aturan Hard

- **CI-first & device-tested:** patch yang belum lewat build CI + boot test di selene
  tidak boleh di-commit sebagai `applied`
- **No fake sublevel:** sublevel mentok di 357 (blank-screen issue di MTK di atasnya).
  Bukti level patch ditunjukkan lewat tag ASB di `EXTRAVERSION`/LOCALVERSION:
  `4.14.357-Phrolova🎻-ASB202609`
- **Vendor-driver landmine:** config hardening yang sudah terbukti bikin crash
  (SLAB_FREELIST_HARDENED, INIT_ON_ALLOC, BUG_ON_DATA_CORRUPTION, SHADOW_CALL_STACK)
  **tidak boleh** di-enable sebagai "bonus" — lihat AGENTS.md

## Status Saat Ini

- **2026-09:** project dibuat. Baseline = full OpenELA scan (lihat `BASELINE.md`) —
  delta vs upstream terakhir = 0. Backlog ASB Jan 2024 → Agu 2026 = **32 bulan**, belum
  di-triage. Prioritas: bulan-bulan yang punya CVE critical/acts-in-the-wild dulu.
