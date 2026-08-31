#!/bin/bash
# Telegram Notification - Phrolova Kernel
# Usage: bash notify-telegram.sh <status> <version> <tag> [file]
# Status: start | success | failed
#
# Required GitHub Secrets:
#   TELEGRAM_BOT_TOKEN        - Bot token from @BotFather
#   TELEGRAM_CHANNEL_ID       - Main channel (build start + success)
#   TELEGRAM_ERROR_CHANNEL_ID - Error channel (build failed)

STATUS="${1:-unknown}"
VERSION="${2:-unknown}"
TAG="${3:-$VERSION}"

VARIANT_NAME="Stable"
case "$VERSION" in
	*nightly*) VARIANT_NAME="Nightly" ;;
	*hotfix*)  VARIANT_NAME="Hotfix" ;;
esac

BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-}"
CHANNEL_ID="${TELEGRAM_CHANNEL_ID:-}"
ERROR_CHANNEL_ID="${TELEGRAM_ERROR_CHANNEL_ID:-}"

if [ -z "$BOT_TOKEN" ]; then
	echo "TELEGRAM_BOT_TOKEN not set. Skipping."
	exit 0
fi

if [ "$STATUS" != "failed" ] && [ -z "$CHANNEL_ID" ]; then
	echo "TELEGRAM_CHANNEL_ID not set. Skipping."
	exit 0
fi

if [ "$STATUS" == "failed" ] && [ -z "$ERROR_CHANNEL_ID" ] && [ -z "$CHANNEL_ID" ]; then
	echo "Neither TELEGRAM_ERROR_CHANNEL_ID nor TELEGRAM_CHANNEL_ID set. Skipping."
	exit 0
fi

SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
COMMIT_MSG=$(git log -1 --pretty=%s 2>/dev/null || echo "unknown")
BUILD_NUM="${GITHUB_RUN_NUMBER:-0}"
BUILD_URL="${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}"
REPO_URL="https://github.com/${GITHUB_REPOSITORY}"
DATE=$(date +%d/%m/%y 2>/dev/null || echo "??/??/??")

# KSU info — from CI env or auto-extract from Kbuild
if [ -n "$KSU_VERSION" ] && [ -n "$KSU_TAG" ]; then
	KSU_VER_NUM="$KSU_VERSION"
	KSU_VER_TAG="$KSU_TAG"
else
	KSU_SCRIPT="$(dirname "$0")/get_ksu_info.sh"
	if [ -f "$KSU_SCRIPT" ]; then
		eval "$("$KSU_SCRIPT")"
		KSU_VER_NUM="${KSU_VERSION_NUM:-0}"
		KSU_VER_TAG="${KSU_TAG:-unknown}"
	else
		KSU_VER_NUM=0
		KSU_VER_TAG="unknown"
	fi
fi

