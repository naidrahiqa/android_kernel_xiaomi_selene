# Phrolova Kernel — Roadmap

## Versi Saat Ini: v0.6.0-dev

---

## Fase 1 — Foundation Stabil (done)

- [x] KernelSU backslashxx v3.2.5-26
- [x] NoMount path redirection
- [x] TCP BBR + ZRAM ZSTD + BFQ
- [x] CI/CD pipeline functional (Void Linux container)
- [x] AnyKernel3 MTK A/B slot fix
- [x] Kprofiles — sysfs power profile manager
- [x] Simple LMK — low memory killer
- [x] Kernel Mode NEON — crypto acceleration
- [x] TTL target (hotspot fix)
- [x] Toolchain: Greenforce Clang 24

## Fase 2 — Performance Tuning (v0.7.0)

Target: Benchmark gain + responsivitas.

- [ ] **CPU governor tuning** — custom schedutil parameters (rate limit, up/down thresholds)
- [ ] **GPU frequency table** — adjust Mali G52 MC2 freq steps
- [ ] **Devfreq tuning** — DRAM freq scaling, L3 cache
- [ ] **I/O scheduler** — BFQ tuning (slice_idle, timeout_sync)
- [ ] **ZRAM tuning** — stream count, compression level balancing
- [ ] **VM tuning** — dirty ratio, dirty background ratio, vfs_cache_pressure
- [ ] **Network tuning** — BBR pacing gain, TCP buffer sizes

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
- [ ] **KernelSU next-gen** — upgrade ke backslashxx latest jika stabil
- [ ] **Toolchain benchmarking** — evaluasi performa Clang 24 vs 19 vs Gino
- [ ] **Upstream 4.14.x terbaru** — kernel.org update aman selama < 357

---

## Feature Comparison: Phrolova vs Tendou-Arisu

| Fitur | Phrolova | Tendou-Arisu |
|---|---|---|
| KernelSU | ✓ (backslashxx v3.2.5-26) | ✓ |
| NoMount | ✓ | ✗ |
| WireGuard | ✓ | ✗ |
| BBR | ✓ | ✓ |
| ZRAM ZSTD | ✓ | ✓ |
| BFQ | ✓ | ✓ |
| FPSGO | ✓ | ✓ |
| SCHEDUTIL | ✓ | ✓ |
| AnyKernel MTK fix | ✓ (explicit block) | ✗ (block=auto) |
| CI/CD | ✓ | n/a |
| Toolchain | Greenforce Clang 24 | Gino Clang 22 |
| Build Type | Universal | Universal |
