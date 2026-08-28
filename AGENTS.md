# AGENTS.md — Selene Kernel (Phrolova Edition)

Baca file ini dulu sebelum kerja di repo ini. **File ini orchestrator** — untuk detail task, load skill terkait dari `.opencode/skills/*/SKILL.md`.

## Daftar Skill

| Skill | File | Trigger |
|---|---|---|
| **Selene Kernel** | `.opencode/skills/selene-kernel/SKILL.md` | **Master skill** — build, update, merge, KSU, NoMount, CI/CD, AK3 |
| KSU Version Management | `.opencode/skills/ksu-version-management/SKILL.md` | Update ReSukiSU driver, sync source, bump version, keep docs in sync |
| AK3 Packaging | `.opencode/skills/selene-kernel/references/ak3.md` | AnyKernel3 packaging, anykernel.sh config, flash error debugging |
| AK3 Reverse Engineering | `.opencode/skills/ak3-reverse-engineering/SKILL.md` | Membandingkan anykernel.sh dengan zip kernel lain yang sudah terbukti work |
| ReSukiSU Manager Link | `.opencode/skills/resukisu-manager-link/SKILL.md` | Update KSU_VERSION + manager link di CI scripts, docs, defconfig |
| CI/CD (GitHub Actions) | `.opencode/skills/ci-cd-github-actions/SKILL.md` | Setup/modify GitHub Actions workflows, Telegram notif, release automation |
| Versioning & Release | `.opencode/skills/versioning-release/SKILL.md` | Version scheme (nightly/stable/hotfix), changelog buat release, troubleshooting body kosong |
| Finishing Branch | `.opencode/skills/finishing-a-development-branch/SKILL.md` | Integrasi kerja setelah implementasi selesai — merge, PR, cleanup |
| Kernel Source Merge | `.opencode/skills/kernel-source-merge/SKILL.md` | Merge/compare MiCode base vs Ronald826 reference |
| Kernel Update | `.opencode/skills/kernel-update/SKILL.md` | Upgrade/downgrade kernel version (4.14.x), CVE patching |
| ReSukiSU Integration | `.opencode/skills/resukisu-integration/SKILL.md` | ReSukiSU integration, manual hooks (non-GKI), KSU_VERSION pin, manager APK handling |
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
- **Root solution:** ReSukiSU (`ReSukiSU/ReSukiSU`, fork SukiSU-Ultra, main @ `25d94deb` = v4.2.0-rc1 + 32 commits, **KSU_VERSION 35097**).
  - **Hook mode: manual hook (`CONFIG_KSU_MANUAL_HOOK=y`)** — TP-hook (syscall table) cuma GKI 5.10+; di non-GKI 4.14 wajib manual hook. Patch manual di: `fs/exec.c` (`ksu_handle_execveat`), `fs/open.c` (`ksu_handle_faccessat`), `fs/stat.c` (`ksu_handle_stat`/`ksu_handle_newfstat_ret`/`ksu_handle_fstat64_ret`), `kernel/reboot.c` (`ksu_handle_sys_reboot`). setuid/initrc/read via LSM (`KSU_MANUAL_HOOK_AUTO_SETUID_HOOK`/`AUTO_INITRC_HOOK`) + input via input_handler (`AUTO_INPUT_HOOK`) — otomatis, default y (<6.8). `manual_hook_check.mk` meng-verify tiap hook saat build — hook hilang = compile error.
  - Kbuild di-patch lokal: fallback version pin tanpa `.git` (`KSU_LOCAL_VERSION := 4397`, tag `v4.2.0-rc1`, sha `25d94deb`, branch `main`). `CONFIG_KPROBES` tidak dibutuhkan; `CONFIG_EXT4_FS=y` dipertahankan.
  - **Manager:** `CONFIG_KSU_MULTI_MANAGER_SUPPORT=y` (default) — manager KernelSU/MKSU/RKSU/SukiSU-Ultra bisa dipakai. Disarankan **ReSukiSU manager** (nightly.link build-manager / t.me/ReSukiSU) — match KSU_VERSION 35097.
