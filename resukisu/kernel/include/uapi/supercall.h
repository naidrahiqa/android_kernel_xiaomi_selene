#ifndef __KSU_UAPI_SUPERCALL_H
#define __KSU_UAPI_SUPERCALL_H

#include <linux/ioctl.h>
#include <linux/types.h>

#include "uapi/app_profile.h"
#include "uapi/feature.h"
#include "uapi/selinux.h"

#define DEFINE_KSU_UAPI_CONST(type, name, val) \
    enum { name = (val) }; \
    static const type name##_RUST = (val);

#define KSU_FULL_VERSION_STRING 255

static const __u32 KERNEL_SU_UAPI_VERSION = 2;

DEFINE_KSU_UAPI_CONST(__u32, KSU_INSTALL_MAGIC1, 0xDEADBEEF)
DEFINE_KSU_UAPI_CONST(__u32, KSU_INSTALL_MAGIC2, 0xCAFEBABE)

struct ksu_become_daemon_cmd {
    __u8 token[65];
};

DEFINE_KSU_UAPI_CONST(__u32, EVENT_POST_FS_DATA, 1)
DEFINE_KSU_UAPI_CONST(__u32, EVENT_BOOT_COMPLETED, 2)
DEFINE_KSU_UAPI_CONST(__u32, EVENT_MODULE_MOUNTED, 3)

DEFINE_KSU_UAPI_CONST(__u32, KSU_GET_INFO_FLAG_LKM, (1U << 0))
DEFINE_KSU_UAPI_CONST(__u32, KSU_GET_INFO_FLAG_MANAGER, (1U << 1))
DEFINE_KSU_UAPI_CONST(__u32, KSU_GET_INFO_FLAG_LATE_LOAD, (1U << 2))
DEFINE_KSU_UAPI_CONST(__u32, KSU_GET_INFO_FLAG_PR_BUILD, (1U << 3))

struct ksu_get_info_cmd {
    __u32 version;
    __u32 flags;
    __u32 features;
    __u32 uapi_version;
};

struct ksu_get_info_legacy_cmd {
    __u32 version;
    __u32 flags;
    __u32 features;
};

struct ksu_report_event_cmd {
    __u32 event;
};

struct ksu_set_sepolicy_cmd {
    __u64 data_len;
    __aligned_u64 data;
};

struct ksu_sepolicy_cmd_hdr {
    __u32 cmd;
    __u32 subcmd;
};

struct ksu_check_safemode_cmd {
    __u8 in_safe_mode;
};

struct ksu_get_allow_list_cmd {
    __u32 uids[128];
    __u32 count;
    __u8 allow;
};

struct ksu_new_get_allow_list_cmd {
    __u16 count;
    __u16 total_count;
    __u32 uids[0];
};

struct ksu_uid_granted_root_cmd {
    __u32 uid;
    __u8 granted;
};

struct ksu_uid_should_umount_cmd {
    __u32 uid;
    __u8 should_umount;
};

struct ksu_get_manager_appid_cmd {
    __u32 appid;
};

struct ksu_get_app_profile_cmd {
    struct app_profile profile;
};

struct ksu_set_app_profile_cmd {
    struct app_profile profile;
};

struct ksu_get_feature_cmd {
    __u32 feature_id;
    __u64 value;
    __u8 supported;
};

struct ksu_set_feature_cmd {
    __u32 feature_id;
    __u64 value;
};

struct ksu_get_wrapper_fd_cmd {
    __u32 fd;
    __u32 flags;
};

struct ksu_manage_mark_cmd {
    __u32 operation;
    __s32 pid;
    __u32 result;
};

DEFINE_KSU_UAPI_CONST(__u32, KSU_MARK_GET, 1)
DEFINE_KSU_UAPI_CONST(__u32, KSU_MARK_MARK, 2)
DEFINE_KSU_UAPI_CONST(__u32, KSU_MARK_UNMARK, 3)
DEFINE_KSU_UAPI_CONST(__u32, KSU_MARK_REFRESH, 4)

