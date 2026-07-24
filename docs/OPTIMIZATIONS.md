# Phrolova Kernel — Performance & Memory Optimizations (v0.4.0)

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
