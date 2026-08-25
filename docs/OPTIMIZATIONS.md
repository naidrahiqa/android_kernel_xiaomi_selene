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