struct ksu_nuke_ext4_sysfs_cmd {
    __aligned_u64 arg;
};

struct ksu_get_sulog_fd_cmd {
    __u32 flags;
};

struct ksu_manage_try_umount_cmd {
    __aligned_u64 arg;
    __u32 flags;
    __u8 mode;
};

DEFINE_KSU_UAPI_CONST(__u8, KSU_UMOUNT_WIPE, 0)
DEFINE_KSU_UAPI_CONST(__u8, KSU_UMOUNT_ADD, 1)
DEFINE_KSU_UAPI_CONST(__u8, KSU_UMOUNT_DEL, 2)
DEFINE_KSU_UAPI_CONST(__u8, KSU_UMOUNT_GETSIZE_LEGACY, 107)
DEFINE_KSU_UAPI_CONST(__u8, KSU_UMOUNT_GETLIST_LEGACY, 108)
DEFINE_KSU_UAPI_CONST(__u8, KSU_UMOUNT_GETSIZE_NEW, 200)
DEFINE_KSU_UAPI_CONST(__u8, KSU_UMOUNT_GETLIST_NEW, 201)

struct ksu_get_full_version_cmd {
    char version_full[KSU_FULL_VERSION_STRING];
};

struct ksu_hook_type_cmd {
    char hook_type[32];
};

DEFINE_KSU_UAPI_CONST(__u8, DYNAMIC_MANAGER_OP_SET, 0)
DEFINE_KSU_UAPI_CONST(__u8, DYNAMIC_MANAGER_OP_GET, 1)
DEFINE_KSU_UAPI_CONST(__u8, DYNAMIC_MANAGER_OP_WIPE, 2)
DEFINE_KSU_UAPI_CONST(__u8, DYNAMIC_MANAGER_OP_SET_SYNCHRONOUS, 3)

struct ksu_dynamic_manager_cmd {
    __u8 operation;
    unsigned int size;
    __u8 hash[64];
};

struct ksu_manager_entry {
    __u32 uid;
    __u8 signature_index;
} __attribute__((packed));

struct ksu_get_managers_cmd {
    __u16 count;
    __u16 total_count;
    struct ksu_manager_entry managers[];
} __attribute__((packed));

DEFINE_KSU_UAPI_CONST(__u8, KERNEL_PATCH_NOT_FOUND, 0)
DEFINE_KSU_UAPI_CONST(__u8, KERNEL_PATCH_ORIGINAL, 1)
DEFINE_KSU_UAPI_CONST(__u8, KERNEL_PATCH_KPN, 2)
DEFINE_KSU_UAPI_CONST(__u8, KERNEL_PATCH_SUKISU, 3)

struct ksu_get_kernel_patch_implement {
    __u8 type;
};