- **Systemless path redirection:** NoMount (`maxsteeel/nomount`).
  - Virtual file injection + path redirection tanpa mount filesystem.
  - Compiled into kernel (`CONFIG_NOMOUNT=y`), keyring-based userspace control.
- **Build variants:** Single universal kernel — works on MIUI/HyperOS and AOSP-based ROMs (LineageOS, crDroid, etc.). Satu zip buat semua.
- **Bootloader:** UBL'd. Device testing via ADB available.

## Source of Truth

- Base kernel: `MiCode/Xiaomi_Kernel_OpenSource`, branch `selene-r-oss-update`.
- Reference-only: `Ronald826/xiaomi_kernel_selene`, branch `4.14-baxter_EXPERIMENTAL` (jangan merge mentah).
- ReSukiSU: `ReSukiSU/ReSukiSU` main @ `25d94deb` (local copy di `resukisu/kernel/`).
- NoMount: `maxsteeel/nomount` (source di `fs/nomount.c` + `fs/nomount.h`).

## Dokumentasi Project

- [CHANGELOG.md](CHANGELOG.md) — Record cherry-pick & versi rilis kernel.
- [docs/OPTIMIZATIONS.md](docs/OPTIMIZATIONS.md) — Detail optimasi BBR, ZSTD ZRAM, & BFQ I/O.
- [docs/HOOK_MODES.md](docs/HOOK_MODES.md) — Perbandingan hook mode root solution: ReSukiSU manual hook (non-GKI) vs TP-hook (GKI2).
- [FIX_PROMPT.md](FIX_PROMPT.md) — Panduan perbaikan cepat jika terjadi masalah kompilasi.

## Build Commands (Greenforce Clang 24.0.0)

