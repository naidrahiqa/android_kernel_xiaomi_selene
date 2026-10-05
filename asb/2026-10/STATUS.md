# ASB 2026-10 — Triage Status

Bulletin: https://source.android.com/docs/security/bulletin/2026-10

| CVE | Komponen/file | Eksposur kita | Status | Sumber patch | Catatan |
|---|---|---|---|---|---|
| (isi manual — lihat section Kernel di bulletin) | | | open | | |

## Checklist
- [ ] Daftar semua CVE section Kernel dari bulletin
- [ ] Grep subsystem di selene_defconfig (n.a. screening)
- [ ] Evaluasi + apply yang relevan (asb/triage.sh)
- [ ] CI + device test
- [ ] Update docs/CVE-INVENTORY.md + CHANGELOG.md
