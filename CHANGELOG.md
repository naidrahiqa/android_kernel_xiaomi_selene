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
