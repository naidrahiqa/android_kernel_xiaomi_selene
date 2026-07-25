#include <linux/module.h>
#include <linux/kobject.h>
#include <linux/sysfs.h>
#include <linux/notifier.h>
#include <linux/version.h>
#include "version.h"

#define KP_MODE_OFF		0
#define KP_MODE_BATTERY		1
#define KP_MODE_BALANCED	2
#define KP_MODE_PERFORMANCE	3

static unsigned int kp_mode = CONFIG_KP_DEFAULT_MODE;
static bool auto_kp = true;

static struct kobject *kp_kobj;
static BLOCKING_NOTIFIER_HEAD(kp_notifier_list);

int kp_active_mode(void)
{
	return kp_mode;
}
EXPORT_SYMBOL(kp_active_mode);

void kp_set_mode(unsigned int level)
{
	if (level > KP_MODE_PERFORMANCE)
		return;
	kp_mode = level;
	blocking_notifier_call_chain(&kp_notifier_list, kp_mode, NULL);
}
EXPORT_SYMBOL(kp_set_mode);

void kp_set_mode_rollback(unsigned int level, unsigned int duration_ms)
{
	unsigned int prev = kp_mode;
	kp_set_mode(level);
	msleep(duration_ms);
	kp_set_mode(prev);
}
EXPORT_SYMBOL(kp_set_mode_rollback);

int kp_notifier_register_client(struct notifier_block *nb)
{
	return blocking_notifier_chain_register(&kp_notifier_list, nb);
}
EXPORT_SYMBOL(kp_notifier_register_client);

int kp_notifier_unregister_client(struct notifier_block *nb)
{
	return blocking_notifier_chain_unregister(&kp_notifier_list, nb);
}
EXPORT_SYMBOL(kp_notifier_unregister_client);

#if defined(CONFIG_AUTO_KPROFILES_FB)
#include <linux/notifier.h>
#include <linux/fb.h>

static int kp_fb_notifier_cb(struct notifier_block *nb, unsigned long action, void *data)
{
	struct fb_event *ev = data;
	int *blank;

	if (action != FB_EVENT_BLANK)
		return NOTIFY_OK;
	blank = ev->data;
	if (!auto_kp)
		return NOTIFY_OK;
	if (*blank == FB_BLANK_UNBLANK)
		kp_set_mode(CONFIG_KP_DEFAULT_MODE);
	else
		kp_set_mode(KP_MODE_BATTERY);
	return NOTIFY_OK;
}

static struct notifier_block kp_fb_notifier = {
	.notifier_call = kp_fb_notifier_cb,
};
#endif

static ssize_t kp_mode_show(struct kobject *kobj, struct kobj_attribute *attr, char *buf)
{
	return scnprintf(buf, PAGE_SIZE, "%u\n", kp_mode);
}

static ssize_t kp_mode_store(struct kobject *kobj, struct kobj_attribute *attr, const char *buf, size_t count)
{
	int ret;
	unsigned int val;

	ret = kstrtouint(buf, 10, &val);
	if (ret)
		return ret;

	kp_set_mode(val);
	return count;
}

static struct kobj_attribute kp_mode_attr = __ATTR(kp_mode, 0664, kp_mode_show, kp_mode_store);

static int __init kprofiles_init(void)
{
	int ret;

	kp_kobj = kobject_create_and_add("kprofiles", kernel_kobj);
	if (!kp_kobj)
		return -ENOMEM;

	ret = sysfs_create_file(kp_kobj, &kp_mode_attr.attr);
	if (ret)
		goto err_sysfs;

#if defined(CONFIG_AUTO_KPROFILES_FB)
	fb_register_client(&kp_fb_notifier);
#endif

	pr_info("Kprofiles v%s loaded (default mode: %u)\n",
		KPROFILES_VERSION, CONFIG_KP_DEFAULT_MODE);
	return 0;

err_sysfs:
	kobject_put(kp_kobj);
	return ret;
}

static void __exit kprofiles_exit(void)
{
#if defined(CONFIG_AUTO_KPROFILES_FB)
	fb_unregister_client(&kp_fb_notifier);
#endif
	sysfs_remove_file(kp_kobj, &kp_mode_attr.attr);
	kobject_put(kp_kobj);
	pr_info("Kprofiles unloaded\n");
}

module_init(kprofiles_init);
module_exit(kprofiles_exit);

MODULE_LICENSE("GPL v2");
MODULE_DESCRIPTION("Kprofiles - Kernel power profile manager");
MODULE_VERSION(KPROFILES_VERSION);

module_param(auto_kp, bool, 0664);
MODULE_PARM_DESC(auto_kp, "Enable automatic screen-off profile switching");