function tg_send() {
	local target="$1" message="$2"
	local resp
	resp=$(curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
		-d chat_id="${target}" \
		-d text="${message}" \
		-d parse_mode="HTML" \
		-d disable_web_page_preview=true)
	if ! echo "$resp" | grep -q '"ok":true'; then
		echo "Telegram API error: $(echo "$resp" | grep -o '"description":"[^"]*"' | cut -d\" -f4)"
		return 1
	fi
	return 0
}

function tg_photo() {
	local target="$1" photo_url="$2" caption="$3"
	local resp
	resp=$(curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendPhoto" \
		-d chat_id="${target}" \
		-d photo="${photo_url}" \
		-d caption="${caption}" \
		-d parse_mode="HTML")
	if ! echo "$resp" | grep -q '"ok":true'; then
		echo "Telegram photo API error: $(echo "$resp" | grep -o '"description":"[^"]*"' | cut -d\" -f4)"
		return 1
	fi
	return 0
}

function build_start() {
	local msg="🎻 Phrolova · <code>${VERSION}</code>
━━━━━━━━━━━━━━━━━━━━
selene · Redmi 10 2022 · linux 4.14.356 · Non-GKI
ReSukiSU <code>${KSU_VER_TAG}</code> (KSU_VERSION <code>${KSU_VER_NUM}</code>) · Manual Hook

⏳ Building...
<code>${SHA}</code> ${COMMIT_MSG}
<a href='${BUILD_URL}'>Build Log</a>"
	tg_send "$CHANNEL_ID" "$msg" && echo "Start notification sent." || echo "Start notification FAILED."
}

function build_success() {
	local changelog_file="${1:-}"
	local changelog_items=""
	if [ -n "$changelog_file" ] && [ -f "$changelog_file" ]; then
		changelog_items=$(grep '^- ' "$changelog_file" 2>/dev/null | head -8)
	fi

	local BANNER_URL="https://raw.githubusercontent.com/${GITHUB_REPOSITORY:-naidrahiqa/phrolova_kernel_xiaomi_selene}/phrolova/docs/assets/banner_landscape.jpg"

	local msg="🎻 Phrolova · <code>${VERSION}</code>
━━━━━━━━━━━━━━━━━━━━
selene · Redmi 10 2022 · linux 4.14.356 · Non-GKI
ReSukiSU <code>${KSU_VER_TAG}</code> (KSU_VERSION <code>${KSU_VER_NUM}</code>) · Manual Hook
NoMount v20 (module v2.0.0)"

	if [ -n "$changelog_items" ]; then
		msg="${msg}

changelog
${changelog_items}
- fix screen going black under thermal load: backlight cooler had no floor, added 10%
- fix fast charge throttle: thermal HAL was clamping QC/HVDCP to 1.5A even at safe temps"
	fi

	msg="${msg}

works: boot, audio, touch, wifi/bt/data, charging, fingerprint, sensors, camera, root
untested: ir blaster, volte, video rec, nfc

dtbo does not matter, stock dtbo works.

⬇ Download Kernel

#selene #Redmi10 #mt6768 #kernel #ReSukiSU #NoMount"

	if tg_photo "$CHANNEL_ID" "$BANNER_URL" "$msg"; then
		echo "Success notification sent with banner."
	else
		echo "Photo failed, falling back to text..."
		tg_send "$CHANNEL_ID" "$msg" && echo "Success notification sent (text fallback)." || echo "Success notification FAILED."
	fi
}

function build_failed() {
	local error_log="${1:-build.log}"
	local error_context="No error context available."
	local error_type="UNKNOWN ERROR"
	local failed_step="Unknown step"

	if [ -f "$error_log" ]; then
		if grep -q "make\[" "$error_log" && grep -q "Error" "$error_log"; then
			error_type="MAKE ERROR"
		elif grep -q "fatal:" "$error_log"; then
			error_type="FATAL ERROR"
		elif grep -q "error:" "$error_log"; then
			error_type="COMPILE ERROR"
		fi

		if grep -q "CC\s" "$error_log" || grep -q "\.c:" "$error_log"; then
			failed_step="Build kernel (compile error)"
		elif grep -q "LD\s" "$error_log" || grep -q "ld.lld:" "$error_log"; then
			failed_step="Build kernel (link error)"
		else
			failed_step="Build kernel (make error)"
		fi

		error_context=$(grep -iE "(\.c:[0-9]+:|\.S:[0-9]+:|error:|fatal error:|clang: error:)" "$error_log" | grep -v "sub-make" | head -25)
		if [ -z "$error_context" ]; then
			error_context=$(tail -15 "$error_log")
		fi
	fi

	local simple_msg="🎻 Phrolova · <code>${VERSION}</code>
━━━━━━━━━━━━━━━━━━━━
❌ <b>${error_type}</b> · ${failed_step}
<a href='${BUILD_URL}'>Check Log</a>"
	tg_send "$CHANNEL_ID" "$simple_msg" && echo "Fail notification sent to channel." || echo "Fail notification to channel FAILED."

	if [ -n "$ERROR_CHANNEL_ID" ]; then
		local detail_msg="🎻 Phrolova Error Log
<code>${VERSION}</code> · <code>${SHA}</code>
<b>${error_type}</b> · ${failed_step}

<pre><code>${error_context}</code></pre>
<a href='${BUILD_URL}'>Full Log</a>"
		tg_send "$ERROR_CHANNEL_ID" "$detail_msg" && echo "Error log sent to error channel." || echo "Error log to error channel FAILED."
	fi
}

case "$STATUS" in
	start)
		build_start
		;;
	success)
		build_success "$4"
		;;
	failed)
		build_failed "$4"
		;;
	*)
		echo "Unknown status: $STATUS"
		echo "Usage: notify-telegram.sh <start|success|failed> <version> <tag> [file]"
		exit 1
		;;
esac
