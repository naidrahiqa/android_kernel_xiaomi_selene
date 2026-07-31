# Phrolova Kernel — Roadmap

## Versi Saat Ini: v0.8.0

---

## Fase 1 — Foundation Stabil (done)

- [x] KernelSU-Next v3.3.0 (syscall table hook + sys_enter tracepoint)
- [x] NoMount path redirection
- [x] TCP BBR + ZRAM ZSTD + BFQ
- [x] CI/CD pipeline functional (Void Linux container)
- [x] AnyKernel3 MTK A/B slot fix
- [x] Kprofiles — sysfs power profile manager
- [x] Simple LMK — low memory killer
- [x] Kernel Mode NEON — crypto acceleration
- [x] TTL target (hotspot fix)
- [x] Toolchain: Greenforce Clang 24

## Fase 2 — Performance Tuning (v0.7.1)

Target: Benchmark gain + responsivitas.

- [x] **Workqueue tuning** — `WQ_POWER_EFFICIENT_DEFAULT=n` (big core utilization)
- [x] **vmalloc reduction** — 496M→320M (freed 176MB RAM)
- [x] **Slab allocator** — `slub_max_order=2` (kurang overhead)
- [x] **MTK scheduler** — CPULOAD, RQAVG_US, SYSHINT (schedutil visibility)
- [x] **Boost engines** — GBE, EARA_AI, Task Turbo, Touch Boost, IO Boost
- [x] **ZRAM resize** — 3GB→2GB (kurang CPU compression thrash)
- [x] **KSM disabled** — save CPU cycles
- [x] **Stack protector disabled** — `CC_STACKPROTECTOR_STRONG=n`
- [x] **HID bloat** — 25→4 drivers
- [x] **Simple LMK v1.0.1** — 200MB threshold, 500ms, race fix
- [ ] **GPU frequency table** — adjust Mali G52 MC2 freq steps
- [ ] **BFQ tuning** — slice_idle, timeout_sync
- [ ] **VM sysctl** — dirty ratio, vfs_cache_pressure (runtime)
- [ ] **BBR tuning** — pacing gain, TCP buffer sizes
- [ ] **ZRAM tuning** — stream count, compression level

## Fase 3 — Fitur Tambahan (v0.8.0)

Target: New functionality beyond base kernel.

- [ ] **KernelSU LKM mode** — dukungan loadable kernel module (CONFIG_KSU_LKM)
- [ ] **Power Efficient Workqueue** — `CONFIG_WQ_POWER_EFFICIENT`
- [ ] **KSU WebUI Manager** — built-in kernel manager via KernelSU (kmod)
- [ ] **WireGuard** — update ke versi terbaru
- [ ] **Backport task_tgid_nr** — untuk kompatibilitas KernelSU terbaru
- [ ] **Optimasi F2FS** — mount options, GC tuning

## Fase 4 — Pengalaman Pengguna (v0.9.0)

Target: User-facing polish.

- [ ] **KernelSU WebUI default theme** — dark mode, custom preset
- [ ] **NoMount userspace control app** — netlink-based control
- [ ] **Perf mode toggle** — gaming vs day-to-day via Kprofiles
- [ ] **Sound control** — speaker/headphone gain (if codec supports)
- [ ] **Build variant** — separate "Lite" build

## Fase 5 — Eksperimental (v1.0.0+)

Target: Cutting-edge / long-term.

- [ ] **Kernel 4.14.357+ blank screen** — cari fix atau stay di <357
- [ ] **MGLRU** — backport multi-gen LRU (massive effort, ditunda)
- [ ] **KCAL** — display color control (MTK panel not compatible)
- [ ] **AutoSMP** — hotplug alternatif
- [x] **KernelSU next-gen** — migrasi ke KernelSU-Next v3.3.0 (v0.8.0)
- [ ] **Toolchain benchmarking** — evaluasi performa Clang 24 vs 19 vs Gino
- [ ] **Upstream 4.14.x terbaru** — kernel.org update aman selama < 357

