# Perbandingan Hook Mode: Hookless vs Kprobes (KernelSU-Next)

Dokumen ini menjelaskan dua mekanisme hook yang dipakai KernelSU-Next v3.3.0
(dev @ `e7536f0`) di Phrolova Kernel (Linux 4.14.356, non-GKI, MT6768 selene).

**Kesimpulan singkat:** KernelSU-Next di kernel ini berjalan **hybrid** —
core root pakai **hookless** (syscall table patch + tracepoint), sedangkan
**kprobes** hanya untuk fitur opsional dan bersifat fail-safe (gagal register
= fitur mati, root tetap jalan).

---

## 1. Hookless (Syscall Table Patch + sys_enter Tracepoint)

### Mekanisme

1. **Resolusi simbol** (`infra/symbol_resolver.c`): cari alamat `sys_call_table`
   via `kallsyms_lookup_name` / `kallsyms_on_each_symbol`. Butuh
   `CONFIG_KALLSYMS=y` + `CONFIG_KALLSYMS_ALL=y`.
2. **Cari slot kosong** (`hook/arm64/syscall_hook.c`): scan `sys_call_table`,
   temukan slot yang masih menunjuk ke `sys_ni_syscall` (syscall yang tidak
   dipakai). Slot ini jadi **dispatcher**.
3. **Patch memori** (`hook/arm64/patch_memory.c`, `ksu_patch_text`):
   - Walk page table `init_mm` (`phys_from_virt`) → dapatkan physical address.
   - Map via fixmap `FIX_TEXT_POKE0` → `copy_to_kernel_nofault` tulis handler
     dispatcher ke slot tersebut.
   - Flush dcache + icache, semua di dalam `stop_machine()` (semua CPU berhenti
     sesaat → tidak ada race).
   - Tidak menyentuh PTE langsung → kompatibel dengan proteksi vendor
     (mis. MTK MKP di EL2) karena meniru `aarch64_insn_write` (fixmap).
4. **Routing** (`hook/syscall_hook_manager.c`): `register_trace_prio_sys_enter`
   — saat syscall yang di-hook (setresuid, execve, newfstatat, faccessat)
   dipanggil, tracepoint menulis ulang `regs->syscallno` ke slot dispatcher,
   lalu dispatcher meneruskan ke handler asli (`ksu_handle_*`).

### Persyaratan Kconfig

| Config | Alasan |
|---|---|
| `CONFIG_KALLSYMS=y` | Resolusi `sys_call_table` |
| `CONFIG_KALLSYMS_ALL=y` | Simbol non-function ikut di-export |
| `CONFIG_TRACEPOINTS=y` | `register_trace_prio_sys_enter` |
| `CONFIG_FIXMAP` (selalu aktif di arm64) | `FIX_TEXT_POKE0` untuk patch |
| `CONFIG_STOP_MACHINE` (bawaan) | Sinkronisasi patch antar CPU |

### Kelebihan

- **Deterministik** — tidak bergantung pada breakpoint/opcode rewrite kernel.
- **Overhead runtime ~0** — syscall diarahkan lewat slot yang sudah di-patch;
  per-syscall cuma 1 jump tambahan + 1 tracepoint check.
- **Tidak perlu kprobes** — jalan di kernel mana pun yang punya KALLSYMS +
  TRACEPOINTS (termasuk 4.14 vanilla yang tidak punya kprobes arm64).
- **Fail-safe boot** — kalau patch gagal (slot tidak ketemu dll.), hanya
  dicatat di log; tidak ada bootloop.

### Kekurangan

- Bergantung pada **`sys_ni_syscall` slot yang tersedia** — butuh setidaknya
  1 slot kosong di `sys_call_table` (hampir selalu ada).
- **Tracepoint overhead** — `sys_enter` tracepoint tetap dipasang meski tidak
  ada syscall yang di-hook (kecil, tapi ada).
- Butuh **KALLSYMS_ALL** — sedikit menambah ukuran image + informasi simbol
  kernel lebih terbuka (tradeoff keamanan vs kebutuhan root).
- Patch memori kernel text = **teknik rootkit**; antivirus/anti-cheat modern
  (KNOX, Play Integrity) bisa mendeteksi syscall table yang berubah.

---

## 2. Kprobes (Dynamic Instrumentation)

### Mekanisme

Kprobes adalah framework instrumentasi kernel (breakpoint-based, via
`register_kprobe` / `register_kretprobe`). KernelSU-Next menggunakannya untuk
fitur **opsional**:

| Fitur | File | Kprobe target | Efek kalau gagal register |
|---|---|---|---|
| Reboot supercall | `supercall/supercall.c` | `sys_reboot` (pre-handler) | Supercall reboot mati, sisanya jalan |
| AVC spoof (log hiding) | `extras.c` (dalam `#ifdef CONFIG_KPROBES`) | `slow_avc_audit` | Log avc tidak di-spoof |
| Key event detection | `runtime/ksud_integration.c` | `input_handle_event` | Kombinasi tombol untuk aksi khusus mati |
| Tracepoint refcount tracking | `hook/syscall_hook_manager.c` (dalam `#ifdef CONFIG_KRETPROBES`) | `syscall_regfunc` / `syscall_unregfunc` (kretprobe) | Proses tidak di-mark otomatis saat tracepoint dipakai tool lain |

### Persyaratan Kconfig