```bash
# Install deps
sudo apt-get install -y bc bison build-essential flex \
  libssl-dev libelf-dev zstd python3 \
  binutils-aarch64-linux-gnu gcc-aarch64-linux-gnu zip

# Setup Greenforce Clang (CI uses get_clang.sh)
bash <(wget -qO- https://raw.githubusercontent.com/greenforce-project/greenforce_clang/refs/heads/main/get_clang.sh)
export PATH="$(pwd)/greenforce-clang/bin:$PATH"

# Setup ReSukiSU symlink (wajib sebelum build)
ln -sf "$(realpath resukisu/kernel)" drivers/kernelsu

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
- ReSukiSU: ReSukiSU main @ `25d94deb` via `drivers/kernelsu` symlink (manual hook, non-GKI)
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
- **KSU auto-extract:** `.github/scripts/get_ksu_info.sh` parses `resukisu/kernel/Kbuild` for `KSU_VERSION_NUM`, `KSU_TAG`, `KSU_COMMIT`, `KSU_BRANCH`. CI passes these as env vars to notify-telegram.sh. Fallback: script auto-extracts from Kbuild if env vars absent.

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

### ReSukiSU Integration
- Source: `resukisu/kernel/` (direct copy, not submodule). Current: main @ `25d94deb` (v4.2.0-rc1 + 32 commits, 4397 commits, **KSU_VERSION 35097**).
- Symlink: `ln -sf "$(realpath resukisu/kernel)" drivers/kernelsu` — created at CI time, not in git.
- `drivers/Kconfig`: already has `source "drivers/kernelsu/Kconfig"` (line 223).
- `drivers/Makefile`: already has `obj-$(CONFIG_KSU) += kernelsu/` (line 191).
- Kconfig: `CONFIG_KSU` (tristate, `select KALLSYMS`) — tidak ada `depends on KPROBES/EXT4_FS` di ReSukiSU. `CONFIG_EXT4_FS=y` dipertahankan (boot_event pakai ext4 helpers).
- **Hook mode: `CONFIG_KSU_MANUAL_HOOK=y`** (wajib non-GKI). TP-hook (`CONFIG_KSU_TRACEPOINT_HOOK`) **hard error** di Kbuild untuk Non-GKI/GKI1. Manual hooks di-patch di tree kernel:
  - `fs/exec.c` → `ksu_handle_execveat` di `do_execve` + `compat_do_execve`
  - `fs/open.c` → `ksu_handle_faccessat` di `SYSCALL_DEFINE3(faccessat)`
  - `fs/stat.c` → `ksu_handle_stat` di `newfstatat` + `fstatat64`; `ksu_handle_newfstat_ret` di `newfstat`; `ksu_handle_fstat64_ret` di `fstat64`
  - `kernel/reboot.c` → `ksu_handle_sys_reboot` di `SYSCALL_DEFINE4(reboot)`
  - setuid/initrc(read)/input: **otomatis** via LSM/input_handler — `KSU_MANUAL_HOOK_AUTO_SETUID_HOOK`/`AUTO_INITRC_HOOK`/`AUTO_INPUT_HOOK` (default y, hanya untuk <6.8; kita 4.14 aman). Jangan patch `kernel/sys.c`/`fs/read_write.c`/`drivers/input/input.c` manual selama AUTO_* on.
  - `tools/manual_hook_check.mk` mem-verify SEMUA hook saat build (grep string di file kernel) — hook hilang/ekstra = compile error. Juga menolak hook lama (`ksu_vfs_read_hook`, `is_ksu_transition`, `ksu_handle_rename`).
- **Versi di-pin via fallback di `Kbuild`** (patch lokal — upstream `$(error ...)` kalau bukan git submodule): `KSU_LOCAL_VERSION := 4397`, `KSU_TAG_NAME := v4.2.0-rc1`, `KSU_COMMIT_SHA := 25d94deb`, `KSU_BRANCH_NAME := main`. Formula `KSU_VERSION = 30000 + commits + 700` → 35097. Jangan set ke 1 (manager tidak deteksi root).
- **Manager:** `CONFIG_KSU_MULTI_MANAGER_SUPPORT=y` (default) — manager KernelSU/MKSU/RKSU/SukiSU-Ultra diterima. Rekomendasi: ReSukiSU manager (nightly.link build-manager / t.me/ReSukiSU) — match KSU_VERSION.
- Compat layer: `tools/kernel_compat.mk` auto-detect API 4.14 (flex_array policydb, hashtab 3-arg, `struct selinux_ss`, status_lock global, dst) — tidak perlu port manual seperti KSU-Next dulu.
- Build system: `Kbuild` (bukan Makefile) — `kernelsu-objs` multi-file, bukan unity build.

### ReSukiSU 4.14 SELinux & Link Notes (referensi port)
Kontek 4.14 yang sudah ditangani upstream `kernel_compat.mk` + `compat/kernel_compat.c` (jangan revert):
- **Model policy:** `struct selinux_policy` + `selinux_state.policy` + `policy_mutex` hanya ada di 5.10+. 4.14 pakai `struct selinux_ss` (`security/selinux/ss/services.h`) — `sidtab`, `policydb`, `policy_rwlock`, `latest_granting`, `status_page`, `status_lock`. `rules.c`/`sepolicy.c`: di <5.10 aturan diedit **in-place** ke `selinux_state.ss->policydb` di bawah `policy_rwlock`; `ksu_dup/destroy_sepolicy` = stub no-op.
- **Policydb 4.14 pakai `flex_array`:** `te_avtab.htable`, `type_attr_map_array`, `type_val_to_struct_array`, `sym_val_to_name[SYM_TYPES]` bukan array langsung (flex_array baru 5.1 jadi array). Guard `KSU_COMPAT_HAS_MODERN_POLICYDB` dari `kernel_compat.mk` (flex_array ada di 4.14 → tidak di-set → branch legacy).
- **filename_trans:** `policydb_filenametr_search`/`filename_trans_key`/`filenametr_key_params` hanya 5.9+. <5.9 pakai `struct filename_trans` + hashtab **3-arg** (4.14 `hashtab.h` = `hashtab_insert(h,k,d)`). Guard `KSU_COMPAT_HAS_FILENAME_TRANS_KEY`/`KSU_COMPAT_HAS_HASHTAB_KEY_PARAMS`.
- **API 4.14 lain:** `path_mount` (5.9+) → wrapper `d_path()` + `do_mount()` + `set_fs(KERNEL_DS)`; `seccomp_filter_release` static → `put_seccomp_filter(current)`; `ktime_get_boottime_ts64` → `getboottime64()` (<5.6); `__poll_t` → `unsigned int` (<4.16); `status_lock`/`status_page` akses via `selinux_state.ss->` (<5.10).
- Kalau error API muncul, cek dulu guard di `tools/kernel_compat.mk` sudah cover atau belum — baru patch manual (lihat skill `linux-version-compat`).

### NoMount Integration
- Source: `maxsteeel/nomount` v20 — kernel-level path redirection + virtual file injection.
- Compiled as `fs/nomount.c` + `fs/nomount.h`, enabled via `CONFIG_NOMOUNT=y`.
- **Arsitektur v20:** dentry/inode/superblock operation hijacking + keyring control (`register_key_type("nomount")`, `SYS_ADD_KEY` syscall). TIDAK lagi pakai genetlink atau handle_* functions manual.
- VFS hooks dibersihkan (v0.9.4): semua panggilan `nomount_handle_*` dihapus dari `dcache.c`, `namei.c`, `readdir.c`, `stat.c`, `statfs.c`, `proc/task_mmu.c`. Interception otomatis via hijacked i_op/fop/s_op/d_op.
- **gnu89 requirement:** Kernel 4.14 compile `-std=gnu89` — semua `for (int i ...)` dalam satu fungsi harus dihoist (redefinition error).
- **ABI userspace berubah:** tool `nm` lama berbasis genetlink TIDAK kompatibel dengan v20. Wajib pakai binary `nm` baru (`tools/nomount/nm.c`, freestanding static arm64, raw `SYS_ADD_KEY` syscall). Di-build di CI & di-upload sebagai release asset kedua.
- **Module v2.0.0 required:** NoMount metamodule v1.x uses netlink detection → **false negative** on v20 kernels (keyring-based). Wajib pakai **NoMount module v2.0.0+** (`maxsteeel/nomount` v2.0.0 release). Download: `https://github.com/maxsteeel/nomount/releases/download/v2.0.0/NoMount-v2.0.0-release.zip`
- **Verification:** `nm version` should return `20`. If "KERNEL DRIVER NOT DETECTED" → wrong module version (v1.x), not a kernel issue.
- Kconfig vendor caveat: `drivers/misc/mediatek/Kconfig.default` punya `select TCP_CONG_BIC` yang bisa mengaktifkan BIC secara diam-diam — sudah dihapus di v0.9.4. CI gate memverifikasi absennya BIC post-build.