---

## Feature Comparison: Phrolova vs Tendou-Arisu

| Fitur | Phrolova | Tendou-Arisu |
|---|---|---|
| KernelSU | ✓ (KernelSU-Next v3.3.0) | ✓ |
| NoMount | ✓ | ✗ |
| WireGuard | ✓ | ✗ |
| BBR | ✓ | ✓ |
| ZRAM ZSTD | ✓ | ✓ |
| BFQ | ✓ | ✓ |
| FPSGO | ✓ | ✓ |
| SCHEDUTIL | ✓ | ✓ |
| Kprofiles | ✓ | ✗ |
| Simple LMK | ✓ | ✗ |
| NEON | ✓ | ? |
| TTL/Hotspot | ✓ | ? |
| AnyKernel MTK fix | ✓ (block=auto) | ✓ (block=auto) |
| Droidspaces compatible | ✓ | ✓ |
| CI/CD | ✓ | n/a |
| Toolchain | Greenforce Clang 24 | Gino Clang 22 |
| CC_STACKPROTECTOR | NONE (perf) | STRONG |
| vmalloc | 320MB | 496MB |
| ZRAM | 2GB ZSTD | ? |
| Security mitigations | Minimal (perf-first) | Stock |
| Build Type | Universal | Universal |

---

## Security Roadmap

**Current posture:** Performance-first kernel, mitigasi sengaja di-disable untuk speed.

### Phase S1 — Gap Analysis (v0.8.0)

- [ ] **CVE inventory:** Daftar CVE critical yang belum di-patch
  - Scan kernel 4.14.357 against latest 4.14.y reference (OpenELA LTS)
  - Prioritize: remote-code-exec, privilege-escalation, UAF in core subsystems
  - CVSS 9.0+ = must patch, CVSS 7.0-8.9 = eval, below 7.0 = backlog
- [ ] **ASB catch-up:** Merge ASB tags yang terlewat (2024-06, 2024-10, 2025)
  - Cari Android 4.14 stable branch patches terbaru
  - Atau cherry-pick dari `aosp/kernel/common` android-4.14-stable
- [ ] **CVE tracking framework:** Dokumen berisi CVE status per komponen
  - Format: `| CVE | Komponen | CVSS | Patched? | Patch source |`
  - Integrasi ke CI: cek CVE otomatis?

### Phase S2 — Low-Hanging Fruit (v0.8.x)

Mitigasi ringan yang ga ngaruh performa:

- [ ] **Enable `ARM64_SSBD`** — Speculative Store Bypass Disable
  - Overhead: minimal (hanya set 1 bit di firmware/hardware)
  - Covers: CVE-2018-3639
  - Guard di AGENTS.md: MTK CPU mungkin perlu SMC call — verify dulu
- [ ] **Enable `HARDEN_BRANCH_PREDICTOR`** — Spectre v2 mitigation
  - Overhead: negligible on ARM64 with KASLR
  - Covers: CVE-2017-5715
- [ ] **Enable `MITIGATE_SPECTRE_BRANCH_HISTORY`** — Spectre-BHB
  - Re-enable (currently disabled for perf)
  - Benchmark dulu — overhead reported minimal on MTK G88
- [ ] **`CONFIG_DEBUG_LIST=y`** — detect corrupted list operations
  - Overhead: very small, catches memory corruption bugs
  - Covers: kernel memory safety
- [ ] **`CONFIG_BUG_ON_DATA_CORRUPTION=y`** — panic on data corruption
  - Better than silent corruption leading to exploitable states

### Phase S3 — Stack Protector Re-eval (v0.9.0)

`CC_STACKPROTECTOR_STRONG=n` adalah tradeoff terbesar. Evaluasi ulang:

- [ ] **Benchmark perf with `CC_STACKPROTECTOR_REGULAR`** vs Strong vs None
  - Regular protects functions with >=8 byte array on stack = smaller coverage
  - Hitung overhead real di MT6768 (bukan angka teoretis)
