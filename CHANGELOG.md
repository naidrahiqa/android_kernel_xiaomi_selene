# CHANGELOG

Catatan cherry-pick wajib (sesuai PRD §5 & AGENTS.md prinsip #2):
setiap patch yang diambil dari `ronald826/xiaomi_kernel_selene` (atau source
lain) HARUS dicatat di sini dengan commit hash asal + alasan.

Format:
```
- [commit hash asal] file/path: deskripsi singkat
  Alasan: ...
  Sumber: ronald826 / upstream / ref kernel MT6768 lain
```

## v0.9.9 — Security Hardening + OpenELA 4.14.357

- **OpenELA 4.14.357 security patches:** cherry-pick dari `openela/kernel-lts` linux-4.14.y
  - `81cba5e105` — inet: inet_defrag: prevent sk release while in use (sk_buff UAF fix)
  - `70649db160` — ima: Fix use-after-free on a dentry's dname.name
  - Skipped: `30c9d27783` + `a7cd6312e4` — clk: devm_clk_release (different implementation in our tree)
  - Skipped: `b418fc71a9` — ocfs2: fix slab-use-after-free (ocfs2 not enabled)
  - CVE-2026-31431 (CopyFail) NOT backported to 4.14 by OpenELA

- **SUBLEVEL bumped:** 356 → 357

- **SHADOW_CALL_STACK=y:** `arch/arm64/Kconfig`
  - ARM64 Shadow Call Stack protects function return addresses from overwrite.
  - Uses separate shadow stack for each thread, prevents ROP attacks.

- **IDLE_PAGE_TRACKING=y:** `mm/Kconfig`
  - Enables tracking of idle pages for memory management tuning.
  - Useful for profiling memory usage and optimizing memory cgroup limits.

- **Vendor log spam silenced:** pr_err→pr_debug in:
  - `drivers/misc/mediatek/io_boost/mtk_io_boost.c` (task write errors)
  - `drivers/power/supply/mediatek/battery/mtk_battery.c` (OTG boost check)
  - `drivers/power/supply/mediatek/charger/bq2589x_charger.c` (charger detection)
  - `drivers/power/supply/mediatek/charger/mtk_charger.c` (hq_jeita_config)
  - `drivers/power/supply/mediatek/charger/mtk_chg_type_det.c` (typec/OTG)
  - Normal operation logs (not errors) were spamming kernel log buffer.

- **PHROLOVA_BASE bumped:** 0.9.8 → 0.9.9.

## v0.9.8 — Security Hardening + ReSukiSU 35114

- **ReSukiSU 35114 (0b5efe9e01, v4.2.0-rc1+53):** `resukisu/kernel/`
  - KSU_LOCAL_VERSION 4404→4414, KSU_COMMIT_SHA 0b5efe9e01.
  - 10 commits baru dari upstream:
    - ksud: reuse ZIP archive and validate module IDs
    - ksud: call post_ota() only once after OTA flash
    - ksud: improve slot info parsing speed
    - kernel: synchronization the first track_throne of the late-load
    - build: bump ddk to 20260828, support android17-6.18
    - LICENSE updates, dependency bumps

- **STRICT_KERNEL_RWX=y:** `arch/Kconfig`
  - Marks kernel text as read-only, rodata as read-only+no-execute.
  - Prevents runtime modification of kernel code (rootkit injection, etc.).
  - **Overhead:** None (boot-time page table setup only).

- **BUG_ON_DATA_CORRUPTION DISABLED:** MTK vendor drivers punya benign list corruption → trigger `BUG()` → bootloop.
- **INIT_ON_ALLOC_DEFAULT_ON DISABLED:** MTK vendor drivers depend on uninitialized memory behavior → bootloop.
- **SLAB_FREELIST_HARDENED DISABLED:** MTK modem driver (CCCI/CLDMA) punya heap corruption (use-after-free) di `ccci_free_skb` → kernel panic setelah ~81 menit uptime. SLAB_FREELIST_HARDENED nangkep corruption, tapi modem crash = radio restart.
- **Sumber:** Device live debugging — bootloop + modem crash reproduction.

- **PHROLOVA_BASE bumped:** 0.9.7 → 0.9.8.

## v0.9.7 — Performance Tuning + ReSukiSU 35104

- **ReSukiSU 35104 (83614d892d, v4.2.0-rc1+43):** `resukisu/kernel/`
  - KSU_LOCAL_VERSION 4397→4404, KSU_COMMIT_SHA 83614d892d.
  - CI auto-extract: version 35104, tag v4.2.0-rc1, sha 83614d892d, branch main.
  - 7 commits baru dari upstream:
    - umount for webview zygote (kernel + ksud + manager)
    - selinux context in su (ksud)
    - selinux hide: spoof status page and avd seqno
    - Fix su identity argument handling
    - manager: fix android lints, update translations

- **BFQ default tuning:** `block/bfq-iosched.c`
  - `slice_idle` 8ms → 2ms (`NSEC_PER_SEC / 500`): kurangi idle wait eMMC, better multi-queue throughput saat game load asset.
  - `fifo_expire_sync` 250ms → 150ms (`150 * NSEC_PER_MSEC`): tighter sync expiry, background I/O gak block game I/O.
  - **Alasan:** eMMC 5.1 di Helio G88 gak butuh idle sepanjang HDD. BFQ defaults terlalu konservatif untuk mobile storage.
  - **Sumber:** Internal Phrolova performance tuning.

- **ZRAM ZSTD compression level:** `crypto/zstd.c`
  - `ZSTD_DEF_LEVEL` 3 → 5: ZSTD level 5 pakai `ZSTD_greedy` strategy → ~15-20% better compression ratio.
  - CPU overhead ~30% lebih tinggi tapi masih aman di Cortex-A75/A55 (MT6768).
  - **Alasan:** Lebih banyak data terkompresi di 2GB ZRAM → lebih sedikit app reload di 4GB RAM device.
  - **Sumber:** Internal Phrolova performance tuning.

- **MTK_PERF_OBSERVER=y:** `drivers/misc/mediatek/performance/observer/`
  - Performance metric aggregation hub untuk FPSGO/EARA thermal feedback.
  - reads EMI BW counters dari SSPM SRAM, fires notifier chain on bandwidth events.
  - **Risk:** Low — monitoring only, no hardware control.
  - **Sumber:** Stock MTK defconfig.

- **MTK_PERF_TRACKER=y:** `drivers/misc/mediatek/performance/`
  - Performance tracking framework, provides metrics consumed by FPSGO/GBE.
  - **Risk:** Low — informational only.
  - **Sumber:** Stock MTK defconfig.

- **MTK_RESYM=y:** `drivers/misc/mediatek/performance/resym/`
  - Resource Symphony — system resource coordination for performance.
  - **Risk:** Low — coordinates existing boost engines.
  - **Sumber:** Stock MTK defconfig.

- **MTK_SWPM=y:** `drivers/misc/mediatek/base/power/swpm_v1/`
  - Software Power Meter — per-rail average power estimation (VPROC12, VPROC11, VGPU, VCORE, VDRAM1, VDD1).
  - Uses 3 PMU counters per CPU + 1s timer for activity-based power modeling.
  - procfs: `/proc/swpm/` for power debugging.
  - **Risk:** Low-Medium — monitoring only, consumes 3 PMU counters per CPU.
  - **Sumber:** Stock MTK defconfig.

- **MTK_QOS_V1=y:** `drivers/misc/mediatek/base/power/mtk_qos/`
  - QoS framework for DRAM bandwidth management via SSPM IPI.
  - BW bound detector tracks congestive/full/free bandwidth states.
  - sysfs: `qos_bound_enable`, `qos_bound_status`.
  - **Risk:** Medium — controls DRAM OPP via BW prediction. SSPM firmware must be active.
  - **Dependencies:** `MTK_TINYSYS_SSPM_SUPPORT=y` (already set).
  - **Sumber:** Stock MTK defconfig.

- **MTK_RAM_CONSOLE=y:** `drivers/misc/mediatek/ram_console/`
  - Crash log persistence — writes to reserved DRAM region, survives reboots.
  - 26+ MTK drivers write diagnostic data (thermal, GPU freq, SPM, EEM, PPM, etc.).
  - Provides `/proc/last_kmsg` for crash forensics.
  - **Note:** DTS tanpa reserved memory entry → driver fails to init gracefully (no crash).
  - **Risk:** Low — console write to reserved memory only.
  - **Sumber:** Stock MTK defconfig.

- **PHROLOVA_BASE bumped:** 0.9.6 → 0.9.7.

## v0.9.6 — ReSukiSU 35097 + NoMount Module v2.0.0

- **ReSukiSU 35097 (25d94deb, v4.2.0-rc1+36):** `resukisu/kernel/Kbuild`
  - KSU_LOCAL_VERSION 4393→4397, KSU_COMMIT_SHA 25d94deb.
  - CI auto-extract: version 35097, tag v4.2.0-rc1, sha 25d94deb, branch main.

- **NoMount module v2.0.0 required:** Module v1.x (netlink detection) → false negative on v20 kernels (keyring).
  - Download: `https://github.com/maxsteeel/nomount/releases/download/v2.0.0/NoMount-v2.0.0-release.zip`
  - Verification: `nm version` should return `20`.

- **Release notif updated:** ReSukiSU manager link → Telegram post (`t.me/ReSukiSU/5/276176`), NoMount module link added, version matching warning.

- **PHROLOVA_BASE bumped:** 0.9.5 → 0.9.6.

## v0.9.5 — Phase 1: DT2W + Dynamic FPS + CI Auto-Extract KSU Version

- **DT2W (Double-Tap to Wake):** `drivers/input/touchscreen/mediatek/focaltech_touch_k19a/focaltech_config.h`
  - `FTS_GESTURE_EN` flipped 0→1 — mengaktifkan fitur gesture Focaltech untuk double-tap wake.
  - Gesture handling sudah ada di `focaltech_gesture.c` (Focaltech vendor driver) — hanya perlu enable di Kconfig.
  - **Sumber:** Focaltech vendor driver untuk selene (MT6768).

- **Dynamic FPS (DFRC):** `arch/arm64/configs/selene_defconfig`
  - `CONFIG_MTK_DYNAMIC_FPS_FRAMEWORK_SUPPORT=y` — mengaktifkan Dynamic Frame Rate Control driver (`drivers/misc/mediatek/dfrc/`).
  - Memungkinkan perubahan refresh rate dinamis berdasarkan konteks (game, video, idle).
  - **Sumber:** MTK vendor driver untuk MT6768.

- **USB Boost:** Sudah aktif — `drivers/misc/mediatek/usb_boost/` dikompilasi otomatis ketika `CONFIG_USB=y`. Tidak perlu perubahan defconfig.
  - **Sumber:** MTK vendor driver.

- **Vibrator:** Sudah aktif — `CONFIG_MTK_VIBRATOR=y` di defconfig. Tidak perlu perubahan.
  - **Sumber:** MTK vendor driver.

- **CI Auto-Extract KSU Version:** `.github/scripts/get_ksu_info.sh` (baru)
  - Script baru yang parse `resukisu/kernel/Kbuild` untuk extract `KSU_VERSION_NUM`, `KSU_TAG`, `KSU_COMMIT`, `KSU_BRANCH`.
  - CI workflow (`build.yml`) sekarang extract KSU info via step `ksu` → pass sebagai env vars ke `notify-telegram.sh`.
  - Fallback: script auto-extract dari Kbuild jika env vars tidak ada.
  - Notifikasi Telegram otomatis tampilkan versi KSU yang benar (tidak hardcode).

- **KSU update to 35093:** `resukisu/kernel/` updated to `7bb6f0df` (v4.2.0-rc1 + 32 commits).
  - Kbuild pin: `KSU_LOCAL_VERSION := 4393`, `KSU_COMMIT_SHA := 7bb6f0df`.
  - Bugfix: input hook sleep-in-atomic-context (ReSukiSU#363) — `ksu_stop_input_hook_runtime()` commented out, deferred to `on_post_fs_data`.

- **NoMount module v2.0.0 required:** Metamodule v1.x uses netlink detection → false negative on v20 kernels (keyring-based). Wajib pakai module v2.0.0+.
  - Download: `https://github.com/maxsteeel/nomount/releases/download/v2.0.0/NoMount-v2.0.0-release.zip`
  - Verification: `nm version` should return `20`.

- **Release notif updated:** ReSukiSU manager link changed to `nightly.link` (always latest), NoMount module v2.0.0 link added, version matching warning.

- **PHROLOVA_BASE bumped:** 0.9.4 → 0.9.5 di `build.yml` + `version.sh` fallback.

- **Sumber:** Internal Phrolova (Phase 1 features + CI automation + NoMount module fix).

## v0.9.4 — NoMount v20 Port + BBR Fix Regresi + Defconfig Hardening & Features

- **NoMount v20 port (dentry-op hijack + keyring control):** `fs/nomount.c` + `fs/nomount.h`
  - Upgrade dari v1.1.0 (genetlink + handle_* hooks) ke v20 (maxsteeel/nomount @ b8d26835).
  - Arsitektur baru: superblock/dentry/inode operation hijacking menggantikan 7 hook functions manual di 6 file VFS.
  - Kontrol userspace pindah dari genetlink ke keyring (`register_key_type("nomount")`, `SYS_ADD_KEY` syscall).
  - Adaptasi 4.14: `iterate` (bukan `iterate_shared`), `getattr` 3-arg, `notify_change` 3-arg, `generic_fillattr` 2-arg, gnu89 declaration hoist.
  - Fix build: `FLAGS_ARG`/`FLAGS_VAL` compat macros, `KMEM_CACHE(nm_inode_info)` typo, `int i` redefinition.
  - VFS hooks dibersihkan: `dcache.c`, `namei.c`, `readdir.c`, `stat.c`, `statfs.c`, `proc/task_mmu.c` — semua panggilan `nomount_handle_*` dihapus.
  - ABI userspace berubah: tool `nm` lama (genetlink) TIDAK kompatibel — wajib pakai binary `nm` baru (`SYS_ADD_KEY`), di-build static arm64 & di-upload sebagai release asset.
  - **Sumber:** maxsteeel/nomount v20 (rewrite total).

- **Fix BBR regresi (CRITICAL):** `drivers/misc/mediatek/Kconfig.default`
  - `ANDROID_DEFAULT_SETTING` (line 1) punya `select TCP_CONG_BIC` (line 235) yang memaksa BIC=y meski defconfig menolak.
  - Kconfig `select` selalu menang melawan user choice → fix v0.9.3 (defconfig `# TCP_CONG_BIC is not set`) **dibatalkan secara diam-diam** oleh vendor Kconfig.
  - Result: zip v0.9.3 yang sudah di-flash masih punya BIC → vendor rc `networksetting.rc` tetep bisa override BBR → bug internet lambat belum fix di production.
  - Fix: hapus baris `select TCP_CONG_BIC` dari `Kconfig.default`.
  - **Lesson:** CI gate v0.9.3 gak ngecek absennya BIC — sekarang ditambahkan.

- **CI gate ekspansi:** `.github/workflows/build.yml`
  - Verifikasi `CONFIG_TCP_CONG_BIC is not set` post-build (anti-regresi permanen).

- **Defconfig features & hardening:** `arch/arm64/configs/selene_defconfig`
  - **Memory:** `CONFIG_KSM=y` (dedup halaman, runtime tunable via `/sys/kernel/mm/ksm/run`)
  - **Container networking:** `CONFIG_MACVLAN=y` + `CONFIG_MACVTAP=y` (Droidspaces LXC networking modes)
  - **Security:** `CONFIG_SECURITYFS=y`, `CONFIG_SLAB_FREELIST_HARDENED=y`, `CONFIG_SLAB_FREELIST_RANDOM=y`
  - **Performance:** `CONFIG_SQUASHFS_DECOMP_MULTI_PERCPU=y` (decompress paralel), `CONFIG_ZRAM_WRITEBACK=y` (dorman sampai di-setup)
  - **Power:** `CONFIG_WQ_POWER_EFFICIENT_DEFAULT=y`
  - **Stack protection:** `CONFIG_VMAP_STACK=y`
  - Catatan: `SCHED_AUTOGROUP` tidak diaktifkan (konflik dengan `SCHED_HMP` di Helio G88).

- **Userspace nm binary:** `tools/nomount/nm.c` + `nm.h` (freestanding, raw syscalls, arm64 static)
  - CI step baru: compile via Greenforce Clang → upload sebagai release asset kedua.
  - Wajib dipakai dengan NoMount v20 kernel — tool lama berbasis genetlink tidak akan jalan.

- **Sumber:** Internal Phrolova (NoMount v20 port, Kconfig vendor audit, defconfig optimization).

## v0.9.3 — Log Noise Reduction + Fix Layar Mati Sendiri + Fast Charge Tanpa Module
- **Log noise reduction (12 titik):** `pr_err` spam vendor diturunkan ke `pr_debug` (perilaku identik, nol biaya output):
  - `drivers/misc/mediatek/io_boost/mtk_io_boost.c`: "failed to open task file" (17x/boot)
  - `drivers/power/supply/mediatek/battery/mtk_battery.c`: "phone is to high skip batterty otg boost check" (68x, loop 5 detik)
  - `drivers/power/supply/mediatek/charger/bq2589x_charger.c`: `id_dis`, `vbus_stat/chg_type`, `charger_detect_count`, `prev_pg/power_good`, `foce UNKNOWN ti/silergy` (spam polling charger IC)
  - `drivers/power/supply/mediatek/charger/mtk_charger.c`: `hq_config()` `printk` tiap panggilan → `pr_debug` (+ newline hilang diperbaiki)
  - `drivers/power/supply/mediatek/charger/mtk_chg_type_det.c`: "dhx--hvdcp" tiap poll psy REAL_TYPE
  - **Alasan:** kurangi kerja kernel (CPU/log buffer) dan buat dmesg bersih untuk debugging; temuan audit log device live.
- **Fix layar mati sendiri:** `drivers/misc/mediatek/thermal/mtk_cooler_backlight_cus.c`
  - Cooler `mtk-cl-backlight` tidak lagi menghormati clamp brightness dari thermal policy userspace (`setMaxbrightness(state, enable=1)` dinetralkan); hanya jalur reset (state == max) yang dihormati.
  - **Akar masalah:** daemon thermal ROM menulis `cur_state` cooler → panel diblank/dim padahal sistem hidup (terverifikasi live: `cooler/backlight 1610` tepat sebelum `FB_BLANK_POWERDOWN`). Mitigasi panas asli tetap jalan via cpufreq/GPU cooler.
- **Fix fast charge tanpa module:** `drivers/power/supply/mediatek/charger/mtk_charger.c`
  - `charger_manager_set_prop_system_temp_level()`: input current limit dari tabel `thermal_mitigation_*` tidak lagi diterapkan (`thermal_icl_ua = -1` permanen).
  - **Akar masalah:** thermal HAL userspace menulis `charge_control_limit` (psy CHARGE_CONTROL_LIMIT) → `system_temp_level` ≥1 → QC/HVDCP drop dari 3A ke 1.5A bahkan 900mA meski suhu aman — inilah yang selama ini "disembuhkan" thermal module.
  - **Keamanan tetap terjaga:** sw_jeita (threshold dts, T4=45°C) + hardware JEITA bq2589x tetap membatasi CC/CV berdasarkan suhu cell asli; yang dihapus hanya throttle policy-level.
- **Fix congestion control tertimpa vendor init:** `arch/arm64/configs/selene_defconfig`
  - `# CONFIG_TCP_CONG_BIC is not set` — modul BIC dihilangkan dari kernel.
  - **Akar masalah:** `/vendor/etc/init/networksetting.rc` (bawaan Huaqin) menulis `tcp_congestion_control=bic` di early-init, menimpa `CONFIG_DEFAULT_BBR=y`. Bic buruk di link lossy (seluler) → throughput turun.
  - Dengan BIC tidak tersedia di kernel, sysctl write dari vendor rc gagal diam-diam dan default tetap **BBR**.
- **Fix silent-drop Kconfig DEFAULT_BFQ (akar masalah "cfq" di artefak):** `block/Kconfig.iosched`
  - Choice "Default I/O scheduler" milik tree ini tidak punya member `DEFAULT_BFQ` → baris `CONFIG_DEFAULT_BFQ=y` diabaikan diam-diam dan fallback ke `DEFAULT_CFQ`. Terbukti via repro lokal `make selene_defconfig`.
  - Fix: tambah member `config DEFAULT_BFQ` (`bool "BFQ" if IOSCHED_BFQ=y`) + mapping string `default "bfq" if DEFAULT_BFQ`. Verified: `.config` kini memuat `CONFIG_DEFAULT_BFQ=y`, `IOSCHED="bfq"`.
- **Droidspaces/container configs:** `selene_defconfig` tambah `CONFIG_IPC_NS=y`; CI gate baru memverifikasi `USER_NS/IPC_NS/CGROUP_PIDS/POSIX_MQUEUE/VETH/OVERLAY_FS/BBR/BFQ/KSU*/NOMOUNT` benar-benar mendarat di `out/.config` (anti silent-drop) + upload `.config` sebagai artifact build untuk audit.
- **ReSukiSU refresh:** snapshot `resukisu/kernel/` faccf4c5 → **03b60f26** (main, v4.2.0-rc1 + 19 commits, 4390 commits) — termasuk sync susfs upstream & compat update. Pin Kbuild lokal di-apply ulang: `KSU_LOCAL_VERSION := 4390` → **KSU_VERSION 35090**. `manual_hook_check.mk` baru ternyata conditional-aware: dengan `AUTO_SETUID/INITRC/INPUT=y`, ketiga hook manual baru (setresuid/sys_read/input) tidak wajib; hook lama (execveat/faccessat/stat/reboot) tetap terverifikasi. Hook incompatible (ksu_vfs_read_hook/is_ksu_transition/ksu_handle_rename) dipastikan nihil di tree.
- **NoMount TIDAK di-update** (keputusan sadar): upstream maxsteeel/nomount @ b8d26835 me-rewrite arsitektur total (dentry-op hijacking menggantikan `nomount_handle_*`, kontrol userspace genetlink → keyring). Port penuh = rombak 6 titik VFS hook + ABI userspace baru — dijadwalkan kerjaan terpisah v0.9.4 dengan siklus build-test sendiri. Tree tetap pakai NoMount v1.1.0 yang stabil.
- **Dokumentasi:** AGENTS.md dapat section "Device Debugging Findings 2026-08-25" (artifact mismatch, contexthub WTF ROM bug, netd tether counters, bic override, fast charge clamp, backlight cooler); docs/OPTIMIZATIONS.md + section 5–8 (BBR enforcement, fast charge unlock, backlight neutralized, verifikasi artefak).
- **Sumber:** Internal Phrolova (analisis audit log device live + trace source mtk_charger/mtk_battery/bq2589x).

## v0.9.2 — Performance Tuning: Virtual Memory (VM) Dirty Ratios
- `a853a4bab8` `arch/arm64/configs/selene_defconfig`: Tambahkan `vm.dirty_background_ratio=5` dan `vm.dirty_ratio=15` di boot `CONFIG_CMDLINE`.
  - **Alasan:** Memulai flush dirty pages lebih awal ke storage eMMC 5.1 agar queue I/O tidak macet (menghilangkan lag saat proses instalasi/download di background).
  - **Sumber:** Internal performance tuning Phrolova.

## v0.9.1 — Performance Tuning: BFQ Default I/O Scheduler
- `3f44a5eb21` `arch/arm64/configs/selene_defconfig`: Set `CONFIG_DEFAULT_BFQ=y` dan `CONFIG_DEFAULT_IOSCHED="bfq"`.
  - **Alasan:** Mengoptimalkan throughput storage eMMC 5.1 pada Helio G88 (selene) dengan prioritas latensi rendah untuk aplikasi interaktif foreground (UI/touch) di atas background disk write.
  - **Sumber:** Internal performance tuning Phrolova.

## v0.9.0 — Migrasi Root Solution: KernelSU-Next → ReSukiSU
- **Root solution diganti: KernelSU-Next → ReSukiSU** (`ReSukiSU/ReSukiSU`, fork SukiSU-Ultra, main @ `faccf4c5` = v4.2.0-rc1 + 10 commits, 4371 commits, **KSU_VERSION 35071**; formula `30000 + commit_count + 700`).
  - `ksu-next/kernel/` dihapus → source baru di `resukisu/kernel/` (direct copy, bukan submodule).
  - **Hook mode: manual hook (`CONFIG_KSU_MANUAL_HOOK=y`)** — wajib non-GKI: TP-hook (`CONFIG_KSU_TRACEPOINT_HOOK`) hanya GKI2 5.10+ dan di-hard-error Kbuild untuk Non-GKI/GKI1. Patch manual di tree kernel:
    - `fs/exec.c`: `ksu_handle_execveat` di `do_execve` + `compat_do_execve`
    - `fs/open.c`: `ksu_handle_faccessat` di `SYSCALL_DEFINE3(faccessat)`
    - `fs/stat.c`: `ksu_handle_stat` di `newfstatat` + `fstatat64`; `ksu_handle_newfstat_ret` di `newfstat`; `ksu_handle_fstat64_ret` di `fstat64`
    - `kernel/reboot.c`: `ksu_handle_sys_reboot` di `SYSCALL_DEFINE4(reboot)`
    - setuid/initrc(read)/input: **otomatis** via LSM/input_handler (`KSU_MANUAL_HOOK_AUTO_SETUID_HOOK`/`AUTO_INITRC_HOOK`/`AUTO_INPUT_HOOK`, default y, hanya <6.8 — 4.14 aman). Tidak ada patch manual di `kernel/sys.c`/`fs/read_write.c`/`drivers/input/input.c`.
    - `resukisu/kernel/tools/manual_hook_check.mk` meng-verify SEMUA hook saat build (grep string di file kernel) — hook hilang/ekstra = compile error; hook lama (`ksu_vfs_read_hook`, `is_ksu_transition`, `ksu_handle_rename`) ditolak.
  - **Kbuild di-patch lokal:** upstream `$(error)` kalau bukan git submodule → fallback pin tanpa `.git`: `KSU_LOCAL_VERSION := 4371`, `KSU_TAG_NAME := v4.2.0-rc1`, `KSU_COMMIT_SHA := faccf4c5`, `KSU_BRANCH_NAME := main`. Jangan set ke 1 (manager tidak deteksi root).
  - **Manager:** `CONFIG_KSU_MULTI_MANAGER_SUPPORT=y` (default) — manager KernelSU/MKSU/RKSU/SukiSU-Ultra diterima. Rekomendasi: **ReSukiSU manager** (nightly.link build-manager / t.me/ReSukiSU) — match KSU_VERSION 35071.
  - `CONFIG_KPROBES` **tidak dibutuhkan** (Kconfig ReSukiSU tidak `depends on KPROBES`). `CONFIG_EXT4_FS=y` dipertahankan (boot_event pakai ext4 helpers). `CONFIG_KALLSYMS_ALL=y` dipertahankan — tanpa itu ReSukiSU butuh static export patch di `security/selinux/`.
  - **Compat 4.14 ditangani upstream:** `tools/kernel_compat.mk` + `compat/kernel_compat.c` auto-detect (flex_array policydb, hashtab 3-arg, `struct selinux_ss`, `path_mount` wrapper, `put_seccomp_filter`, `__poll_t`, dll) — tidak perlu port manual seperti KSU-Next dulu.
- **Defconfig (`selene_defconfig`):** section KernelSU-Next → ReSukiSU: `CONFIG_KSU=y`, `CONFIG_KSU_MANUAL_HOOK=y`, `CONFIG_KSU_MULTI_MANAGER_SUPPORT=y` (+ KALLSYMS/KALLSYMS_ALL, MODULES, EXT4_FS dipertahankan).
- **CI/CD diupdate:** `build.yml` (symlink → `resukisu/kernel`, `KERNELSU_VERSION=ReSukiSU main @ faccf4c5 (v4.2.0-rc1+10)`, `PHROLOVA_BASE` → 0.9.0, release body + section "Root Solution — ReSukiSU" dengan link manager), `notify-telegram.sh` (manager link ReSukiSU + credits ReSukiSU/SukiSU-Ultra), `update-kernel.yml` + `scripts/update_kernel_selective.sh` (skip list → `resukisu/`).
- **Dokumentasi diupdate:** AGENTS.md (Konteks Project, Source of Truth, gotchas ReSukiSU Integration + 4.14 SELinux notes), skill `ksunext-integration` → `resukisu-integration` (ditulis ulang), `selene-kernel` SKILL (Workflow D), `kernel-update`, `linux-version-compat`, `selinux-policy`, docs/HOOK_MODES.md (ditulis ulang → manual hook vs TP-hook), FIX_PROMPT.md, ROADMAP.md.
- **Sumber:** ReSukiSU/ReSukiSU (upstream). Alasan: fork SukiSU-Ultra yang aktif (last push 2026-08-14), support resmi non-GKI (3.4+), multi-manager support, dan fix non-GKI terbaru (`3b70416f` handle_sepolicy success_cmd_count).

## v0.8.0-nightly.20260802 — CI: Docs-only Push Tidak Trigger Build
- `67a4a331c0` `.github/workflows/build.yml`: trigger `push` kini punya `paths-ignore: ['*.md', '**/*.md']`.
- **Alasan:** sebelumnya commit yang cuma mengubah dokumentasi (CHANGELOG/AGENTS/docs) memicu full build + update release dengan tag yang sama — release body (`changelog.md`) dihitung ulang sejak tag terakhir dan menimpa changelog lengkap dengan hanya item "docs: ...". Notif Telegram ikut menampilkan changelog menyusut.
- **Efek**: hanya perubahan kode/defconfig/CI yang memicu build, notif, dan release update.

## v0.8.0-nightly.20260802 — KernelSU-Next 4.14 Porting: SELinux & Link Compat
- Rangkaian fix kompatibilitas agar KernelSU-Next v3.3.0 (`ksu-next/kernel/`) compile + link hijau di kernel 4.14.356 (selene_defconfig). Referensi utama: branch `legacy` KernelSU-Next.
- `682cc38dc5` `selinux/rules.c` + `selinux/sepolicy.c`: model `struct selinux_policy` (dup/swap policy) hanya ada di 5.10+. Untuk <5.10 (4.14): aturan diaplikasikan langsung ke `selinux_state.ss->policydb` di bawah `policy_rwlock` (pola legacy KSU). `ksu_dup_sepolicy`/`ksu_destroy_sepolicy` jadi stub no-op di <5.10.
- `1a399126df` `selinux/sepolicy.c`: policydb 4.14 pakai `flex_array` untuk `te_avtab.htable`, `type_attr_map_array`, `type_val_to_struct_array`, `sym_val_to_name` (helper `ksu_avtab_get_node`/`put_node` + branch `add_type` flex_array). `policydb_filenametr_search`/`filename_trans_key`/`compat_filename_trans_count`/`filenametr_key_params` hanya 5.9+ → branch legacy pakai `struct filename_trans` + hashtab 3-arg.
- `4e9b9b7ca5` `sulog/event.c`: `ktime_get_boottime_ts64` (5.6+) → fallback `getboottime64()` untuk 4.14 (+ include `linux/timekeeping.h`).
- `0161316a81` `sulog/fd.c`: `__poll_t` (4.16+) → `unsigned int` untuk <4.16.
- `bba51baf25` `supercall/dispatch.c`: include `linux/sched/task.h` — `tasklist_lock`/`init_task` ada di sana di 4.14.
- `70c3b02548` `feature/selinux_hide.c`: `status_lock`/`status_page` di 4.14 ada di `selinux_state.ss->*`; tidak ada member `state.policy`; `backup_sepolicy->sidtab` hanya valid 5.10+ (guard).
- `bad5f1cae0` `infra/su_mount_ns.c` + `policy/app_profile.c`: link fix — `path_mount` (5.9+) diganti wrapper `d_path()` + `do_mount()` + `set_fs(KERNEL_DS)` (pola legacy kernel_compat.c); `seccomp_filter_release` static di <5.9 → pakai `put_seccomp_filter(current)` (simbol global di 4.14).
- **Sumber:** KernelSU-Next branch `legacy` (kernel/selinux/*, kernel/compat/kernel_compat.c) + struktur SELinux 4.14 di tree (`ss/services.h`, `ss/policydb.h`, `ss/avtab.h`).

## v0.8.1 — Hookless-only (Kprobes Disabled)
- **KernelSU-Next sekarang murni hookless:** `CONFIG_KPROBES=y` dihapus dari `selene_defconfig` → framework kprobes tidak di-compile sama sekali.
- **Kconfig ksu-next di-patch lokal:** `depends on KPROBES && EXT4_FS` → `depends on EXT4_FS` (upstream tetap `KPROBES && EXT4_FS`).
- **Kode kprobe di-guard `#ifdef CONFIG_KPROBES`** (compiled-out):
  - `ksu-next/kernel/supercall/supercall.c`: reboot kprobe (sys_reboot magic) — fd-install tetap jalan via `hook/setuid_hook.c` `ksu_install_fd()`.
  - `ksu-next/kernel/runtime/ksud_integration.c`: input_event kprobe + `stop_input_hook_work`.
  - `extras.c` (avc_spoof) & `syscall_hook_manager.c` (kretprobe) — sudah ada guard dari upstream; `#ifndef CONFIG_KRETPROBES` fallback `ksu_mark_running_process_locked()` aktif.
- **Fitur yang mati (disengaja):** reboot supercall, AVC spoof, key-event hook. Root, manager fd, setresuid/execve/newfstatat/faccessat/read/fstat hooks — semua tetap jalan via syscall table + tracepoint.
- **`CONFIG_MODULES=y` dipertahankan** (parity MiCode asli).
- **Alasan:** kprobes = permukaan serang breakpoint + overhead runtime; hookless sudah cukup untuk semua fitur root inti. Tidak ada device testing (bootloader masih locked) — validasi via CI compile.
- **Dokumentasi:** AGENTS.md (gotcha integration), docs/HOOK_MODES.md (section 4 → hookless-only).
- **Sumber:** patch lokal di atas upstream KernelSU-Next v3.3.0 @ `e7536f0`.

## v0.8.0 — Migrasi KernelSU → KernelSU-Next
- **Root solution diganti: backslashxx/KernelSU → KernelSU-Next** (`KernelSU-Next/KernelSU-Next`, dev @ `e7536f0`, tag v3.3.0, 3227 commits).
  - `backslash-ksu/kernel/` dihapus → source baru di `ksu-next/kernel/` (direct copy, sama seperti sebelumnya).
  - **Hook mode:** dispatcher slot di-patch langsung ke `sys_call_table` (`hook/arm64/syscall_hook.c`, via `ksu_patch_text`) + routing `register_trace_prio_sys_enter` (`hook/syscall_hook_manager.c`). Tidak ada patch fs/ manual — analog dengan syscall table hook backslashxx.
  - **Opsi Kconfig lama dibuang:** `KSU_TAMPER_SYSCALL_TABLE`, `KSU_KPROBES_KSUD`, `KSU_MULTI_MANAGER_SUPPORT` tidak ada di KernelSU-Next.
  - **Manager tunggal:** hanya KernelSU-Next manager APK (signature `KSU_NEXT_MANAGER_HASH` di Kbuild). Multi-manager (tiann/backslashxx/RKSU/MKSU) tidak didukung lagi.
  - **KSU_VERSION di-pin:** `KSU_VERSION_FALLBACK := 33227` (30000 + 3227 commits) + `KSU_VERSION_TAG_FALLBACK := v3.3.0` di `ksu-next/kernel/Kbuild` — vendored copy tidak punya `.git`, jadi fallback upstream `1` diganti supaya manager tetap deteksi root.
- **Defconfig baru (selene_defconfig):**
  - `CONFIG_MODULES=y` — wajib: `KPROBES depends on MODULES` di tree ini; hilang sejak rebase yuki-saisei (ada di defconfig MiCode asli). Tanpa ini `CONFIG_KPROBES` di-drop diam-diam → KSU tidak ter-build.
  - `CONFIG_KPROBES=y` — wajib untuk Kconfig KernelSU-Next (`depends on KPROBES && EXT4_FS`). Tersedia karena MTK 4.14 punya backport kprobes (`arch/arm64/Kconfig`: `select HAVE_KPROBES` + `HAVE_KRETPROBES`; vanilla upstream 4.14 arm64 TIDAK punya — kprobes arm64 baru masuk 4.16). Kprobes runtime opsional & fail-safe (reboot supercall, slow_avc_audit, input_handle_event, syscall_regfunc kretprobe).
  - `CONFIG_EXT4_FS=y` — wajib untuk `depends on KPROBES && EXT4_FS` (dipakai `ext4_unregister_sysfs` di `runtime/boot_event.c`); sebelumnya tidak di-enable (kernel berbasis F2FS).
- **CI/CD & scripts diupdate:** `build.yml` (symlink → `ksu-next/kernel`, `KERNELSU_VERSION=KernelSU-Next v3.3.0`), `update-kernel.yml` + `scripts/update_kernel_selective.sh` (skip list → `ksu-next/`), `notify-telegram.sh` (credit + link manager).
- **Dokumentasi diupdate:** AGENTS.md, skill `xxksu-integration` → `ksunext-integration` (ditulis ulang), `selene-kernel` SKILL + references (ksu.md/build.md/ci.md/update.md), `kernel-update`, `selinux-policy`, `project-identity`, FIX_PROMPT.md, ROADMAP.md, docs/PRD.md.
- **Sumber:** KernelSU-Next/KernelSU-Next (upstream). Alasan: drop multi-manager complexity, ikut ekosistem KernelSU-Next (maintener aktif, manager sendiri, policy profiles), kompatibel 4.14 non-GKI.

## v0.7.1 — Performance Tuning (Responsiveness & RAM Fix)
- **WQ_POWER_EFFICIENT_DEFAULT=n:** Workqueue ga lagi dipaksa jalan di little core doang. Fix root cause slow background task processing — workqueue tasks sekarang bisa jalan di A75 big core.
- **vmalloc=496M→320M:** Hemat ~176MB RAM yang sebelumnya dipesen buat vmalloc. RAM tambahan ini available buat app/launcher/system, kurangi LMK kills.
- **slub_max_order=0→2:** Naikin slab allocator dari order-0 (4KB) ke order-2 (16KB) per chunk. Kurangin overhead management slab, akses memory lebih cepat.
- **MTK_SCHED_CPULOAD=y:** Per-CPU load calculation — schedutil governor sekarang bisa liat akurat beban tiap CPU buat frequency scaling yang tepat. Without this, governor basically blind.
- **MTK_SCHED_RQAVG_US=y:** Runqueue average dari userspace — bantu scheduler bikin task placement decision yang lebih baik.
- **MTK_SCHED_SYSHINT=y:** System-wide scheduling hints — ngasih tau scheduler tentang konteks sistem (screen on/off, heavy load) buat keputusan yang lebih cerdas.
- **MTK_GBE=y:** Global Boost Engine — boost frekuensi CPU+GPU pas app launch, switching task, dan interaksi UI. Fix "app ga mau load kenceng".
- **ZRAM_SIZE 3GB→2GB:** Kurangin CPU compression overhead. 3GB ZRAM di device 4GB bikin CPU terus-terusan zstd compress/decompress pas multitasking — itu sumber lemot. 2GB lebih balance, sistem bisa keep pages uncompressed lebih banyak.
- **ZRAM_WRITEBACK=n:** Gak ada backing device (flash-based swap). Konfigurasi ini useless tapi ZRAM tetap jalan function call buat ngecek — sekarang di-disable.
- **MTK_EARA_AI=y:** AI-guided task placement di big.LITTLE. EARA (Energy-Aware Resource Allocator) pake AI lightweight model buat nentuin task mana yang jalan di A75 (big) vs A55 (LITTLE) — lebih cerdas dari HMP static rules.
- **CC_STACKPROTECTOR_STRONG=n:** Stack canary prologue/epilogue dihilangkan dari semua fungsi kernel. Setiap fungsi kernel dapet ~2-5% speedup. `drivers/misc/mediatek/Kconfig.default` juga diedit — hapus `select CC_STACKPROTECTOR_STRONG` yang sebelumnya override defconfig.
- **KSM=n:** Kernel Samepage Merging thread distop. Dulu KSM scan 4GB RAM tiap beberapa detik — CPU dibuang buat cari page duplikat yang jarang ada di Android (Zygote udah handle sharing via fork). ZRAM + Simple LMK udah cukup handle memory pressure.
- **SCHEDSTATS=n:** Scheduler stats collection dimatiin. Kurangin overhead di context switch path. Ini data debug yang gak dipake di runtime.
- **HID driver bloat removed:** Dari 25 HID driver built-in jadi cuma 4 (Apple, Logitech, Microsoft, Samsung). Gaming HID (DragonRise, GreenAsia, SmartJoyPlus, ThrustMaster, ZeroPlus) + vendor obscure (Gyration, TwinHan, dll) di-cut — gak ada gunanya di phone. Kernel image lebih kecil, memory footprint lebih rendah.
- **Simple LMK Fix (v1.0.1):**
  - **min_free=200MB** (dari 64MB): Sekarang pake `si_mem_available()` (free + reclaimable cache), bukan cuma `freeram`. Threshold dinaikin ke 200MB biat LMK kill cached apps SEBELUM sistem mulai thrashing swap.
  - **Check interval 500ms** (dari 2000ms): Respon lebih cepet ke memory pressure. 2 detik terlalu lambat — memory bisa abis total dalam waktu itu.
  - **Fix race condition:** `lmk_find_best_victim()` sekarang return dengan refcount dipegang (`get_task_struct` inside loop). Sebelumnya return raw pointer tanpa ref → bisa use-after-free kalo task exit antara return dan caller pake.
  - **kill_now_store fix:** Ikut adapt ke refcount pattern baru.

## v0.6.0 — Kprofiles + Simple LMK + Droidspaces Ready
- **Kprofiles Power Profile Manager:** New `drivers/misc/kprofiles/` driver. Sysfs interface (`/sys/kernel/kprofiles/kp_mode`) with 4 modes: Off(0), Battery(1), Balanced(2), Performance(3). Exported API (`kp_set_mode`, `kp_active_mode`, `kp_set_mode_rollback`) for other drivers. Auto screen-off profile switching via FB notifier. `CONFIG_KPROFILES=y` in defconfig.
- **Simple LMK (Low Memory Killer):** New `drivers/staging/android/simple_lmk.c`. Periodic memory checker with configurable `min_free_mb` threshold (default 64MB). Sysfs at `/sys/kernel/simple_lmk/`. Kills highest oom_score_adj process when memory drops below threshold. `CONFIG_SIMPLE_LMK=y` in defconfig.
- **ARM NEON:** Enabled `CONFIG_KERNEL_MODE_NEON=y` for hardware floating-point and SIMD acceleration.
- **TTL/Hotspot Tethering Fix:** Confirmed working via `CONFIG_IP_NF_TARGET_TTL=y` + `NETFILTER_XT_TARGET_HL`. TTL manipulation module (`xt_HL.c`) compiles and links correctly.
- **Droidspaces Compatibility:** Verified full compatibility with [Droidspaces-OSS](https://github.com/ravindu644/Droidspaces-OSS) container runtime. Kernel 4.14.356 non-GKI + KernelSU fully supported. Recommended for running full Linux distros (Ubuntu, Debian, Alpine) on selene.
- **AnyKernel3 Flash Fix:** Latest AK3 (osm0sis) uses UPPERCASE variables (`BLOCK`, `IS_SLOT_DEVICE`) but `anykernel.sh` had lowercase (`block`, `is_slot_device`) → variable was empty at runtime → partition detection loop never ran → abort. Fixed by updating to `BLOCK=auto; IS_SLOT_DEVICE=auto;`. Tendou-Arisu (selene/MT6768) works because it uses older AK3 with lowercase vars.
- **CI Stabilization:** Fixed Greenforce Clang 24.0.0 cache key, `reference/banner` tracking, graceful AnyKernel3 packaging. Build passes on ubuntu-24.04.

## v0.7.0 — Kprofiles + Simple LMK + Droidspaces Ready

- **Memory Management:** Enable THP (madvise), CMA, Compaction, ZSWAP/ZPOOL, TASKSTATS, SCHED_AUTOGROUP for better memory utilization and performance.
- **Kernel Hardening:** Enable FORTIFY_SOURCE, HARDENED_USERCOPY, SECURITY_PERF_EVENTS_RESTRICT - low-overhead exploit mitigations.
- **TCP:** Add Westwood (cellular) and BIC congestion algorithms alongside BBR.
- **Android Compat:** Enable ASHMEM for vendor HAL compatibility.
- **PSI:** Pressure Stall Information - Android 12+ uses this for smarter LMK/kill decisions.
- **MTK Performance Boost:** Enable Touch Boost (CPU freq/cores naik pas disentuh), Load Tracker, CPU Ceiling Fool-Proof (bebasin ceiling pas heavy load), IO Boost (stune boost), Task Turbo (app launch/lock latency), GBE (Game Boost Engine), EARA AI (AI low power balance). Semua native MTK, sudah di tree.
- **Scheduler — HMP:** Ganti `SCHED_AUTOGROUP` → `SCHED_HMP` (big.LITTLE task placement) + EAS power calculation, Multi Gears, BL_FIRST, RQAVG, CPULOAD, SYSHINT. Stock MiCode juga pake HMP. AUTOGROUP kurang relevan di Android karena cgroups udah handle task grouping.
- **Speculative Page Fault:** Kurangin `mmap_sem` contention buat multi-thread performance.
- **PGTABLE Mapping:** Page table mapping buat zsmalloc/ZRAM — lebih cepat dari copy mapping. Stock enable.
- **Process Reclaim:** `/proc/pid/reclaim` — targeted memory reclaim tanpa LMK.
- **MEMCG_SWAP:** Per-cgroup swap accounting.
- **CPU_PERFORMANCE governor:** Buat benchmarking.
- **Kyber I/O scheduler:** Low-overhead scheduler buat eMMC. — hapus total pemanggilan `f_op->iterate_shared` / `f_op->iterate`. VFS `iterate_dir` sudah handle real iterate, NoMount cukup skip pos ke `nomount_magic_pos` dan inject virtual entries. Fix duplikasi total di semua direktori yang di-intercept NoMount.
- **Version:** Bump ke v0.7.0 (feature bump).

## v0.6.1 — NoMount Double-Iterate Hotfix
- **NoMount Fix:** `nomount_handle_iterate_dir` di `fs/nomount.c` tidak lagi memanggil `f_op->iterate_shared` dua kali. `iterate_dir` di VFS sudah memanggil iterate function asli, jadi hook NoMount cukup inject virtual files tanpa re-iterate. Fix duplicate file listing di directory mana pun yang di-intercept NoMount.

## v0.5.0 — FPSGO Tracepoint Fix + Build Stabilization
- **FPSGO Tracepoint Fix:** Add `CONFIG_TRACEPOINTS=y`, `CONFIG_TRACING=y`, `CONFIG_TRACING_SUPPORT=y`, `CONFIG_FTRACE=y`, `CONFIG_CONTEXT_SWITCH_TRACER=y`, `CONFIG_ENABLE_DEFAULT_TRACERS=y`, `CONFIG_NOP_TRACER=y`, `CONFIG_EVENT_TRACING=y`, `CONFIG_MTK_SCHED_TRACERS=y` to `selene_defconfig`. Fixes 60+ undefined reference errors (`__tracepoint_*`, `tracepoint_probe_register`) in FPSGO GPU driver (`xgf.c`). Root cause: FPSGO hooks into kernel tracepoints via `FPSFO_DECLARE_SYSTRACE` macro but tracepoint infrastructure was never enabled.
- **Kernel String:** Add violin emoji 🎻 to `kernel.string` in `anykernel.sh`.

## v0.4.0 — Performance & Memory Optimizations + LTO Fix
- **LTO Fix:** Disable `CONFIG_LTO_CLANG` di `selene_defconfig` untuk mengatasi bitcode mismatch antara LLVM 23 (compiler) dan LLVM 16 (system linker).
- **TCP Congestion Control:** Enable Google BBR (`CONFIG_TCP_CONG_BBR=y`, `CONFIG_DEFAULT_TCP_CONG="bbr"`) + Fair Queueing (`CONFIG_NET_SCH_FQ=y`, `CONFIG_NET_SCH_FQ_CODEL=y`) untuk koneksi internet lebih responsif dan latency lebih rendah.
- **ZRAM & Memory Compression:** Enable ZSTD algorithm (`CONFIG_CRYPTO_ZSTD=y`, `CONFIG_ZRAM_DEF_COMP_ZSTD=y`, `CONFIG_ZRAM_DEF_COMP="zstd"`) dan LZ4/XZ (`CONFIG_RD_LZ4=y`, `CONFIG_RD_XZ=y`) untuk efisiensi dan kecepatan swap RAM.
- **I/O Scheduler:** Enable Budget Fair Queueing (`CONFIG_IOSCHED_BFQ=y`, `CONFIG_BFQ_GROUP_IOSCHED=y`) untuk kelancaran UI saat I/O disk tinggi.

## v0.4.0 Fixes — CI Build & Flash Failures

### CI Build: `xt_hl.o` no rule to make target
- **File:** `net/netfilter/xt_hl.c`
- **Root cause:** File was accidentally deleted during rebase onto yuki-saisei (4.14.356). Kconfig `IP_NF_MATCH_TTL` and `IP6_NF_MATCH_HL` both `select NETFILTER_XT_MATCH_HL`, which force-enables compilation regardless of `CONFIG_NETFILTER_XT_MATCH_HL=n` in defconfig.
- **Fix:** Restore `xt_hl.c` from parent commit `5b0b7cf324~1`.
- **Commit:** `806cf866c6`

### CI Build: `__tracepoint_*` undefined reference (link error)
- **File:** `arch/arm64/configs/selene_defconfig`
- **Root cause:** FPSGO GPU driver (`xgf.c`) uses kernel tracepoints but `CONFIG_TRACEPOINTS` was not enabled. Without it, tracepoint symbols are undefined → vmlinux link fails with 60+ errors.
- **Fix:** Add `CONFIG_TRACEPOINTS=y` to `selene_defconfig`.

### Flash: "Unable to determine partition. Aborting."
- **File:** `scripts/anykernel.sh`
- **Root cause:** `block=auto` fails on MTK MT6768 (selene). The auto-detection doesn't find the boot partition on this device's block layout. All prior releases (v0.1.0–v0.3.0) have this same broken config.
- **Fix:** Set explicit `block=/dev/block/bootdevice/by-name/boot` and `is_slot_device=1` (Redmi 10 2022 is A/B device).
- **Commit:** `806cf866c6`

---

## M0 — Repo setup
- Repo di-init sebagai git. Base of truth = `micode` remote (branch `selene-r-oss-update`).
- `ronald826` remote ditambahkan sebagai reference-only (JANGAN di-merge mentah).
- AGENTS.md, PRD.md, PROMPT.md, .opencode/skills terpasang dari scaffold.
- Push target = `origin` -> `naidrahiqa/phrolova_kernel_xiaomi_selene`.
- ReSukiSU: `resukisu` -> fork `naidrahiqa/ReSukiSU`, `resukisu-upstream` -> `ReSukiSU/ReSukiSU`.
- Fetch **shallow (--depth 1, latest only)** per instruksi Naidra — bukan full history.
- Branch `selene-r-oss-update` -> MiCode tip `6a5cdd275` (bukan ronald826).

### Known issue (Windows) — PENTING buat sesi berikutnya
- Native Windows gak bisa checkout file reserved name (`aux.c`/`aux.h` di
  `drivers/gpu/drm/nouveau/` & `include/soc/arc/`). Workaround:
  - `core.protectNTFS=false` (biar git gak reject di verify_path).
  - `core.sparseCheckout=true` + `.git/info/sparse-checkout` exclude
    `drivers/gpu/drm/nouveau/` dan `include/soc/arc/` (gak dipakai buat selene build).
- `git status` nampilin "M" di `net/netfilter/xt_*.{c,h}` — itu artifact
  case-folding NTFS (CONNMARK vs connmark), konten identik, gak ngaruh build.
- 💡 Rekomendasi: kerja git/checkout/build di WSL (fs Linux) kalau bentrok
  nama reserved file lain muncul.

## M1 — Source diff report (MiCode vs Ronald826, LATEST ONLY)
> ⚠️ Kedua ref **shallow (depth 1)** → ini perbandingan *tree state* terbaru,
> BUKAN per-commit history. Cherry-pick per-commit (step skill) butuh
> `git fetch` lebih dalam untuk `ronald826` saat beneran apply nanti.
> Status: **report only, belum ada yang di-apply.**

### arch/arm64/configs/ (defconfig)
- `cselene_defconfig` (Ronald826, +5193): custom selene defconfig.
  Cek `KSU/SU/SELINUX/GKI` → **kosong** (gak ada root solution).
  Rekomendasi: **REVIEW** sebagai referensi opsi/extra driver, bukan di-merge mentah.
- `selene_defconfig` beda masif (+5022): kemungkinan reordering + tambahan.
  Rekomendasi: **KEEP MiCode sebagai basis**, ambil `CONFIG_*` spesifik dari
  Ronald826 selectively (terutama pas M4 butuh flag ReSukiSU).
- `selene_debug_defconfig` → `selene.bak` (Ronald826, 138): **SKIP**.
- defconfig device lain (lancelot/merlin/shiva/k69v1/cuttlefish/ranchu) dihapus
  Ronald826: cleanup non-selene → **SKIP** (irrelevant).

### arch/arm64/boot/dts/mediatek/ (device tree)
- `selene.dts`: charger current 2000→1000mA, jeita thermal threshold diubah,
  include path fix `<selene/cust.dtsi>` → `"mediatek/selene/cust.dtsi"`.
  Rekomendasi: **REVIEW** (device-specific, include-path fix berguna).
- `selene/cust.dtsi` (+614 baru): **REVIEW**.
- `cust_mt6768_touch_1080x2400.dtsi` (+17), `touch_eos_1080x2400.dtsi` (−1905):
  **REVIEW** (Ronald826 cabut eos touch?).
- `mt6768.dts` (+13), `eos.dts` (+86), battery tables: **REVIEW ringan**.
- dts non-selene (marvell/nvidia/qcom/renesas/rockchip/xilinx): base drift → **SKIP**.

### drivers/ (⚠️ DIVERGEN BESAR)
- Total: **5541 file, +1.7M / −70k baris** → ini base-version drift antar dua
  tree, BUKAN kumpulan fix selene.
- Rekomendasi: **JANGAN bulk-merge drivers.** Cherry-pick HANYA fix kecil
  spesifik kalau ada isu build/runtime konkret.
- Kandidat review-per-hunk (kalau perlu): `mtk_charger.c`(+95),
  `bq2589x_charger.c`(+69), `mtk_battery*.c`(+14), `mtk_eth_soc.c`(+28),
  `pcie-mediatek.c`(+7), `mtk-scpsys.c`(+6), watchdog mtk.
- Mayoritas `1 +` di ratusan file = noise base drift → **SKIP**.

### Catatan ReSukiSU (utk M4)
- Ronald826 **TIDAK** punya trace KernelSU/ReSukiSU → integrasi M4 murni dari
  remote `resukisu` / `resukisu-upstream`, bukan dari Ronald826.

## M1 — Applied cherry-picks (branch: `m1-cherrypick`)
> Base `selene-r-oss-update` (6a5cdd275) TIDAK diubah; semua CP ada di branch
> `m1-cherrypick`. Status: **applied, COMPILE-PENDING** (toolchain M2/M3 belum
> ada → belum ke-verify compile). Belum di-push.

### Applied (clean, 4)
- [c42c4fc6a] arch/arm64/configs/cselene_defconfig: tambah custom defconfig (referensi)
  Sumber: ronald826 | Status: applied (a2e6560bc) | compile-pending
- [a29340b7c] arch/arm64/configs/selene_defconfig: enable CONFIG_CPUFREQ_MTK
  Sumber: ronald826 | Status: applied (3f6709136) | compile-pending
- [cf311b63d] arch/arm64/configs/selene_defconfig: disable syncookies
  Sumber: ronald826 | Status: applied (df6538b57) | compile-pending
- [1b9f616fa] arch/arm64/configs/selene_defconfig: Disable HMP configs
  Sumber: ronald826 | Status: applied (80db46d60) | compile-pending

### Deferred (conflict / mixed commit / butuh build-verify)
- [e55b59d18] disable PRINTK_MT_PREFIX → CONFLICT defconfig, tunda (merge manual M4)
- [5d4369dd1] Enable LZ4 compression → CONFLICT defconfig, tunda
- [7dd794dd5] Enable ZRAM Writeback → CONFLICT defconfig, tunda
- [c1ed273f3] Update selene_defconfig → CONFLICT, tunda
- [acb9c3912] Change selene_defconfig (rewrite 5070 baris) → bukan targeted, SKIP
- [8a337721f] ThunderQuake vibrator driver → driver baru, konflik tree, tunda (per-hunk M4)
- [fd7e5bef4] touchscreen TP interface → driver baru, konflik tree, tunda (per-hunk M4)
- [9aa87e482] kallsyms + selene.dts + cust.dtsi (COMMIT MIXED) → tdk bisa CP utuh;
  selene.dts/cust.dtsi akan di-apply per-hunk manual + kallsyms dipisah (relevan M4)

## Reference — AK3 zips lokal (D:\ROM\CustomRom_Selene\Custom Krrnel)
> Di-bedah pakai skill ak3-reverse-engineering. Zips = release flashable, BUKAN
> source/toolchain. Toolchain binary TIDAK ada di disk → cuma jadi referensi
> konfigurasi, bukan sumber compiler.

- `HitoriBocchi-KSUN-20260320-182750-selene.zip`: berisi Image.gz + anykernel.sh
  (device: selene). KSUN = KernelSU-variant.
- `[A13+]ShockWave-selene-202605241352.zip`: brand "Proton Kernel", device
  name1=merlin name2=lancelot name3=selene; `block=auto`, `is_slot_device=auto`,
  `write_boot` (AK3 standar). Jadi REFERENSI buat `anykernel.sh` kita di M5.
- Konfirmasi: kernel 4.14 selene yang SUDAH terbukti boot ada (merlin/lancelot/
  selene shared tree) → build kita feasible. Compiler pasti GCC/Clang tapi gak
  bisa di-extract dari binary image → ambil dari repo builder publik mereka.
- ⚠️ JANGAN pakai Image/dtb biner mereka sebagai rilis final (prinsip skill:
  maintain dari source sendiri).

## M2 — Toolchain decision (FINAL)
- **Proton Clang** (`kdrag0n/proton-clang`), **pin tag `20210522`** (Clang ~12,
  stabil & terbukti untuk 4.14; ini toolchain yang dipakai "Proton Kernel"/
  ShockWave selene — lihat AK3 ref di atas).
- Clang + binutils bundled → `CC=clang CROSS_COMPILE=aarch64-linux-gnu-`
  (`CROSS_COMPILE_ARM32=arm-linux-gnueabi-` utk vDSO 32-bit). Tidak perlu GCC
  terpisah (sesuai catatan Proton Clang).
- ⚠️ Local WSL Ubuntu **GAGAL di-install** (session ini bukan admin). Maka
  compile-verify M3 dilakuin lewat **GitHub Actions CI** (ubuntu-latest runner,
  fs Linux → bebas isu reserved-name Windows). Ini CI-first (AGENTS.md).
- CATATAN: PRD M2 sebut "Clang/GCC hybrid"; Proton Clang udah include binutils
  (GNU as/ld) jadi efektif hybrid tanpa GCC userspace. CyreneClang ditunda (v2).

## M3 — CI baseline dengan GCC 13 (Proton Clang gagal cc-option)
- Proton Clang (`kdrag0n/proton-clang` 20210522) gagal karena `cc-option`
  tidak bisa mengevaluasi `-fstack-protector-strong` di 4.14.
- Beralih ke **GCC 13** dari apt (ubuntu-24.04): `gcc-aarch64-linux-gnu` +
  `binutils-aarch64-linux-gnu`.
- GCC 13 error di `mm/page_alloc.c:6890` (`-Werror=array-compare`, baru di
  GCC 11+). Fix: `KCFLAGS="-Wno-error=array-compare"` di workflow.
- Workflow di `.github/workflows/build.yml`: install deps, make selene_defconfig,
  build, package AnyKernel3 (Image.gz-dtb/Image.gz/Image), upload artifact.
- `scripts/anykernel.sh` updated ke "Phrolova Kernel" branding.

## M4 — ReSukiSU Manual Hook integration
- Sumber: `resukisu/main:kernel/` dari fork `naidrahiqa/ReSukiSU`.
- `resukisu/kernel/` ditempatkan di tree (bukan symlink, symlink dibuat di CI).
- `drivers/Kconfig`: tambah `source "drivers/kernelsu/Kconfig"`.
- `drivers/Makefile`: tambah `obj-$(CONFIG_KSU) += kernelsu/` + fix conflict marker.
- `selene_defconfig`: `CONFIG_KSU=y`, `CONFIG_KSU_MANUAL_HOOK=y`,
  `CONFIG_KSU_MULTI_MANAGER_SUPPORT` tidak di-set.
- CI: step `Setup ReSukiSU symlink` — `ln -sf resukisu/kernel drivers/kernelsu`.
- Hook mode: **Manual Hook** (bukan Tracepoint — GKI2-only ≥5.10). Sesuai
  rekomendasi ReSukiSU untuk 4.14 non-GKI.
- Auto-hook options default: `AUTO_SETUID`, `AUTO_INITRC`, `AUTO_INPUT`
  (via LSM, tidak perlu patch manual ke kernel/sys.c / fs/read_write.c /
  drivers/input/input.c).

## M5 — CI: Void Linux Container + Toolchain Greenforce Clang 24
- `.github/workflows/build.yml`: runner → `container: voidlinux/voidlinux`
- Package manager: `apt-get` → `xbps-install` (Void Linux)
- `TOOLCHAIN_NAME`: Greenforce Clang 23 → 24
- Cache key: `greenforce-clang-23.0.0` → `greenforce-clang-24.0.0`
- Added `cp reference/banner ak3/banner` di packaging step

## M6 — Feature Update: Kprofiles, Simple LMK, NEON, TTL (v0.6.0)

### Kprofiles — Kernel Power Profile Manager
- `drivers/misc/kprofiles/` (main.c, Kconfig, Makefile, version.h)
- Sysfs: `/sys/kernel/kprofiles/kp_mode` (0=Off, 1=Battery, 2=Balanced, 3=Performance)
- Auto screen-off switching via fb_notifier
- Exported API: `kp_active_mode()`, `kp_set_mode()`, `kp_notifier_register_client()`
- `CONFIG_KPROFILES=y`, `CONFIG_KP_DEFAULT_MODE=0`, `CONFIG_AUTO_KPROFILES_NONE=y`

### Simple Low Memory Killer
- `drivers/staging/android/simple_lmk.c` + header
- Periodically checks free RAM via `si_meminfo()`, kills best candidate when below threshold
- Sysfs: `/sys/kernel/simple_lmk/` (min_free_mb, enabled, kill_now)
- `CONFIG_SIMPLE_LMK=y`, default min_free=64MB

### Kernel Mode NEON
- `arch/arm64/configs/selene_defconfig`: `CONFIG_KERNEL_MODE_NEON=y`
- Enables ARM NEON crypto acceleration

### TTL Target (Hotspot Fix)
- Already enabled via `CONFIG_IP_NF_TARGET_TTL=y` → selects `NETFILTER_XT_TARGET_HL`
- `net/ipv4/netfilter/xt_HL.c` provides both IPv4 TTL and IPv6 HL target
- File already exists in tree (no new addition needed)
