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

### Manager & Modules

> **⚠️ Version matching required:** Manager APK dan NoMount module harus compatible dengan KSU_VERSION kernel.

| Component | Version | Link |
|---|---|---|
| ReSukiSU Manager | KSU_VERSION `35093` | [Telegram APK](https://t.me/ReSukiSU/5/271281) · [Nightly CI](https://nightly.link/ReSukiSU/ReSukiSU/workflows/build-manager/main/Manager-release.zip) |
| NoMount Module | v2.0.0 (kernel v20) | [GitHub Release](https://github.com/maxsteeel/nomount/releases/download/v2.0.0/NoMount-v2.0.0-release.zip) |

> **NoMount:** Kernel driver uses keyring (v20), NOT netlink. Module v1.x uses netlink detection → **false negative** on v20 kernels. Always use NoMount module v2.0.0+.

> Manager lain (KernelSU / MKSU / RKSU) tidak terdeteksi — root jalan, fitur manager nonaktif.

### Flash

1. Flash kernel zip via AnyKernel3 recovery
2. Install NoMount module v2.0.0 via KernelSU manager
3. Install ReSukiSU manager APK (match KSU_VERSION)
4. Reboot
EOF