### Device Debugging Findings (2026-08-25, LOS20-unofficial hasan build)
Full live-debugging session via ADB on Redmi 10 2022 + LineageOS 20 (20.0-20250905-UNOFFICIAL-selene). Kernel 4.14.356-Phrolova boots clean: 0 panic, root/hooks OK. Temuan penting:

**ARTIFACT MISMATCH (kritis):** Kernel yang ter-flash menunjukkan config era lama (`cfq` default, tanpa dirty-ratio cmdline, `# USER_NS is not set`, `vmalloc=496M`) padahal source CI run-nya (`574a7669`, verified via `git show`) memuat semuanya (`bfq`, dirty-ratio, `USER_NS=y`, `vmalloc=320M`). Repro lokal `make selene_defconfig` menghasilkan config benar → **tree sehat; artefak yang dipakai user bukan dari run tersebut** (stale release asset / salah download zip lama). MITIGASI:
- Selalu verifikasi pasca-flash: `zcat /proc/config.gz | grep -E 'DEFAULT_IOSCHED|USER_NS'`.
- CI wajib punya verification gate + upload `.config` sebagai artifact (v0.9.3).

**ROM bug — soft reboot loop:** `NearbyService.onBootPhase` (A13 code di system_server) memanggil `ContextHubManager` tanpa guard → `Log.wtf("No service published for: contexthub")` tiap boot phase 600 karena vendor selene tidak punya HAL contexthub. Berkorelasi dengan SYSTEM_RESTART di dropbox. **Bukan bug kernel.** Report ke builder ROM.

