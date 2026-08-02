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
| KSU-Next Integration | `.opencode/skills/ksunext-integration/SKILL.md` | KernelSU-Next integration, syscall table hook, KSU_VERSION, manager APK handling |
| NoMount | `.opencode/skills/nomount/SKILL.md` | maxsteeel/nomount systemless path redirection, iterate_dir hook fix, VFS injection |
| Build System Fixes | `.opencode/skills/build-system-fixes/SKILL.md` | Kconfig CRLF, Clang IAS, stpcpy, LTO, ZSTD, UAPI headers, 4.14 gotcha collection |
| Linux Version Compat | `.opencode/skills/linux-version-compat/SKILL.md` | Porting kode upstream (KSU-Next dll) ke 4.14: peta `LINUX_VERSION_CODE` guard, API split points (4.15/4.16/4.17/5.4/5.6/5.11/6.12 dll), fallback 4.14 per file |
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
- **Root solution:** KernelSU-Next (`KernelSU-Next/KernelSU-Next`, fork tiann/KernelSU, latest dev @ `e7536f0`, tag v3.3.0).
  - **Hook mode: syscall table hook + sys_enter tracepoint** — dispatcher slot di-patch langsung ke `sys_call_table` (via `ksu_patch_text`), routing syscall via `register_trace_prio_sys_enter`. Tidak perlu patch fs/ manual.
  - `CONFIG_EXT4_FS=y` — wajib (Kconfig `depends on EXT4_FS`; KPROBES di-drop dari depends — **hookless-only**, `CONFIG_KPROBES=n`). Kprobes compiled-out: reboot supercall, avc spoof, key-event hook, kretprobe tracking mati — root core tidak terpengaruh.
  - **Manager tunggal:** KernelSU-Next manager APK (signature `EXPECTED_MANAGER_HASH` di Kbuild). Manager tiann/backslashxx/RKSU/MKSU **tidak** kompatibel.
- **Systemless path redirection:** NoMount (`maxsteeel/nomount`).
  - Virtual file injection + path redirection tanpa mount filesystem.
  - Compiled into kernel (`CONFIG_NOMOUNT=y`), netlink-based userspace control.
- **Build variants:** Single universal kernel — works on MIUI/HyperOS and AOSP-based ROMs (LineageOS, crDroid, etc.). Satu zip buat semua.
- **Bootloader:** Masih locked. Tidak ada device testing sampai unlock manual. Semua validasi = compile-time saja.

## Source of Truth

- Base kernel: `MiCode/Xiaomi_Kernel_OpenSource`, branch `selene-r-oss-update`.
- Reference-only: `Ronald826/xiaomi_kernel_selene`, branch `4.14-baxter_EXPERIMENTAL` (jangan merge mentah).
- KernelSU: `KernelSU-Next/KernelSU-Next` v3.3.0 @ `e7536f0` (local copy di `ksu-next/kernel/`).
- NoMount: `maxsteeel/nomount` (source di `fs/nomount.c` + `fs/nomount.h`).

## Dokumentasi Project

