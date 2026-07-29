# AGENTS.md — Selene Kernel (Phrolova Edition)

Baca file ini dulu sebelum kerja di repo ini. **File ini orchestrator** — untuk detail task, load skill terkait dari `.opencode/skills/*/SKILL.md`.

## Daftar Skill

| Skill | File | Trigger |
|---|---|---|
| **Selene Kernel** | `.opencode/skills/selene-kernel/SKILL.md` | **Master skill** — build, update, merge, KSU, NoMount, CI/CD, AK3 |
| AK3 Packaging | `.opencode/skills/selene-kernel/references/ak3.md` | AnyKernel3 packaging, anykernel.sh config, flash error debugging |
| AK3 Reverse Engineering | `.opencode/skills/ak3-reverse-engineering/SKILL.md` | Membandingkan anykernel.sh dengan zip kernel lain yang sudah terbukti work |
| CI/CD (GitHub Actions) | `.opencode/skills/ci-cd-github-actions/SKILL.md` | Setup/modify GitHub Actions workflows, Telegram notif, release automation |
| Versioning & Release | `.opencode/skills/versioning-release/SKILL.md` | Version scheme (nightly/stable/hotfix), changelog buat release, troubleshooting body kosong |
| Finishing Branch | `.opencode/skills/finishing-a-development-branch/SKILL.md` | Integrasi kerja setelah implementasi selesai — merge, PR, cleanup |
| Kernel Source Merge | `.opencode/skills/kernel-source-merge/SKILL.md` | Merge/compare MiCode base vs Ronald826 reference |
| Kernel Update | `.opencode/skills/kernel-update/SKILL.md` | Upgrade/downgrade kernel version (4.14.x), CVE patching |
| XXKSU Integration | `.opencode/skills/xxksu-integration/SKILL.md` | backslashxx/KernelSU integration, syscall table hook, KSU_VERSION, manager APK handling |
| NoMount | `.opencode/skills/nomount/SKILL.md` | maxsteeel/nomount systemless path redirection, iterate_dir hook fix, VFS injection |
| Build System Fixes | `.opencode/skills/build-system-fixes/SKILL.md` | Kconfig CRLF, Clang IAS, stpcpy, LTO, ZSTD, UAPI headers, 4.14 gotcha collection |
| Defconfig Management | `.opencode/skills/defconfig-management/SKILL.md` | Config dependency chains, known gotchas (HMP, THP, TASK_TURBO, SECTION_MISMATCH), defconfig debug workflow |
| Performance Tuning | `.opencode/skills/performance-tuning/SKILL.md` | Katalog fitur (THP, KSM, HMP, SQUASHFS, ZSWAP, dll), tradeoff notes, referensi defconfig |
| CI/CD Debug Workflow | `.opencode/skills/ci-cd-debug-workflow/SKILL.md` | Step-by-step debug CI build failure: ambil log, parse error, fix, re-run |
| Windows Compatibility | `.opencode/skills/windows-compatibility/SKILL.md` | NTFS case-folding, xt_hl.c vs xt_HL.c, reserved filenames, git index manipulation |
| SELinux Policy | `.opencode/skills/selinux-policy/SKILL.md` | KernelSU device node context, NoMount SELinux implications, debugging denials |
| MTK FPSGO v3 | `.opencode/skills/mtk-fpsgo/SKILL.md` | FPSGO v3 gaming framework components, known bugs (fpsgo_debugfs_dir), build fixes |
| Linux Container | `.opencode/skills/linux-container/SKILL.md` | Droidspaces-OSS integration, namespace/cgroup kernel requirements, verification |
| Skill Creator | `.opencode/skills/skill-creator/SKILL.md` | Membuat atau update SKILL.md baru |
| Git Worktrees | `.opencode/skills/using-git-worktrees/SKILL.md` | Isolasi workspace via git worktree untuk fitur baru |

**Cara pakai:** Saat dapat task, load **Selene Kernel** skill dulu — dia mencakup semua aspek project. Skill lain hanya untuk task spesifik.

## Konteks Project

