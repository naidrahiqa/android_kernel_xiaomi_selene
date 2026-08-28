---
name: nomount
description: Use when integrating, debugging, or fixing maxsteeel/nomount systemless path redirection. Covers VFS hook placement, iterate_dir hook fix (double-iterate), NoMount netlink control protocol, and known kernel compatibility issues.
---

# NoMount (maxsteeel/nomount v20)

## Overview

NoMount v20 provides systemless path redirection and virtual file injection **without mounting filesystems**. Compiled into kernel (`CONFIG_NOMOUNT=y`) with **keyring-based** userspace control (`register_key_type("nomount")`, `SYS_ADD_KEY` syscall). Works alongside KernelSU for full root + systemless overlay solution.

**Important:** v20 uses keyring, NOT genetlink. The old v1.x used genetlink + `nomount_handle_*` hooks — all removed in v20.

## Source Files

- `fs/nomount.c` — Main implementation (1491 lines, keyring + RBTree + dentry-op hijacking)
- `fs/nomount.h` — Header (324 lines, structs, compat macros)
- `tools/nomount/nm.c` + `nm.h` — Userspace binary (freestanding arm64, raw `SYS_ADD_KEY`)

## Architecture v20

- **dentry/inode/superblock operation hijacking** — intercepts VFS via `d_op->d_revalidate`, `i_op->lookup`, `f_op->iterate`, `s_op->show_path`
- **Keyring control** — `register_key_type("nomount")` + `request_key()` for userspace communication
- **RBTree rules** — path redirection rules stored in `nomount_rules_tree` (rb_root_cached)
- **UID filtering** — `nomount_active_uids` static key for per-app isolation

## VFS Hooks (v20 — hijacked operations)

v20 does NOT use `nomount_handle_*` functions in VFS files. Instead, it hijacks dentry/inode operations at runtime:

| Operation | Hijacked On | Purpose |
|-----------|-------------|---------|
| `d_revalidate` | dentry ops | Path redirection on lookup |
| `lookup` | inode ops | Intercept file lookup |
| `iterate` | file ops | Inject virtual files in dir listing |
| `show_path` | superblock ops | Mask statfs |

**Note:** All `nomount_handle_*` calls were removed from `dcache.c`, `namei.c`, `readdir.c`, `stat.c`, `statfs.c`, `proc/task_mmu.c` in v0.9.4.

## Module v2.0.0 Requirement

NoMount metamodule v1.x (v1.1.0, v1.1.1) uses **netlink detection** → **false negative** on v20 kernels (keyring-based). The manager app reports "KERNEL DRIVER NOT DETECTED" even though the driver works.

**Solution:** Always use **NoMount module v2.0.0+**:
- Download: `https://github.com/maxsteeel/nomount/releases/download/v2.0.0/NoMount-v2.0.0-release.zip`
- Flash via KernelSU manager → reboot

## Verification

```bash
# Push nm binary from release asset
adb push nm /data/local/tmp/nm
adb shell chmod 755 /data/local/tmp/nm

# Test keyring communication
adb shell su -c "/data/local/tmp/nm version"
# Should return: 20

adb shell su -c "/data/local/tmp/nm rule list"
# Should return: [] (empty)

adb shell su -c "/data/local/tmp/nm uid list"
# Should return: [] (empty JSON array)
```

If `nm version` returns `20` → driver active, keyring works.
If "command not found" → nm binary not installed.
If error → keyring registration failed (check `CONFIG_NOMOUNT=y` in defconfig).

## Build Integration

```makefile
# fs/Kconfig
config NOMOUNT
    bool "NoMount path redirection"
    default n

# fs/Makefile
obj-$(CONFIG_NOMOUNT) += nomount.o
```

CI gate verifies `CONFIG_NOMOUNT` in post-build `.config`.

## Known Compatibility Issues

| Issue | Status |
|-------|--------|
| gnu89 `for (int i ...)` | Fixed — variable declarations hoisted to block scope |
| `struct rb_node` in for-init | Fixed — C99 extension warning (gnu89 compat) |
| Module v1.x netlink detection | Fixed — use module v2.0.0+ |
| `select TCP_CONG_BIC` in vendor Kconfig | Fixed in v0.9.4 — line removed |

## References

- Source: `https://github.com/maxsteeel/nomount` (branch: main)
- Module v2.0.0: `https://github.com/maxsteeel/nomount/releases/download/v2.0.0/NoMount-v2.0.0-release.zip`
- nm binary: built from `tools/nomount/nm.c` in kernel tree, uploaded as release asset
