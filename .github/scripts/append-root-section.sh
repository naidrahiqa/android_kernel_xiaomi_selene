#!/bin/bash
set -e

cp changelog.md release_body.md

cat >> release_body.md << 'EOF'

---

### 🔐 Root Solution — ReSukiSU

**Manager (versi harus match KSU_VERSION 35071):**
- [ReSukiSU Manager (nightly build)](https://nightly.link/ReSukiSU/ReSukiSU/workflows/build-manager/main/Manager-release.zip)
- [Telegram @ReSukiSU](https://t.me/ReSukiSU)

> ⚠️ Gunakan **ReSukiSU Manager** — manager KernelSU / KernelSU-Next / MKSU / RKSU **tidak** terdeteksi sebagai manager bawaan kernel ini (root tetap jalan via su, tapi fitur manager nonaktif).

**Flash:** flash zip via custom recovery (AnyKernel3), lalu install manager APK di atas.
EOF