#!/bin/bash
set -e

cp changelog.md release_body.md

cat >> release_body.md << 'EOF'

---

## 🔐 Root Solution

| | |
|---|---|
| **Driver** | ReSukiSU v4.2.0-rc1 · KSU_VERSION `35093` |
| **Hook** | Manual Hook (non-GKI 4.14) |
| **Path Redirection** | NoMount v20 (keyring + VFS hijack) |
| **Source** | [ReSukiSU/ReSukiSU](https://github.com/ReSukiSU/ReSukiSU) |

### Manager

Wajib match KSU_VERSION `35093`:
- [ReSukiSU Manager](https://t.me/ReSukiSU/5/271281) (Telegram APK)
- [ReSukiSU Manager](https://nightly.link/ReSukiSU/ReSukiSU/workflows/build-manager/main/Manager-release.zip) (Nightly CI)

> Manager lain (KernelSU / MKSU / RKSU) tidak terdeteksi — root jalan, fitur manager nonaktif.

### Flash

Flash zip via AnyKernel3 recovery, lalu install manager APK.
EOF
