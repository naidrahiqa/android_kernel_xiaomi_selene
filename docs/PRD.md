# Phrolova Kernel — Product Requirements Document

## 1. Product Overview

| Field | Value |
|---|---|
| Product | Phrolova Kernel for Redmi 10 2022 (selene) |
| Codename | Phrolova |
| Device | Redmi 10 2022, MediaTek Helio G88 (MT6768) |
| Kernel Base | Linux 4.14.356, non-GKI |
| Target Users | MIUI/HyperOS & AOSP custom ROM users |
| Distribution | AnyKernel3 flashable zip (single universal build) |

## 2. Purpose & Goals

Provide a stable, performant, and feature-rich custom kernel for Redmi 10 2022 that balances battery efficiency with daily-driver reliability. Primary differentiators: KernelSU root + NoMount systemless redirection — no Magisk/ramdisk modification required.

## 3. Core Features

| Feature | Status | Priority |
|---|---|---|
| **KernelSU** (KernelSU-Next v3.3.0, syscall table hook + sys_enter tracepoint) | Implemented | P0 |
| **NoMount** (systemless path redirection) | Implemented | P0 |
| ZRAM with ZSTD compression | Implemented | P0 |
| TCP BBR congestion control | Implemented | P0 |
| BFQ I/O scheduler (default) | Implemented | P0 |
| WireGuard VPN | Implemented | P1 |
| FPSGO GPU optimization | Implemented | P1 |
| CI/CD automated builds (GitHub Actions) | Implemented | P0 |
| Telegram build notifications | Implemented | P1 |
| AnyKernel3 MTK A/B slot fix | Implemented | P0 |
| Clang 24 compatibility (Greenforce) | Implemented | P0 |
| Kernel 4.14.x update workflow | Implemented | P1 |
| Power-efficient scheduling (SCHEDUTIL + ENERGY_MODEL) | Implemented | P1 |
| Kprofiles power profile manager | Implemented | P1 |
| Simple LMK (low memory killer) | Implemented | P1 |
| ARM NEON SIMD acceleration | Implemented | P1 |
| TTL/Hotspot tethering fix | Implemented | P1 |
| Droidspaces container runtime compatible | Verified | P2 |

## 4. Target Configurations

| Config | Value |
|---|---|
| Clang | Greenforce Clang 24.0.0 |
| KernelSU | KernelSU-Next v3.3.0, CONFIG_KSU=y + EXT4_FS/MODULES (hookless-only, KPROBES=n) |
| NoMount | CONFIG_NOMOUNT=y |
| RAM | LZ4 + ZSTD ZRAM |
| Filesystems | EXT4, F2FS, EXFAT, NTFS, OVERLAY_FS |
| Build | Universal (MIUI/HyperOS + AOSP) |
| Packaging | AnyKernel3 with `block=auto` (KernelSU Manager v3.3.0 compatible) |
| Container Runtime | Droidspaces-OSS verified (kernel 4.14 non-GKI fully supported) |

## 5. Quality Requirements

- **Build**: Must compile cleanly with Greenforce Clang 24.0.0 (no warnings-as-errors)
- **CI**: All builds must pass on GitHub Actions before tagged release
- **Partition**: Must detect and flash to correct A/B slot on MT6768
- **Root**: KernelSU-Next manager APK wajib (tiann/backslashxx/RKSU/MKSU manager tidak kompatibel)
- **SafetyNet**: NoMount provides systemless path redirection without modifying /system

## 6. Constraints

- **No device testing** — bootloader still locked. All validation = compile-time only
- **No GKI patches** — kernel 4.14 non-GKI, many APIs differ from 5.x/6.x
- **Kprobes optional** — KernelSU-Next kprobes (reboot supercall, avc_spoof, input event) fail-safe; core root = syscall table + tracepoint
- **No LTO** — `CONFIG_LTO_CLANG=n`, LLVM bitcode mismatch between Clang 23 and system LLD
- **No xt_hl.c** — must be restored manually after rebase (deleted by yuki-saisei)