- **Device:** Redmi 10 2022, codename **selene**, MediaTek Helio G88 (MT6768).
- **Kernel:** Linux 4.14.356 (yuki-saisei base), **non-GKI**. Banyak API beda drastis dari 5.x/6.x — jangan apply patch GKI 5.10+ tanpa cek dulu.
- **Root solution:** backslashxx/KernelSU v3.2.5-46 (fork tiann/KernelSU).
  - **Hook mode: Syscall Table Hook** (`CONFIG_KSU_TAMPER_SYSCALL_TABLE=y`) — langsung hook syscall table, bukan Manual Hook. Tidak perlu patch fs/ manual.
  - `CONFIG_KSU_KPROBES_KSUD=n` — kprobes broken di non-GKI 4.14.
  - Multi-manager support: `CONFIG_KSU_MULTI_MANAGER_SUPPORT=y` — terima manager dari tiann, backslashxx, ReSukiSU, MKSU, RKSU.
- **Systemless path redirection:** NoMount (`maxsteeel/nomount`).
  - Virtual file injection + path redirection tanpa mount filesystem.
  - Compiled into kernel (`CONFIG_NOMOUNT=y`), netlink-based userspace control.
- **Build variants:** Single universal kernel — works on MIUI/HyperOS and AOSP-based ROMs (LineageOS, crDroid, etc.). Satu zip buat semua.
- **Bootloader:** Masih locked. Tidak ada device testing sampai unlock manual. Semua validasi = compile-time saja.

## Source of Truth

- Base kernel: `MiCode/Xiaomi_Kernel_OpenSource`, branch `selene-r-oss-update`.
- Reference-only: `Ronald826/xiaomi_kernel_selene`, branch `4.14-baxter_EXPERIMENTAL` (jangan merge mentah).
- KernelSU: `backslashxx/KernelSU` v3.2.5-46 (local copy di `backslash-ksu/kernel/`).
- NoMount: `maxsteeel/nomount` (source di `fs/nomount.c` + `fs/nomount.h`).

## Dokumentasi Project