- [ ] **If overhead < 1%:** Enable `CC_STACKPROTECTOR_REGULAR`
  - Covers: stack buffer overflow detection (CVE-2024-*, CVE-2023-*)
  - Prebuilt `.o_shipped` check: drv `gf_spi_tee` depends on `__stack_chk_guard`, but disabled

### Phase S4 — Kernel Self Protection (v0.9.x)

- [ ] **`CONFIG_INIT_ON_ALLOC_DEFAULT=y`** — zero-initialize heap allocations
  - Overhead: boot-time only (pages pre-zeroed), runtime zeroing of slab objects
  - Covers: info leaks via uninit memory
  - Alternative: `CONFIG_INIT_STACK_ALL_ZERO=y` (Clang only, safer)
- [ ] **`CONFIG_SLAB_FREELIST_HARDENED=y`** — random freelist for slab
  - Overhead: minimal (XOR with random canary)
  - Covers: heap spraying attacks
- [ ] **`CONFIG_SLAB_FREELIST_RANDOM=y`** — randomize slab freelist order
  - Overhead: minimal (random shuffle at alloc time)
  - Covers: deterministic heap layout prevention
- [ ] **`CONFIG_RANDOMIZE_KSTACK_OFFSET=y`** — randomize kernel stack offset
  - Overhead: negligible (adds random nop at entry)
  - Covers: stack-based info leaks
- [ ] **`CONFIG_HARDEN_EL2_VECTORS=y`** — harden hyp vectors (ARM64)
  - Overhead: none (boot-time config)
  - Covers: EL2 exploitation

### Phase S5 — SELinux + KSU Hardening (v1.0.0)

- [ ] **KernelSU denials audit:** Review SELinux denials from `/dev/ksu` access
  - Verifikasi `su` context transition works dengan KernelSU-Next
  - Fix overly broad rules (commit `1f327721c0` removed dangerous ones, verify)
- [ ] **NoMount SELinux context:** Pastikan injected virtual files punya context yang benar
  - Test: `ls -Z` on NoMount-redirected paths shows proper context
  - Jika tidak: device nodes bisa diakses tanpa label → denial or security hole
- [ ] **KernelSU exec path hardening:** Verifikasi `kallsyms_lookup_name` gak bisa dipanggil dari userspace
  - CVE-2022-20424: kallsyms exposure
  - Pastikan `kptr_restrict` dan `dmesg_restrict` proper
- [ ] **`CONFIG_STRICT_KERNEL_RWX=y`** — mark kernel text + rodata as read-only
  - Already should be enabled on ARM64 (verify)

### Phase S6 — Monitoring & Incident Response (ongoing)

- [ ] **CI-based CVE scanning:** Script untuk scan commit messages vs CVE database
  - `scripts/cve-scan.sh` — cek commit range for known CVE patterns
- [ ] **Update cadence:** Target patch within 30 days of CVE disclosure for critical
- [ ] **Security changelog:** Tambah `SECURITY.md` dengan CVE tracking table per release
- [ ] **User advisories:** Telegram notif format untuk urgent security updates

### Mitigations NOT Planned

| Mitigation | Reason |
|---|---|
| `CC_STACKPROTECTOR_STRONG` | Perf overhead too high for gaming kernel |
| `HARDENED_USERCOPY` segfault | Already enabled, but perf impact is borderline |
| `SLUB_DEBUG` | Large memory + perf overhead |
| `CONFIG_DEBUG_OBJECTS` | High runtime overhead |
| `CONFIG_PAGE_POISONING` | High memory overhead |
| `FORTIFY_SOURCE` | Already enabled (low overhead) |
| `KASAN` | Dev only, huge overhead |
| `UBSAN` | Dev only, huge overhead |
| `SELINUX_AVC_STATS` | Already disabled, low security value |
