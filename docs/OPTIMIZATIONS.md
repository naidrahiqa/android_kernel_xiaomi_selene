# Phrolova Kernel — Performance & Memory Optimizations
# (v0.4.0 base — diperbarui hingga v0.9.3)

Dokumen ini mencatat seluruh optimasi performa, kompresi memori, dan pengatur lalu lintas jaringan yang diterapkan pada Phrolova Kernel versi `v0.4.0` untuk perangkat Redmi 10 2022 (**selene** / MediaTek Helio G88 MT6768).

---

## 1. Network & Latency Optimization (Google BBR)

### Konfigurasi Kernel:
- `CONFIG_TCP_CONG_ADVANCED=y`
- `CONFIG_TCP_CONG_BBR=y`
- `CONFIG_DEFAULT_BBR=y`
- `CONFIG_DEFAULT_TCP_CONG="bbr"`
- `CONFIG_NET_SCH_FQ=y`
- `CONFIG_NET_SCH_FQ_CODEL=y`

### Penjelasan & Manfaat:
- **Google BBR (Bottleneck Bandwidth and RTT):** Algoritma *congestion control* modern yang memodelkan throughput maksimal dan RTT minimal secara real-time. Tidak seperti CUBIC/RENO yang bergantung pada packet loss, BBR mencegah penumpukan antrean (*bufferbloat*) pada jaringan seluler (4G/LTE) dan Wi-Fi.
- **Fair Queueing (FQ / FQ_CoDel):** Diperlukan oleh BBR untuk pengaturan laju paket (*pacing*), mengurangi *ping latency* saat mendownload atau bermain game online.

---

## 2. ZRAM & Memory Compression (ZSTD + LZ4)

### Konfigurasi Kernel:
- `CONFIG_CRYPTO_ZSTD=y`
- `CONFIG_CRYPTO_LZ4=y`
- `CONFIG_CRYPTO_LZ4HC=y`
- `CONFIG_ZRAM_DEFAULT_COMP_ALGORITHM="zstd"`
- `CONFIG_RD_XZ=y`
- `CONFIG_RD_LZ4=y`

### Penjelasan & Manfaat:
- **ZSTD (Zstandard) Compression:** Menggantikan algoritma LZO standar di ZRAM. ZSTD memberikan rasio kompresi jauh lebih tinggi (~1.5x lebih padat daripada LZO) dengan kecepatan dekompresi yang mendekati kecepatan RAM fisik.
- **Hasil untuk RAM 4GB/6GB:** Memungkinkan sistem menyimpan lebih banyak aplikasi di background tanpa triggering OOM (Out Of Memory) killer atau app reload, sangat membantu pada MIUI/HyperOS maupun Custom ROM.

### ZRAM ZSTD Level Tuning (v0.9.7):
- `ZSTD_DEF_LEVEL` 3 → 5: ZSTD level 5 pakai `ZSTD_greedy` strategy → ~15-20% better compression ratio.
- CPU overhead ~30% lebih tinggi tapi masih aman di Cortex-A75/A55 (MT6768).
- Lebih banyak data terkompresi di 2GB ZRAM → lebih sedikit app reload di 4GB RAM device.

---

## 3. Storage & Disk I/O Scheduling (BFQ)

### Konfigurasi Kernel:
- `CONFIG_IOSCHED_BFQ=y`
- `CONFIG_BFQ_GROUP_IOSCHED=y`
- `CONFIG_DEFAULT_BFQ=y`
- `CONFIG_DEFAULT_IOSCHED="bfq"`

### Penjelasan & Manfaat:
- **BFQ (Budget Fair Queueing):** I/O Scheduler berbasis BLK-MQ yang mengalokasikan bandwidth storage secara adil berdasarkan bobot proses.
- **Mencegah UI Lag:** Saat ada background write/install aplikasi yang intensif, BFQ memberikan prioritas tinggi pada proses UI interaktif dan layar sentuh, sehingga perangkat tidak terasa patah-patah (*stutter-free*).

### BFQ Default Tuning (v0.9.7):
- `slice_idle` 8ms → 2ms: eMMC 5.1 gak butuh idle sepanjang HDD. 2ms kurangi latency multi-queue saat game load asset.
- `fifo_expire_sync` 250ms → 150ms: tighter sync expiry, background I/O gak block game I/O.
- Runtime tunable via `/sys/block/*/queue/iosched/` — user bisa override kapan saja.

---

## 4. CPU & Energy-Aware Scheduling (EAS / Schedutil)

### Konfigurasi Kernel:
- `CONFIG_CPU_FREQ_DEFAULT_GOV_SCHEDUTIL=y`
- `CONFIG_DEFAULT_USE_ENERGY_AWARE=y`
- `CONFIG_UCLAMP_TASK=y`
- `CONFIG_PELT_UTIL_HALFLIFE_16=y`