DEFINE_KSU_UAPI_CONST(__u32, KSU_IOCTL_GRANT_ROOT, _IOC(_IOC_NONE, 'K', 1, 0))
DEFINE_KSU_UAPI_CONST(__u32, KSU_IOCTL_GET_INFO, _IOR('K', 2, struct ksu_get_info_cmd))
DEFINE_KSU_UAPI_CONST(__u32, KSU_IOCTL_GET_INFO_LEGACY, _IOC(_IOC_READ, 'K', 2, 0))
DEFINE_KSU_UAPI_CONST(__u32, KSU_IOCTL_REPORT_EVENT, _IOC(_IOC_WRITE, 'K', 3, 0))
DEFINE_KSU_UAPI_CONST(__u32, KSU_IOCTL_SET_SEPOLICY, _IOC(_IOC_READ | _IOC_WRITE, 'K', 4, 0))
DEFINE_KSU_UAPI_CONST(__u32, KSU_IOCTL_CHECK_SAFEMODE, _IOC(_IOC_READ, 'K', 5, 0))
DEFINE_KSU_UAPI_CONST(__u32, KSU_IOCTL_GET_ALLOW_LIST, _IOC(_IOC_READ | _IOC_WRITE, 'K', 6, 0))
DEFINE_KSU_UAPI_CONST(__u32, KSU_IOCTL_GET_DENY_LIST, _IOC(_IOC_READ | _IOC_WRITE, 'K', 7, 0))
DEFINE_KSU_UAPI_CONST(__u32, KSU_IOCTL_NEW_GET_ALLOW_LIST, _IOWR('K', 6, struct ksu_new_get_allow_list_cmd))
DEFINE_KSU_UAPI_CONST(__u32, KSU_IOCTL_NEW_GET_DENY_LIST, _IOWR('K', 7, struct ksu_new_get_allow_list_cmd))
DEFINE_KSU_UAPI_CONST(__u32, KSU_IOCTL_UID_GRANTED_ROOT, _IOC(_IOC_READ | _IOC_WRITE, 'K', 8, 0))
DEFINE_KSU_UAPI_CONST(__u32, KSU_IOCTL_UID_SHOULD_UMOUNT, _IOC(_IOC_READ | _IOC_WRITE, 'K', 9, 0))
DEFINE_KSU_UAPI_CONST(__u32, KSU_IOCTL_GET_MANAGER_APPID, _IOC(_IOC_READ, 'K', 10, 0))
DEFINE_KSU_UAPI_CONST(__u32, KSU_IOCTL_GET_APP_PROFILE, _IOC(_IOC_READ | _IOC_WRITE, 'K', 11, 0))
DEFINE_KSU_UAPI_CONST(__u32, KSU_IOCTL_SET_APP_PROFILE, _IOC(_IOC_WRITE, 'K', 12, 0))
DEFINE_KSU_UAPI_CONST(__u32, KSU_IOCTL_GET_FEATURE, _IOC(_IOC_READ | _IOC_WRITE, 'K', 13, 0))
DEFINE_KSU_UAPI_CONST(__u32, KSU_IOCTL_SET_FEATURE, _IOC(_IOC_WRITE, 'K', 14, 0))
DEFINE_KSU_UAPI_CONST(__u32, KSU_IOCTL_GET_WRAPPER_FD, _IOC(_IOC_WRITE, 'K', 15, 0))
DEFINE_KSU_UAPI_CONST(__u32, KSU_IOCTL_MANAGE_MARK, _IOC(_IOC_READ | _IOC_WRITE, 'K', 16, 0))
DEFINE_KSU_UAPI_CONST(__u32, KSU_IOCTL_NUKE_EXT4_SYSFS, _IOC(_IOC_WRITE, 'K', 17, 0))
DEFINE_KSU_UAPI_CONST(__u32, KSU_IOCTL_MANAGE_TRY_UMOUNT, _IOC(_IOC_WRITE, 'K', 18, 0))
DEFINE_KSU_UAPI_CONST(__u32, KSU_IOCTL_SET_INIT_PGRP, _IO('K', 19))
DEFINE_KSU_UAPI_CONST(__u32, KSU_IOCTL_GET_SULOG_FD, _IOW('K', 20, struct ksu_get_sulog_fd_cmd))
DEFINE_KSU_UAPI_CONST(__u32, KSU_IOCTL_DISABLE_ESCAPE_TO_ROOT, _IO('K', 21))

DEFINE_KSU_UAPI_CONST(__u32, KSU_IOCTL_GET_FULL_VERSION, _IOC(_IOC_READ, 'K', 100, 0))
DEFINE_KSU_UAPI_CONST(__u32, KSU_IOCTL_HOOK_TYPE, _IOC(_IOC_READ, 'K', 101, 0))
DEFINE_KSU_UAPI_CONST(__u32, KSU_IOCTL_DYNAMIC_MANAGER, _IOC(_IOC_READ | _IOC_WRITE, 'K', 103, 0))
DEFINE_KSU_UAPI_CONST(__u32, KSU_IOCTL_GET_MANAGERS, _IOC(_IOC_READ | _IOC_WRITE, 'K', 105, 0))
DEFINE_KSU_UAPI_CONST(__u32, KSU_IOCTL_GET_KERNEL_PATCH_IMPLEMENT, _IOC(_IOC_READ, 'K', 106, 0))

#undef DEFINE_KSU_UAPI_CONST
#endif