**ROM bug — hotspot client tidak dapat internet:** netd meninggalkan `tetherctrl_counters` hanya berisi rule `RETURN` (tanpa ACCEPT per-pair) → koneksi baru forward jatuh ke `-j DROP` terakhir di `tetherctrl_FORWARD`. Fix manual terbukti: replace RETURN→ACCEPT untuk pasangan `ap0↔ccmniX` selama tethering aktif. HATI-HATI: mengedit chain milik netd mid-session berkorelasi 2x dengan framework restart — apply saat tether-up, jangan sambil klien aktif.

**Slow internet:** `/vendor/etc/init/networksetting.rc` (bawaan Huaqin) menulis `tcp_congestion_control=bic` di early-init, menimpa `CONFIG_DEFAULT_BBR=y`. Fix kernel v0.9.3: `# CONFIG_TCP_CONG_BIC is not set` sehingga sysctl write vendor gagal diam-diam.

**Fast charge diblok thermal HAL:** userspace menulis psy `CHARGE_CONTROL_LIMIT` → `charger_manager_set_prop_system_temp_level()` → tabel `thermal_mitigation_*` clamp QC/HVDCP ke 1.5A–900mA meski suhu aman. Fix v0.9.3: bypass tabel (ICL selalu -1). Keamanan baterai tetap oleh sw_jeita dts (T4=45°C) + hardware JEITA bq2589x.

**Layar mati sendiri:** cooler `mtk-cl-backlight` (`mtk_cooler_backlight_cus.c`) menerima tulisan `cur_state` dari daemon thermal userspace → `setMaxbrightness()` clamp/blank panel (terverifikasi: log `cooler/backlight 1610` tepat sebelum `FB_BLANK_POWERDOWN`). Fix v0.9.3: clamp dinetralkan, hanya jalur reset (state==max) dihormati. Mitigasi panas asli = cpufreq/GPU coolers, tidak disentuh.

**Log spam vendor (disilence v0.9.3, pr_err→pr_debug):** `io_boost` task file, `mtk_battery` otg boost check, keluarga polling `bq2589x` (id_dis/vbus_stat/detect_count), `hq_config()` printk, `chg_type_det` hvdcp poll. Normal & aman: `cert length overlimit` (scan APK GMS), package name manager acak (`dqobwk...` = spoofed multi-manager build).

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

## Kernel Update Workflow

- **Script:** `scripts/update_kernel_selective.sh` — selective update, skip Xiaomi-modified files
- **Workflow:** `.github/workflows/update-kernel.yml` — manual trigger, `workflow_dispatch`
- **Source:** kernel.org (≤4.14.336) / OpenELA LTS (>4.14.336)
- **Logic:** Compare repo file vs vanilla 4.14.186 — if identical → replace with target version. If different (Xiaomi modified) → skip.
- **Skip list:** `net/wireguard/`, `resukisu/`, `fs/nomount.*`, `lib/string.c`, `selene_defconfig`, `arch/arm64/lib/{memcpy,memmove,memset}.S`, `arch/arm64/crypto/aes-modes.S`, `include/uapi/linux/netfilter/xt_*.h`, `drivers/goodix/`, `drivers/fpc1020/`, `drivers/misc/mediatek*/`
- **Target versions:** Configurable via `workflow_dispatch` input. Default: latest stable below 350.
- **Known issue:** 4.14.357+ has blank screen issue on MTK devices (screen blank, system alive, need power cycle).

## Escalation

Tanyakan ke Naidra sebelum lanjut kalau:
- Nemu konflik patch MiCode vs Ronald826 yang gak jelas.
- Butuh vermagic/kernel version string exact-match vendor MIUI 12.5.20.
- Toolchain decision belum final.