- [CHANGELOG.md](file:///D:/Dev/Project-Coding/2026/7Juli/android_kernel_xiaomi_selene/CHANGELOG.md) — Record cherry-pick & versi rilis kernel.
- [docs/OPTIMIZATIONS.md](file:///D:/Dev/Project-Coding/2026/7Juli/android_kernel_xiaomi_selene/docs/OPTIMIZATIONS.md) — Detail optimasi BBR, ZSTD ZRAM, & BFQ I/O.
- [FIX_PROMPT.md](file:///D:/Dev/Project-Coding/2026/7Juli/android_kernel_xiaomi_selene/FIX_PROMPT.md) — Panduan perbaikan cepat jika terjadi masalah kompilasi.

## Build Commands (Greenforce Clang 24.0.0)

```bash
# Install deps
sudo apt-get install -y bc bison build-essential flex \
  libssl-dev libelf-dev zstd python3 \
  binutils-aarch64-linux-gnu zip

# Setup Greenforce Clang (CI uses get_clang.sh)
bash <(wget -qO- https://raw.githubusercontent.com/greenforce-project/greenforce_clang/refs/heads/main/get_clang.sh)
export PATH="$(pwd)/greenforce-clang/bin:$PATH"

# Setup KernelSU symlink (wajib sebelum build)
ln -sf "$(realpath backslash-ksu/kernel)" drivers/kernelsu

# Build
make O=out ARCH=arm64 CC=clang HOSTCC=gcc \
  CROSS_COMPILE=aarch64-linux-gnu- selene_defconfig
make O=out ARCH=arm64 CC=clang HOSTCC=gcc \
  CROSS_COMPILE=aarch64-linux-gnu- -j$(nproc)
```

**Output:** `out/arch/arm64/boot/Image.gz` → packaged as `Phrolova-selene-{tag}.zip`

## Branches

| Branch | Purpose |
|---|---|
| `selene-r-oss-update` | Base (MiCode origin) |
| `m1-cherrypick` | Cherry-picks dari Ronald826 |
| `phrolova` | Main development branch |

## CI Pipeline (`.github/workflows/build.yml`)

- Trigger: push ke `selene-r-oss-update`, `m1-cherrypick`, `phrolova`, atau manual dispatch.
- Runner: `ubuntu-24.04` + Docker hybrid (Void Linux build env)
- Toolchain: Greenforce Clang 24.0.0 (`CC=clang HOSTCC=gcc`)
- KernelSU: backslashxx v3.2.5-46 via `drivers/kernelsu` symlink
- CI matrix: **Single build** (universal kernel, 1 zip fits all)
- Telegram notifications: ObsidianKernel-style format with credits/download links
  - Start/success/failed (error log ke `TELEGRAM_ERROR_CHANNEL_ID` channel terpisah)
- Version: `.github/scripts/version.sh` (nightly/stable/hotfix)
  - Nightly: `v{base}-nightly.YYYYMMDD` — base version dinaikin tiap ada fitur baru
  - Stable: `v{base}` — rilis stabil
  - Hotfix: `v{base+1}` — patch untuk stable
  - Trigger manual via `workflow_dispatch` bisa set `base_version` (e.g. 0.3.0)
- Changelog: `.github/scripts/generate-changelog.sh` (commit-type based)
- Artifact naming: `Phrolova-selene-{tag}.zip`
- Release body: clean table format with device info + changelog + flash instructions

## Known Gotchas (Hard-Won Context)

### Clang IAS Binding Errors
Clang IAS rejects changing symbol binding from STB_WEAK to STB_GLOBAL.
Affected files (all fixed):
- `arch/arm64/lib/memcpy.S`: `.weak memcpy` → `.globl memcpy`
- `arch/arm64/lib/memmove.S`: `.weak memmove` → `.globl memmove`
- `arch/arm64/lib/memset.S`: `.weak memset` → `.globl memset`

### Clang 23 stpcpy
Clang 23 optimizes `strcpy` + pointer arithmetic into `stpcpy()` calls.
Kernel 4.14 doesn't provide `stpcpy` for arm64. Fix: added generic
implementation in `lib/string.c` + declaration in `include/linux/string.h`.
If switching to a different Clang version, check if this is still needed.

### Clang 23 LTO Bitcode Mismatch
- `CONFIG_LTO_CLANG=y` menyebabkan LLVM 23.0.0 (compiler) menghasilkan LTO bitcode `.o` yang gagal di-link oleh LLVM 16.0.6 system linker di CI.
- Fix: `# CONFIG_LTO_CLANG is not set` di `selene_defconfig` dan hapus override `LD=ld.lld` di `.github/workflows/build.yml` agar menggunakan standard `aarch64-linux-gnu-ld`.

### ZSTD_STATIC_ASSERT Clang 23 Fix
- `lib/zstd/zstd_internal.h` memiliki macro `ZSTD_STATIC_ASSERT` dengan enum pembagian nol (`1 / 0`) yang ditolak oleh Clang 23.
- Fix: diganti dengan C11 `_Static_assert((c), "ZSTD_STATIC_ASSERT")`.

### Clang + kernel 4.14 Compatibility
- Greenforce Clang 24.0.0 (LLVM trunk) works with kernel 4.14 arm64 **only if**:
  - Top-level `Makefile` CLANG_FLAGS does NOT contain `-no-integrated-as` — Clang IAS handles `-EL` natively. Per-file `-no-integrated-as` only where needed (e.g., `aes-ce.o` for 68-bit literal).
  - `GCC_TOOLCHAIN_DIR` detection uses `$(CROSS_COMPILE)as` (not `$(CROSS_COMPILE)elfedit` which may not exist).
  - `HOSTCC=gcc` — host tools need real GCC (not Clang) for some build scripts.
- VDSO `gettimeofday.S`: `clock_gettime_return, shift=1` must be `clock_gettime_return 1` (positional args) — Clang IAS doesn't support named macro args.
- `arch/arm64/crypto/aes-modes.S`: 68-bit literal `0x30000000200000001` exceeds Clang IAS range → fixed with explicit lane construction using `mov/dup`.
- Zyc Clang (15.0.7) is incompatible with kernel 4.14 arm64 asm — clang support added in 4.19+. Not usable.
- Zyc/Electron/Neutron Clang 16+ may work (not tested). Greenforce Clang 24 is the validated toolchain.

### GCC 13 Compatibility (if reverting)
- GCC 13 promotes many new warnings to `-Werror` on vendor drivers. Strategy: `-Wno-error` in `scripts/Makefile.lib` `orig_c_flags`.
- Without `-Wno-error`: `CONFIG_CC_STACKPROTECTOR_STRONG` fails, `CONFIG_BLK_INLINE_ENCRYPTION` broken.

### KernelSU (backslashxx) Integration
- Source: `backslash-ksu/kernel/` (direct copy, not submodule). Current: v3.2.5-46.
- Symlink: `ln -sf backslash-ksu/kernel drivers/kernelsu` — created at CI time, not in git.
- `drivers/Kconfig`: already has `source "drivers/kernelsu/Kconfig"` (line 225).
- `drivers/Makefile`: already has `obj-$(CONFIG_KSU) += kernelsu/` (line 194).
- Uses `KSU_TAMPER_SYSCALL_TABLE=y` — hooks syscall table directly. NO manual hooks in fs/ needed.
- `KSU_KPROBES_KSUD=n` — kprobes broken on non-GKI 4.14.
- v3.2.5-46 added tristate KSU option (LKM support), fixes 32-on-64 adb_root.
- Multi-manager support: manager bebas — tiann, backslashxx, ReSukiSU, MKSU, RKSU.

### NoMount Integration
- Source: `maxsteeel/nomount` — kernel-level path redirection + virtual file injection.
- Compiled as `fs/nomount.c` + `fs/nomount.h`, enabled via `CONFIG_NOMOUNT=y`.
- VFS hooks in: `fs/dcache.c` (d_path), `fs/namei.c` (getname, permission), `fs/readdir.c` (iterate_dir), `fs/stat.c` (vfs_getattr), `fs/statfs.c` (vfs_statfs), `fs/proc/task_mmu.c` (mmap metadata).
- Netlink-based userspace control (genetlink family "nomount").
- All hooks wrapped in `#ifdef CONFIG_NOMOUNT` guards.

### Missing UAPI Headers
- `include/uapi/linux/netfilter/xt_connmark.h` dan `xt_mark.h` — harus dibuat manual.
- `xt_dscp.h` / `xt_DSCP.h` — shared file (same on disk, NTFS case-insensitive). Contains all 4 structs.

### xt_hl.c Deleted During Rebase
- `net/netfilter/xt_hl.c` (hop limit match module) was accidentally deleted during rebase onto yuki-saisei.
- This file is needed because `IP_NF_MATCH_TTL` and `IP6_NF_MATCH_HL` Kconfigs `select NETFILTER_XT_MATCH_HL`, which force-enables compilation of `xt_hl.o` regardless of `CONFIG_NETFILTER_XT_MATCH_HL=n` in defconfig.
- Fix: restore `xt_hl.c` from parent commit (`5b0b7cf324~1`).
- **Windows NTFS caveat:** `xt_hl.c` (lowercase, match module) and `xt_HL.c` (uppercase, target module) collide on case-insensitive NTFS. On Linux CI they're separate files. On Windows, only one can exist on disk at a time — use `git update-index --add --cacheinfo` to add `xt_hl.c` to git index without disk collision.

### CONFIG_TRACEPOINTS Required for FPSGO
- FPSGO GPU driver (`drivers/misc/mediatek/performance/fpsgo_v3/fbt/src/xgf.c`) uses kernel tracepoints (`__tracepoint_ipi_entry`, `__tracepoint_sched_switch`, `tracepoint_probe_register`, etc.).
- Without `CONFIG_TRACEPOINTS=y`, these symbols are undefined → vmlinux link fails with 60+ `undefined reference` errors.
- Fix: add `CONFIG_TRACEPOINTS=y` to `selene_defconfig`.

### AnyKernel3 Packaging — Match Tendou-Arisu
- CI pin ke commit `dca9dc3` (sebelum backwards compat removal `cea8f97`).
- **anykernel.sh WAJIB**:
  - Lowercase vars: `block=auto`, `is_slot_device=auto`, `ramdisk_compression=auto`, `patch_vbmeta_flag=auto`
  - `boot_attributes()` — bukan `attributes()`
  - **JANGAN override** fungsi AK3 (`unpack_ramdisk`, `dump_boot`, dll)
- Flash error "Unable to determine partition": cek variable case match AK3 version.
- Flash error "New image larger than target partition": tanda ada override AK3 yang ngerusak ramdisk — revert ke default.
- Referensi: `.opencode/skills/selene-kernel/references/ak3.md`.

### Droidspaces Container Runtime
- **Fully compatible** with kernel 4.14.356 non-GKI + KernelSU.
- [Droidspaces-OSS](https://github.com/ravindu644/Droidspaces-OSS): lightweight LXC-like container runtime for Android/Linux. Run full Linux distros (Ubuntu, Debian, Alpine) natively.
- Requirements: root (KernelSU recommended), kernel 3.10+ with namespace/cgroup support.
- Single static binary ~400KB, zero dependencies, musl libc.
- Features: full namespace isolation, systemd/OpenRC, NAT/host networking, GPU acceleration (VirGL/Turnip), PulseAudio.
- Users can install Droidspaces on selene to run server workloads, dev environments, or full desktop Linux.

### GOODIX_FINGERPRINT + FPC
- GOODIX: Prebuilt `gf_spi_tee.o_shipped` depends on `__stack_chk_guard` → disabled via `# CONFIG_GOODIX_FINGERPRINT is not set`.
- FPC: `CONFIG_FPC_FINGERPRINT` depends on `spi_fingerprint` + `goodix_fp_exist` symbols from Goodix. Both disabled.
- If re-enabling: need to provide stubs or rebuild without `-fstack-protector-strong`.

### Sparse Checkout / Windows
- Reserved NTFS filenames (`aux.c`, `aux.h` di nouveau/soc/arc) — pakai sparse checkout atau Linux.

## Prinsip Kerja

1. **Cek API di source tree dulu** (`grep -r`) sebelum nulis patch. Jangan asumsikan API modern ada di 4.14.
2. **Setiap cherry-pick wajib dicatat** di `CHANGELOG.md`: commit hash, file, alasan. Tidak ada silent merge.
3. **CI-first.** Semua perubahan harus lolos GitHub Actions. Build merah = blocker.
4. **Tidak ada device testing** sampai bootloader unlock. Semua = compile-verified artifact ready.

## Kernel Update Workflow

- **Script:** `scripts/update_kernel_selective.sh` — selective update, skip Xiaomi-modified files
- **Workflow:** `.github/workflows/update-kernel.yml` — manual trigger, `workflow_dispatch`
- **Source:** kernel.org (≤4.14.336) / OpenELA LTS (>4.14.336)
- **Logic:** Compare repo file vs vanilla 4.14.186 — if identical → replace with target version. If different (Xiaomi modified) → skip.
- **Skip list:** `net/wireguard/`, `backslash-ksu/`, `fs/nomount.*`, `lib/string.c`, `selene_defconfig`, `arch/arm64/lib/{memcpy,memmove,memset}.S`, `arch/arm64/crypto/aes-modes.S`, `include/uapi/linux/netfilter/xt_*.h`, `drivers/goodix/`, `drivers/fpc1020/`, `drivers/misc/mediatek*/`
- **Target versions:** Configurable via `workflow_dispatch` input. Default: latest stable below 350.
- **Known issue:** 4.14.357+ has blank screen issue on MTK devices (screen blank, system alive, need power cycle).

## Escalation

Tanyakan ke Naidra sebelum lanjut kalau:
- Nemu konflik patch MiCode vs Ronald826 yang gak jelas.
- Butuh vermagic/kernel version string exact-match vendor MIUI 12.5.20.
- Toolchain decision belum final.
