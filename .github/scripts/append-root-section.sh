#!/bin/bash
set -e

cp changelog.md release_body.md

cat >> release_body.md << 'EOF'

---

### 🔐 Root Solution — ReSukiSU

| Component | Version |
|---|---|
| ReSukiSU Driver | **KSU_VERSION 35090** (main @ `03b60f26`) |
| Tag | v4.2.0-rc1 + 19 commits |
| Hook Mode | Manual Hook (non-GKI 4.14) |
| Source | [ReSukiSU/ReSukiSU](https://github.com/ReSukiSU/ReSukiSU) |

**Manager (wajib match KSU_VERSION 35090):**
- [ReSukiSU Manager (Telegram APK Release)](https://t.me/ReSukiSU/5/271281)
- [ReSukiSU Manager (Nightly CI ZIP)](https://nightly.link/ReSukiSU/ReSukiSU/workflows/build-manager/main/Manager-release.zip)

> ⚠️ Gunakan **ReSukiSU Manager** — manager lain (KernelSU / KernelSU-Next / MKSU / RKSU) **tidak** terdeteksi sebagai manager bawaan kernel ini (root tetap jalan via su, tapi fitur manager nonaktif).

**Systemless Path Redirection:** [NoMount v20](https://github.com/maxsteeel/nomount) — kernel-level path redirection via keyring + VFS hijack.

**Flash:** flash zip via custom recovery (AnyKernel3), lalu install manager APK di atas.
EOF
