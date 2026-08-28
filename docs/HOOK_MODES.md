# Perbandingan Hook Mode: ReSukiSU Manual Hook (non-GKI) vs TP-Hook (GKI2)

Dokumen ini menjelaskan mekanisme hook root solution ReSukiSU (main @
`25d94deb`, KSU_VERSION 35097) di Phrolova Kernel (Linux 4.14.356, non-GKI,
MT6768 selene).

**Kesimpulan singkat:** Kernel 4.14 non-GKI **wajib manual hook** — patch
langsung ke source kernel (`fs/exec.c`, `fs/open.c`, `fs/stat.c`,
`kernel/reboot.c`) dengan fungsi `ksu_handle_*`. TP-hook (syscall table
redirect) hanya jalan di GKI2 (5.10+); di non-GKI Kbuild ReSukiSU menolak
dengan `$(error)`.

---

## 1. Manual Hook (dipakai di selene)

### Mekanisme

1. **Patch source kernel** — fungsi `ksu_handle_*` dipanggil langsung di
   syscall handler kernel:

   | File | Hook | Posisi |
   |---|---|---|
   | `fs/exec.c` | `ksu_handle_execveat` | `do_execve` + `compat_do_execve` |
   | `fs/open.c` | `ksu_handle_faccessat` | `SYSCALL_DEFINE3(faccessat)` |
   | `fs/stat.c` | `ksu_handle_stat` | `newfstatat` + `fstatat64` |
   | `fs/stat.c` | `ksu_handle_newfstat_ret` | `newfstat` |
   | `fs/stat.c` | `ksu_handle_fstat64_ret` | `fstat64` |
   | `kernel/reboot.c` | `ksu_handle_sys_reboot` | `SYSCALL_DEFINE4(reboot)` |

2. **Hook tambahan otomatis** (`<6.8`, tidak perlu patch manual):
   - setuid → LSM (`CONFIG_KSU_MANUAL_HOOK_AUTO_SETUID_HOOK`, `hook/setuid_hook.c`)
   - initrc/read → LSM (`CONFIG_KSU_MANUAL_HOOK_AUTO_INITRC_HOOK`)
   - input key event → input_handler (`CONFIG_KSU_MANUAL_HOOK_AUTO_INPUT_HOOK`)

3. **Verifikasi build-time** — `resukisu/kernel/tools/manual_hook_check.mk`
   grep tiap string `ksu_handle_*` di file kernel saat build; hook hilang
   atau hook lama (`ksu_vfs_read_hook`, `is_ksu_transition`,
   `ksu_handle_rename`) = compile error.

### Persyaratan Kconfig

| Config | Alasan |
|---|---|
| `CONFIG_KSU=y` | Aktifkan ReSukiSU |
| `CONFIG_KSU_MANUAL_HOOK=y` | Mode manual hook (wajib non-GKI) |
| `CONFIG_KSU_MULTI_MANAGER_SUPPORT=y` | Terima manager KernelSU/MKSU/RKSU/SukiSU-Ultra (default y) |
| `CONFIG_KALLSYMS=y` + `CONFIG_KALLSYMS_ALL=y` | Resolusi simbol tanpa static export patch |
| `CONFIG_TRACEPOINTS=y` | Dibutuhkan driver FPSGO (bukan ReSukiSU) |

Kprobes **tidak dibutuhkan** sama sekali. `CONFIG_EXT4_FS=y` dipertahankan
(boot_event pakai ext4 helpers).

### Kelebihan

- **Jalan di semua kernel 3.4+** — tidak tergantung tracepoint GKI,
  kprobes, atau patch memori.
- **Deterministik** — hook ada di source, bukan hasil patch runtime;
  boot gagal-hook tidak mungkin (compile-time).
- **Overhead ~0** — 1 call langsung per syscall yang di-hook.
- **Verifikasi build-time** — salah pasang hook = tidak lolos compile
  (bukan crash di runtime).

### Kekurangan

- **Wajib patch source kernel** — setiap update kernel harus cek ulang
  posisi hook (4.14 source stabil, tapi tetap).
- Hook hanya menutupi syscall tertentu — fitur yang butuh fungsi lain
  (mis. avc_spoof via `slow_avc_audit`) tidak tersedia di mode ini.

