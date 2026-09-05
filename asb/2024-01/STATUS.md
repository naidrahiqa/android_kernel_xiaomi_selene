# ASB Triage — 2024-01

**Bulletin:** [Android Security Bulletin — January 2024](https://source.android.com/docs/security/bulletin/2024-01-01)  
**Triage Date:** 2026-09-05  
**Baseline Kernel:** 4.14.357-Phrolova

## Triage Table

| CVE | Subsystem / Komponen | CVSS | Status | Catatan / Evaluasi |
|---|---|---|---|---|
| CVE-2023-45871 | drivers/net/ethernet/intel/igb | 7.8 | `n.a.` | Intel igb driver not enabled in selene_defconfig |
| CVE-2023-45863 | drivers/bluetooth/hci_vhci.c | 7.1 | `n.a.` | Virtual HCI driver not enabled in selene_defconfig |
| CVE-2023-4015 | net/netfilter/nf_tables | 7.8 | `n.a.` | NF_TABLES disabled in selene_defconfig (`# CONFIG_NF_TABLES is not set`) |
| CVE-2023-4244 | net/netfilter/nf_tables | 7.8 | `n.a.` | NF_TABLES disabled in selene_defconfig |
| CVE-2023-4622 | net/unix/af_unix.c | 7.8 | `applied` | AF_UNIX garbage collector UAF patch verified in 4.14 baseline |
| CVE-2023-4623 | net/sched/cls_u32.c | 7.8 | `applied` | cls_u32 classifier fix present in OpenELA 4.14.357 |

## Ringkasan
- Total CVE ditinjau: 6
- Status `applied`: 2 (sudah tercakup di tree baseline)
- Status `n.a.`: 4 (modul tidak dikompilasi atau telah dimatikan via defconfig hardening)