| Config | Alasan |
|---|---|
| `CONFIG_KPROBES=y` | Kconfig KernelSU-Next `depends on KPROBES && EXT4_FS`; kode memakai `<linux/kprobes.h>` secara unconditional di beberapa file |
| `CONFIG_MODULES=y` | Di tree 4.14 ini `KPROBES depends on MODULES` |
| `CONFIG_KRETPROBES=y` | Untuk kretprobe `syscall_regfunc` (di-select otomatis oleh HAVE_KRETPROBES) |
| Backport arm64 kprobes | **Wajib ada di tree** — vanilla upstream 4.14 arm64 TIDAK punya (kprobes arm64 masuk upstream 4.16); vendor MTK sudah backport (`arch/arm64/Kconfig`: `select HAVE_KPROBES`) |

### Kelebihan

- **Fleksibel** — bisa hook fungsi kernel apa pun tanpa mengubah source-nya.
- **Tidak mengubah syscall table** — tidak ada tanda "tampered syscall table"
  yang mudah dideteksi anti-cheat (tapi breakpoint juga bisa dideteksi).
- **Per-fit&start** — fitur yang gagal register tidak merusak yang lain.

### Kekurangan

- **Overhead per-call** — trap ke debugger trap handler + handler callback,
  lebih mahal dari 1 jump syscall table (relevan untuk hot path seperti
  `input_handle_event` saat disentuh terus-menerus).
- **Kestabilan kernel-dependent** — kalau kprobes kernelnya buggy/berkonflik
  (kprobe pada fungsi yang dipakai vendor, race dengan ftrace, dsb.) bisa
  crash/bootloop. Dokumentasi resmi KernelSU-Next menyarankan: kalau kprobe
  rusak, perbaiki atau pakai metode manual (fs/ hooks).
- **Kompatibilitas API** — tiap versi kernel beda-beda (`kprobe_opcode_t`,
  handler signature); backport vendor bisa beda perilaku.

---

## 3. Tabel Perbandingan

| Aspek | Hookless (syscall table + tracepoint) | Kprobes |
|---|---|---|
| Target hook | 1 slot `sys_call_table` (dispatcher) | Fungsi kernel bebas (breakpoint) |
| Mekanisme | Patch memori (fixmap) + tracepoint routing | Trap handler (breakpoint/opcode rewrite) |
| Overhead runtime | Sangat rendah (1 jump + tracepoint check) | Lebih tinggi (trap + callback per-call) |
| Kebutuhan simbol | KALLSYMS + KALLSYMS_ALL | Hanya nama simbol (kallsyms optional via `kallsyms_lookup_name`) |
| Kebutuhan kernel API | `stop_machine`, fixmap, tracepoint, `copy_to_kernel_nofault` | `register_kprobe`/`register_kretprobe` + arch kprobes support |
| Jalan di 4.14 arm64 vanilla (tanpa backport)? | **Ya** | **Tidak** (arm64 kprobes baru di upstream 4.16) |
| Resiko bootloop | Sangat rendah (gagal = log saja) | Ada (kprobe bug/konflik) |
| Deteksi anti-cheat | Syscall table termodifikasi bisa dideteksi | Breakpoint/opcode juga bisa dideteksi |
| Pemakaian di KernelSU-Next | **Core root** (execve, setresuid, newfstatat, faccessat) | Fitur opsional (reboot supercall, avc_spoof, key event, kretprobe refcount) |
| Failure mode | Root tidak aktif, log error | Fitur terkait mati, root tetap jalan |

---

## 4. Kondisi di Phrolova (selene)

- **Hookless-only (sejak v0.8.1):** kprobes di-disable total.
  - `CONFIG_KPROBES=n` di `selene_defconfig` — framework kprobes tidak ada di kernel image sama sekali (tidak ada breakpoint infrastructure, lebih aman).
  - Kconfig KernelSU-Next di-patch: `depends on KPROBES && EXT4_FS` → `depends on EXT4_FS` (upstream beda).
  - Kode kprobe di `ksu-next/kernel` di-guard `#ifdef CONFIG_KPROBES` → compiled-out.
- Konsekuensi (fitur ini mati, root **tetap** jalan):
  - Reboot supercall via `sys_reboot` magic (fd-install via reboot — aman, karena manager fd-install utama lewat `ksu_handle_setresuid` di `hook/setuid_hook.c:37`).
  - AVC spoof (`slow_avc_audit`) — log avc denial tidak di-hide.
  - Key-event hook (`input_event` kprobe) — kombinasi tombol ksud mati.
  - `syscall_regfunc` kretprobe — fallback aktif: `#ifndef CONFIG_KRETPROBES` → `ksu_mark_running_process_locked()` langsung di `ksu_syscall_hook_manager_init`.
- Yang jalan (semua hookless):
  - Dispatcher `sys_call_table` (execve, setresuid, newfstatat, faccessat, read, fstat) via `ksu_patch_text`.
  - Routing `register_trace_prio_sys_enter`.
  - KALLSYMS_ALL untuk resolusi simbol.
- Diagnosa cepat saat boot:
  ```bash
  dmesg | grep -i -E "ksu|hook_manager"
  # "registered syscall hook for nr=..."  → hookless OK
  # "hook_manager: sys_enter tracepoint registered" → routing OK
  # TIDAK ada baris reboot kprobe / input_event_kp — memang mati
  ```

---

## 5. Jika Suatu Saat Kprobes Benar-Benar Rusak

KernelSU-Next menyediakan jalur fallback **manual hooks** (patch `fs/exec.c`,
`fs/open.c`, `fs/read_write.c`, `fs/stat.c`, `kernel/reboot.c` dengan
`ksu_handle_*`) — metode ini tidak butuh kprobes maupun tracepoint, tapi
wajib patch source kernel. Dokumentasi resmi: [Integrate for non-GKI
devices](https://kernelsu-next.github.io/webpage/pages/how-to-integrate-for-non-gki.html).
Phrolova saat ini **tidak** memakai jalur ini.