---

## 2. TP-Hook (Tracepoint Syscall Redirect, GKI2 only)

### Mekanisme

1. **Resolusi simbol** (`infra/symbol_resolver.c`): cari `sys_call_table`
   via kallsyms (butuh KALLSYMS_ALL).
2. **Slot dispatcher** (`hook/arm64/syscall_hook.c`): scan slot
   `sys_ni_syscall` kosong di `sys_call_table`.
3. **Patch memori** (`hook/arm64/patch_memory.c`, `ksu_patch_text`):
   walk page table → fixmap `FIX_TEXT_POKE0` → tulis handler, flush
   dcache/icache di dalam `stop_machine()`.
4. **Routing** (`hook/syscall_hook_manager.c`): `register_trace_prio_sys_enter`
   menulis ulang `regs->syscallno` ke slot dispatcher.

### Kenapa tidak dipakai di selene

- Kbuild ReSukiSU: `$(error TP hooks are incompatible with Non-GKI/GKI 1.0
  kernels.)` — dukungan resmi hanya GKI2 (5.10+).
- Kernel 4.14 non-GKI tidak punya infrastruktur syscall tracepoint GKI.
- Dokumentasi resmi: https://resukisu.github.io/guide/manual-integrate.html

---

## 3. Tabel Perbandingan

| Aspek | Manual Hook (selene) | TP-Hook (GKI2) |
|---|---|---|
| Target hook | Source kernel (compile-time) | 1 slot `sys_call_table` (runtime patch) |
| Mekanisme | Call `ksu_handle_*` langsung di syscall handler | Patch memori fixmap + tracepoint routing |
| Support kernel | 3.4+ (termasuk 4.14 non-GKI) | GKI2 5.10+ saja |
| Overhead runtime | ~0 (1 call langsung) | 1 jump + tracepoint check |
| Kebutuhan simbol | KALLSYMS_ALL (opsional via static export) | KALLSYMS + KALLSYMS_ALL |
| Verifikasi | Build-time (manual_hook_check.mk) | Runtime (gagal = log, root tidak aktif) |
| Resiko bootloop | Hampir nol (compile-time) | Rendah (gagal = log saja) |
| Deteksi anti-cheat | Tidak ada patch memori | Syscall table termodifikasi bisa dideteksi |

---

## 4. Kondisi di Phrolova (selene)

- **Manual hook (sejak v0.9.0):** ReSukiSU main @ `25d94deb` (v4.2.0-rc1 + 32
  commits, KSU_VERSION 35097) menggantikan KernelSU-Next hookless
  (syscall table + tracepoint) yang dipakai sejak v0.8.0.
- `CONFIG_KPROBES` tidak dibutuhkan dan tidak di-enable.
- Kbuild di-patch lokal: fallback version pin tanpa `.git`
  (`KSU_LOCAL_VERSION := 4397` → `KSU_VERSION = 30000 + 4397 + 700 = 35097`).
- Manager: multi-manager (`CONFIG_KSU_MULTI_MANAGER_SUPPORT=y`). Rekomendasi
  ReSukiSU manager — match KSU_VERSION 35097:
  - https://nightly.link/ReSukiSU/ReSukiSU/workflows/build-manager/main/Manager-release.zip
  - https://t.me/ReSukiSU
- Diagnosa cepat saat boot:
  ```bash
  dmesg | grep -i -E "ksu|resuki"
  # "-- ReSukiSU version code: 35097" → versi benar
  # "ksu: ..." dari hook/setuid_hook.c dll → hook aktif
  ```

---

## 5. Sejarah

| Versi | Root solution | Hook mode |
|---|---|---|
| ≤ v0.7.x | backslashxx/KernelSU | Syscall table patch |
| v0.8.0 – v0.8.1 | KernelSU-Next v3.3.0 | Hookless: syscall table + sys_enter tracepoint (kprobes off) |
| v0.9.0+ | ReSukiSU main @ 25d94deb | Manual hook (fs/exec.c, fs/open.c, fs/stat.c, kernel/reboot.c) |

Referensi: https://resukisu.github.io/guide/manual-integrate.html