### Penjelasan & Manfaat:
- **Schedutil & EAS:** Menyesuaikan frekuensi CPU secara dinamis berdasarkan sinyal beban utilitas dari scheduler kernel, mengoptimalkan konsumsi daya baterai Helio G88 tanpa mengorbankan responsiveness.

---

## 5. BBR Enforcement (v0.9.3)

### Masalah:
- `/vendor/etc/init/networksetting.rc` (bawaan Huaqin/MIUI) menulis `tcp_congestion_control=bic` di early-init, **menimpa** default BBR dari defconfig. Hasil live device: `bic` aktif → throughput jelek di link seluler lossy.

### Solusi:
- `# CONFIG_TCP_CONG_BIC is not set` di `selene_defconfig` — modul BIC tidak ada di kernel sehingga sysctl write vendor gagal diam-diam dan default tetap **BBR**.

### Verifikasi pasca-flash:
```
cat /proc/sys/net/ipv4/tcp_congestion_control   # harus: bbr
```

---

## 6. Fast Charge Unlock (v0.9.3)

### Masalah:
- Thermal HAL userspace menulis psy `CHARGE_CONTROL_LIMIT` → `charger_manager_set_prop_system_temp_level()` → tabel `thermal_mitigation_dcp/qc2/qc3[]` menurunkan input current limit QC/HVDCP dari 2–3A ke 1.5A bahkan 900mA meski suhu baterai aman. Inilah alasan "butuh thermal module" untuk fast charge.

### Solusi:
- `mtk_charger.c`: input current clamp dari `system_temp_level` dinetralkan (`thermal_icl_ua = -1` permanen).
- **Keamanan tetap terjaga oleh lapisan asli:** sw_jeita dts (T4=45°C menurunkan CV/CC) + hardware JEITA bq2589x. Yang dihilangkan hanya throttle policy-level userspace.
- Tabel arus per-tipe charger di dts sudah optimal: DCP 2.05A / HVDCP 2A-in 3A-chg / HVDCP_3 3A.

---

## 7. Display: Backlight Cooler Neutralized (v0.9.3)

### Masalah:
- Cooler `mtk-cl-backlight` menerima tulisan `cur_state` dari daemon thermal userspace → `setMaxbrightness()` meng-clamp/membuang panel (layar mati sendiri padahal sistem hidup). Live evidence: log `cooler/backlight 1610` tepat sebelum `FB_BLANK_POWERDOWN`.

### Solusi:
- `mtk_cooler_backlight_cus.c`: `set_cur_state()` hanya menghormati jalur reset (state == max). Clamp brightness dari thermal policy tidak pernah diterapkan lagi. Mitigasi panas asli (cpufreq/GPU cooler) tidak disentuh.

---

## 8. Verifikasi Artefak (WAJIB pasca-flash)

Kernel yang ter-flash kadang bukan yang dikira (stale release asset). Selalu cek:
```
adb shell su -c 'zcat /proc/config.gz | grep -E "DEFAULT_IOSCHED|USER_NS"'
adb shell cat /proc/sys/net/ipv4/tcp_congestion_control   # bbr
```
Harapannya: `bfq`, `CONFIG_USER_NS=y`. CI (v0.9.3+) punya verification gate + upload `.config` sebagai artifact build.

---

## 9. MTK Stock Configs (v0.9.7)

### Yang Diaktifkan:
- **MTK_PERF_OBSERVER=y** — Performance metric aggregation hub untuk FPSGO/EARA thermal feedback. Reads EMI BW counters dari SSPM SRAM. Monitoring only, no hardware control.
- **MTK_PERF_TRACKER=y** — Performance tracking framework, provides metrics consumed by FPSGO/GBE.
- **MTK_RESYM=y** — Resource Symphony — system resource coordination untuk boost engines.
- **MTK_SWPM=y** — Software Power Meter — per-rail power estimation (VPROC12/VCORE/VGPU/VDRAM1). procfs: `/proc/swpm/`.
- **MTK_QOS_V1=y** — QoS framework untuk DRAM BW management via SSPM IPI. sysfs: `qos_bound_enable`, `qos_bound_status`.
- **MTK_RAM_CONSOLE=y** — Crash log persistence ke reserved DRAM. 26+ MTK drivers write diagnostic data. `/proc/last_kmsg` untuk crash forensics.

### Catatan:
- Semua configs ada di `stock_defconfig` tapi sebelumnya tidak diaktifkan di Phrolova.
- `MTK_RAM_CONSOLE` perlu reserved memory di DTS — driver gagal gracefully kalau tidak ada (no crash).
- `MTK_QOS_V1` depends on `MTK_TINYSYS_SSPM_SUPPORT=y` (sudah aktif).
- `MTK_SWPM` consume 3 PMU counters per CPU — overhead moderat tapi acceptable untuk monitoring.
