#ifndef __KSU_H_UTIL
#define __KSU_H_UTIL

#include "linux/fdtable.h" // IWYU pragma: keep
#include <linux/version.h>
#include <linux/syscalls.h>

#if LINUX_VERSION_CODE >= KERNEL_VERSION(5, 11, 0)
#define ksu_close_fd close_fd
#else
// MTK 4.14 selene tree has no ksys_close (removed by vendor); sys_close exists.
#define ksu_close_fd sys_close
#endif

#endif
