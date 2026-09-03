#!/bin/bash
set -e

# Get kernel version string from out/.config or binary
KERNEL_VERSION=""
if [ -f "out/.config" ]; then
  LOCALVERSION=$(grep "^CONFIG_LOCALVERSION=" out/.config | cut -d'"' -f2)
  KERNEL_VERSION="4.14.357${LOCALVERSION}"
elif [ -f "out/include/generated/utsrelease.h" ]; then
  KERNEL_VERSION=$(grep -o '"[^"]*"' out/include/generated/utsrelease.h | tr -d '"')
fi
KERNEL_VERSION="${KERNEL_VERSION:-4.14.357-Phrolova🎻}"

# Get KSU info
if [ -f "resukisu/kernel/Kbuild" ]; then
  KSU_VERSION=$(grep "KSU_VERSION_NUM" resukisu/kernel/Kbuild | sed 's/.*:= *//')
  KSU_TAG=$(grep "KSU_TAG_NAME" resukisu/kernel/Kbuild | sed 's/.*:= *//')
fi
KSU_VERSION="${KSU_VERSION:-35114}"
KSU_TAG="${KSU_TAG:-v4.2.0-rc1}"

cp changelog.md release_body.md

cat >> release_body.md << EOF

---

## 🎻 Phrolova Kernel for Redmi 10 2022 (selene)

| Info | Value |
|---|---|
| **Kernel** | \`${KERNEL_VERSION}\` |
| **SoC** | MediaTek Helio G88 (MT6768) |
| **Root** | ReSukiSU ${KSU_TAG} · KSU_VERSION \`${KSU_VERSION}\` |
| **Hook** | Manual Hook (non-GKI 4.14) |
| **Systemless** | NoMount v20 (keyring + VFS hijack) |
| **Toolchain** | Greenforce Clang 24.0.0 |
| **Base** | MiCode \`selene-r-oss-update\` + OpenELA LTS |

### 📦 Downloads

| File | Description |
|---|---|
| \`Phrolova-selene-*.zip\` | Kernel zip (AnyKernel3) |
| \`nm\` | NoMount userspace binary (static arm64) |

### ⚡ Features

- ✅ Boot, Audio, Touch, WiFi/BT/Data, Charging, Fingerprint, Sensors, Camera
- ✅ Root (ReSukiSU + NoMount)
- ✅ BBR TCP congestion, ZSTD ZRAM, BFQ I/O scheduler
- ✅ ARM64 crypto extensions (hardware AES)
- ❌ IR blaster, VoLTE, Video recording, NFC (untested)

### 📱 Manager & Modules

> **⚠️ Version matching required:** Manager APK dan NoMount module harus compatible dengan KSU_VERSION kernel.

| Component | Version | Link |
|---|---|---|
| ReSukiSU Manager | KSU_VERSION \`${KSU_VERSION}\` | [Nightly CI](https://t.me/ReSukiSU/5/276176) · [Telegram](https://t.me/ReSukiSU) |
| NoMount Module | v2.0.0 (kernel v20) | [GitHub Release](https://github.com/maxsteeel/nomount/releases/download/v2.0.0/NoMount-v2.0.0-release.zip) |

> **NoMount:** Kernel driver uses keyring (v20), NOT netlink. Module v1.x → false negative. Always use v2.0.0+.

### 🔧 Flash Instructions

1. Download \`Phrolova-selene-*.zip\` + \`nm\` binary
2. Reboot to recovery (TWRP/OrangeFox)
3. Flash kernel zip
4. Reboot to system
5. Install NoMount module v2.0.0 via KernelSU manager
6. Install ReSukiSU manager APK (match KSU_VERSION)
7. Reboot

### 📝 Notes

- **Universal zip** — works on MIUI/HyperOS and AOSP ROMs (LineageOS, crDroid, etc.)
- **UBL required** — bootloader must be unlocked
- **dtbo does not matter** — stock dtbo works

### Credits

- [@naidrahiqa](https://github.com/naidrahiqa) — Kernel maintainer
- [ReSukiSU](https://github.com/ReSukiSU/ReSukiSU) — Root solution
- [maxsteeel](https://github.com/maxsteeel/nomount) — NoMount
- [greenforce-project](https://github.com/greenforce-project) — Toolchain
- [osm0sis](https://github.com/osm0sis/AnyKernel3) — AnyKernel3
EOF