- [CHANGELOG.md](file:///D:/Dev/Project-Coding/2026/7Juli/android_kernel_xiaomi_selene/CHANGELOG.md) — Record cherry-pick & versi rilis kernel.
- [docs/OPTIMIZATIONS.md](file:///D:/Dev/Project-Coding/2026/7Juli/android_kernel_xiaomi_selene/docs/OPTIMIZATIONS.md) — Detail optimasi BBR, ZSTD ZRAM, & BFQ I/O.
- [docs/HOOK_MODES.md](file:///D:/Dev/Project-Coding/2026/7Juli/android_kernel_xiaomi_selene/docs/HOOK_MODES.md) — Perbandingan hook mode KernelSU-Next: hookless (syscall table + tracepoint) vs kprobes.
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
ln -sf "$(realpath ksu-next/kernel)" drivers/kernelsu

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
- **Docs-only push di-skip:** `paths-ignore: ['*.md', '**/*.md']` — commit yang cuma mengubah dokumentasi tidak memicu build/notif/release (mencegah release body tertimpa changelog "docs:" saja).
- Runner: `ubuntu-24.04` + Docker hybrid (Void Linux build env)
- Toolchain: Greenforce Clang 24.0.0 (`CC=clang HOSTCC=gcc`)
- KernelSU: KernelSU-Next v3.3.0 via `drivers/kernelsu` symlink
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

### KernelSU-Next Integration
- Source: `ksu-next/kernel/` (direct copy, not submodule). Current: v3.3.0 @ `e7536f0` (dev branch).
- Symlink: `ln -sf ksu-next/kernel drivers/kernelsu` — created at CI time, not in git.
- `drivers/Kconfig`: already has `source "drivers/kernelsu/Kconfig"` (line 225).
- `drivers/Makefile`: already has `obj-$(CONFIG_KSU) += kernelsu/` (line 194).
- Kconfig `depends on EXT4_FS` (KPROBES **dihapus** dari depends — patch lokal; upstream `depends on KPROBES && EXT4_FS`). `CONFIG_EXT4_FS=y` wajib.
- **Hookless-only:** `CONFIG_KPROBES=n` (bukan `=y` lagi). Kode kprobe di `ksu-next/kernel` di-guard `#ifdef CONFIG_KPROBES` (supercall.c reboot kprobe, ksud_integration.c input_event kprobe, extras.c avc_spoof, syscall_hook_manager.c kretprobe) — fitur opsional tsb compiled-out: reboot supercall via sys_reboot magic, avc spoof, key-event hook mati (manager fd-install tetap jalan via setuid hook).
- `CONFIG_MODULES=y` dipertahankan (parity defconfig MiCode asli).
- Hook mode: dispatcher slot di `sys_call_table` (via `ksu_patch_text`) + `register_trace_prio_sys_enter` — NO manual hooks in fs/ needed, NO kprobes.
- **Manager tunggal:** hanya KernelSU-Next manager APK. `KSU_NEXT_MANAGER_SIZE`/`KSU_NEXT_MANAGER_HASH` di `Kbuild` (default = signature KernelSU-Next manager).
- Versi di-pin via fallback di `Kbuild`: `KSU_VERSION_FALLBACK := 33227` (30000 + 3227 commits) dan `KSU_VERSION_TAG_FALLBACK := v3.3.0` — jangan set ke 1 (manager tidak deteksi root).
- Build system: `Kbuild` (bukan Makefile) — `kernelsu-objs` multi-file, bukan unity build.

### KernelSU-Next 4.14 SELinux & Link Port (v0.8.0-nightly.20260802)
Semua fix di bawah SUDAH diterapkan & build hijau. Jangan revert tanpa alasan.
- **Model policy:** `struct selinux_policy` + `selinux_state.policy` + `policy_mutex` hanya ada di 5.10+. 4.14 pakai `struct selinux_ss` (`security/selinux/ss/services.h`) — `sidtab`, `policydb`, `policy_rwlock`, `latest_granting`, `status_page`, `status_lock`. `rules.c`/`sepolicy.c`: macro `SELINUX_POLICY_INSTEAD_SELINUX_SS` hanya didefinisikan `>=5.10`; di bawahnya aturan diedit **in-place** ke `selinux_state.ss->policydb` di bawah `policy_rwlock`. `ksu_dup/destroy_sepolicy` = stub no-op <5.10. Reference: branch `legacy` KernelSU-Next.
- **Policydb 4.14 pakai `flex_array`:** `te_avtab.htable`, `type_attr_map_array`, `type_val_to_struct_array`, `sym_val_to_name[SYM_TYPES]` bukan array langsung (flex_array baru 5.1 jadi array). Helper `ksu_avtab_get_node`/`ksu_avtab_put_node` + branch flex_array di `add_type`.
- **filename_trans:** `policydb_filenametr_search`/`filename_trans_key`/`filenametr_key_params` hanya 5.9+. <5.9 pakai `struct filename_trans` + hashtab **3-arg** (4.14 `hashtab.h` = `hashtab_insert(h,k,d)`; hash/cmp disimpan di struct `hashtab`).
- **Link fixes:** `path_mount` (5.9+) → wrapper `d_path()` + `do_mount()` + `set_fs(KERNEL_DS)` (pola legacy `kernel/compat/kernel_compat.c`); `seccomp_filter_release` static di 4.14 → pakai `put_seccomp_filter(current)` (global di `kernel/seccomp.c:523`).
- **API 4.14 lain:** `ktime_get_boottime_ts64` → `getboottime64()` (<5.6); `__poll_t` → `unsigned int` (<4.16); `tasklist_lock`/`init_task` butuh `#include <linux/sched/task.h>`; `status_lock`/`status_page`/`status` akses via `selinux_state.ss->` (<5.10) di `feature/selinux_hide.c`.

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
- **Skip list:** `net/wireguard/`, `ksu-next/`, `fs/nomount.*`, `lib/string.c`, `selene_defconfig`, `arch/arm64/lib/{memcpy,memmove,memset}.S`, `arch/arm64/crypto/aes-modes.S`, `include/uapi/linux/netfilter/xt_*.h`, `drivers/goodix/`, `drivers/fpc1020/`, `drivers/misc/mediatek*/`
- **Target versions:** Configurable via `workflow_dispatch` input. Default: latest stable below 350.
- **Known issue:** 4.14.357+ has blank screen issue on MTK devices (screen blank, system alive, need power cycle).

## Escalation

Tanyakan ke Naidra sebelum lanjut kalau:
- Nemu konflik patch MiCode vs Ronald826 yang gak jelas.
- Butuh vermagic/kernel version string exact-match vendor MIUI 12.5.20.
- Toolchain decision belum final.
