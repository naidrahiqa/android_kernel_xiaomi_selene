#!/bin/bash
# Telegram Notification - Phrolova Kernel
# Usage: bash notify-telegram.sh <status> <version> <tag> [arg4] [arg5] [arg6]
# Status: start | success | failed | tested
#   start   - build dimulai
#   success - build SUKSES: notif singkat TANPA link download, tanpa changelog
#   failed  - build gagal (ringkasan + log)
#   tested  - build sudah DITES & BOOTING AMAN: notif lengkap + tombol download
#             arg4 = catatan testing, arg5 = download URL, arg6 = nama zip (opsional)
#
# Target Channels / Topics:
#   Left (Supergroup Naidrahiqa Stuff):
#     TELEGRAM_GROUP_ID       - Chat ID supergroup (-1004414006944)
#     TELEGRAM_TOPIC_CI       - Thread ID topic ⁉️ Selene CI (47) [NOTIF ONLY, NO ZIP]
#     TELEGRAM_TOPIC_LOG      - Thread ID topic 🔍 log (8) [Build error log]
#
#   Right (Private Channels):
#     TELEGRAM_CHANNEL_ID     - Chat ID channel Nai project update (-1003752197403) [KIRIM FILE .ZIP KERNEL]
#     TELEGRAM_ERROR_CHANNEL_ID - Chat ID channel Nai Error Dump (-1003945405514) [Full error dump]

STATUS="${1:-unknown}"
VERSION="${2:-unknown}"
TAG="${3:-$VERSION}"

BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-}"
GROUP_ID="${TELEGRAM_GROUP_ID:-}"
TOPIC_CI="${TELEGRAM_TOPIC_CI:-47}"
TOPIC_LOG="${TELEGRAM_TOPIC_LOG:-8}"
CHANNEL_ID="${TELEGRAM_CHANNEL_ID:-}"
ERROR_CHANNEL_ID="${TELEGRAM_ERROR_CHANNEL_ID:-}"

if [ -z "$BOT_TOKEN" ]; then
	echo "TELEGRAM_BOT_TOKEN not set. Skipping."
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
		eval "$(bash "$KSU_SCRIPT")"
		KSU_VER_NUM="${KSU_VERSION_NUM:-0}"
		KSU_VER_TAG="${KSU_TAG:-unknown}"
	else
		KSU_VER_NUM=0
		KSU_VER_TAG="unknown"
	fi
fi

function tg_send() {
	local target="$1" message="$2" thread_id="${3:-}" buttons="${4:-}"
	local extra_args=()
	if [ -n "$thread_id" ]; then
		extra_args+=(-d "message_thread_id=${thread_id}")
	fi
	if [ -n "$buttons" ]; then
		extra_args+=(-d "reply_markup=${buttons}")
	fi
	local resp
	resp=$(curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
		-d chat_id="${target}" \
		"${extra_args[@]}" \
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
	local target="$1" photo_url="$2" caption="$3" thread_id="${4:-}" buttons="${5:-}"
	local extra_args=()
	if [ -n "$thread_id" ]; then
		extra_args+=(-d "message_thread_id=${thread_id}")
	fi
	if [ -n "$buttons" ]; then
		extra_args+=(-d "reply_markup=${buttons}")
	fi
	local resp
	resp=$(curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendPhoto" \
		-d chat_id="${target}" \
		-d photo="${photo_url}" \
		-d caption="${caption}" \
		-d parse_mode="HTML" \
		"${extra_args[@]}")
	if ! echo "$resp" | grep -q '"ok":true'; then
		echo "Telegram photo API error: $(echo "$resp" | grep -o '"description":"[^"]*"' | cut -d\" -f4)"
		return 1
	fi
	return 0
}

function tg_document() {
	local target="$1" doc_path="$2" caption="$3" thread_id="${4:-}"
	local extra_args=()
	if [ -n "$thread_id" ]; then
		extra_args+=(-F "message_thread_id=${thread_id}")
	fi
	local resp
	resp=$(curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendDocument" \
		-F chat_id="${target}" \
		-F document=@"${doc_path}" \
		-F caption="${caption}" \
		-F parse_mode="HTML" \
		"${extra_args[@]}")
	if ! echo "$resp" | grep -q '"ok":true'; then
		echo "Telegram document API error: $(echo "$resp" | grep -o '"description":"[^"]*"' | cut -d\" -f4)"
		return 1
	fi
	return 0
}

function build_start() {
	local msg="🎻 <b>Phrolova</b> · <code>${VERSION}</code>
━━━━━━━━━━━━━━━━━━━━
🔨 <b>Building...</b>
<code>${SHA}</code> ${COMMIT_MSG}
<a href='${BUILD_URL}'>Build Log</a>"

	# Kirim ke Gambar Kiri (Supergroup topic ⁉️ Selene CI)
	local target_group="${GROUP_ID:-$CHANNEL_ID}"
	if [ -n "$target_group" ]; then
		tg_send "$target_group" "$msg" "$TOPIC_CI" && echo "Start notification sent to CI topic." || echo "Start notification to CI topic FAILED."
	fi
}

function build_success() {
	local changelog_file="${1:-}"
	local zip_file="${2:-}"

	if [ -z "$zip_file" ] || [ ! -f "$zip_file" ]; then
		zip_file=$(ls Phrolova-selene-*.zip selene-*.zip 2>/dev/null | head -1)
	fi

	local changelog_items=""
	if [ -n "$changelog_file" ] && [ -f "$changelog_file" ]; then
		changelog_items=$(grep '^- ' "$changelog_file" 2>/dev/null | head -20)
	fi
	if [ -z "$changelog_items" ] && [ -f "CHANGELOG.md" ]; then
		changelog_items=$(awk '/^## v[0-9]/{if(found)exit; found=1; next} found && /^- /{print}' CHANGELOG.md 2>/dev/null | head -20)
	fi

	local BANNER_URL="https://raw.githubusercontent.com/${GITHUB_REPOSITORY:-naidrahiqa/android_kernel_xiaomi_selene}/phrolova/docs/assets/banner_landscape.jpg"

	# 1. KIRIM NOTIFIKASI KE GAMBAR KIRI (Supergroup Naidrahiqa Stuff -> Topic ⁉️ Selene CI)
	# HANYA "build berhasil" — TANPA link download, tanpa changelog, tanpa tombol.
	# Pengumuman download dikirim terpisah lewat status `tested` SETELAH device tes booting.
	local notif_msg="🎻 <b>Phrolova</b> · <code>${VERSION}</code>
━━━━━━━━━━━━━━━━━━━━
✅ <b>Build succeeded</b>
📦 <code>$(basename "$zip_file")</code>
<code>${SHA}</code> ${COMMIT_MSG}
<a href='${BUILD_URL}'>Build Log</a>

<i>Belum diuji — pengumuman download menyusul setelah tes booting aman.</i>"

	local target_group="${GROUP_ID:-$CHANNEL_ID}"
	if [ -n "$target_group" ]; then
		if tg_photo "$target_group" "$BANNER_URL" "$notif_msg" "$TOPIC_CI"; then
			echo "Success notification sent with banner to CI topic."
		else
			echo "Photo failed, falling back to text..."
			tg_send "$target_group" "$notif_msg" "$TOPIC_CI" && echo "Success notification sent (text fallback) to CI topic." || echo "Success notification to CI topic FAILED."
		fi
	fi

	# 2. KIRIM FILE KERNEL .ZIP KE GAMBAR KANAN (Private Channel 'Nai project update')
	if [ -n "$CHANNEL_ID" ] && [ -n "$zip_file" ] && [ -f "$zip_file" ]; then
		local file_size=$(du -h "$zip_file" | cut -f1)
		local doc_caption="🎻 <b>Phrolova Kernel</b> · <code>${VERSION}</code>
━━━━━━━━━━━━━━━━━━━━
<b>Device:</b> Redmi 10 (selene) · MT6768 · Non-GKI
<b>Root:</b> ReSukiSU <code>${KSU_VER_TAG}</code>
<b>Redirection:</b> NoMount v2.0.0
<b>Size:</b> ${file_size}
<b>Commit:</b> <code>${SHA}</code> ${COMMIT_MSG}

Changelog:
${changelog_items}

⚠️ <i>Flash via AnyKernel3 recovery (TWRP/OrangeFox).</i>"

		tg_document "$CHANNEL_ID" "$zip_file" "$doc_caption" && echo "Kernel zip document sent to release channel." || echo "Failed to send kernel zip to release channel."
	fi
}

function build_tested() {
	local notes="${1:-booting aman}"
	local download_url="${2:-${REPO_URL}/releases/tag/${TAG}}"
	local zip_name="${3:-${TAG}.zip}"

	local changelog_items=""
	if [ -f "CHANGELOG.md" ]; then
		changelog_items=$(awk '/^## v[0-9]/{if(found)exit; found=1; next} found && /^- /{print}' CHANGELOG.md 2>/dev/null | head -20)
	fi

	local BANNER_URL="https://raw.githubusercontent.com/${GITHUB_REPOSITORY:-naidrahiqa/android_kernel_xiaomi_selene}/phrolova/docs/assets/banner_landscape.jpg"

	local notif_msg="🎻 <b>Phrolova</b> · <code>${VERSION}</code>
━━━━━━━━━━━━━━━━━━━━
✅ <b>Tested — booting aman</b>
<b>Redmi 10</b> · selene · MT6768 · Non-GKI
📦 <b>File:</b> <code>${zip_name}</code>
⚠️ ReSukiSU <code>${KSU_VER_TAG}</code> · NoMount v2.0.0
🧪 <b>Catatan:</b> ${notes}

Changelog:
${changelog_items:-<i>No changes recorded</i>}"

	local BUTTONS='{"inline_keyboard":[[{"text":"⬇️ Download","url":"'"${download_url}"'"}],[{"text":"📱 ReSukiSU APK","url":"https://github.com/ReSukiSU/ReSukiSU/releases/tag/'"${KSU_VER_TAG}"'"}],[{"text":"📦 NoMount","url":"https://github.com/maxsteeel/nomount/releases"}]]}'

	local target_group="${GROUP_ID:-$CHANNEL_ID}"
	if [ -n "$target_group" ]; then
		if tg_photo "$target_group" "$BANNER_URL" "$notif_msg" "$TOPIC_CI" "$BUTTONS"; then
			echo "Tested notification sent with banner to CI topic."
		else
			tg_send "$target_group" "$notif_msg" "$TOPIC_CI" "$BUTTONS" && echo "Tested notification sent to CI topic." || echo "Tested notification to CI topic FAILED."
		fi
	fi
}

function build_failed() {
	local error_log="${1:-build.log}"
	local error_context="No error context available."
	local error_type="UNKNOWN ERROR"
	local failed_step="Unknown step"

	if [ "${MAKE_EXIT_CODE:-1}" -eq 0 ]; then
		# make succeeded — a later pipeline step (verify/package/release) failed
		error_type="CI STEP ERROR"
		failed_step="Post-build step (verify/package/release)"
		if [ -f "$error_log" ]; then
			error_context=$(tail -12 "$error_log")
		fi
	elif [ -f "$error_log" ]; then
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

		error_context=$(grep -iE "(\.c:[0-9]+:|\.S:[0-9]+:|error:|fatal error:|clang: error:)" "$error_log" | grep -v "sub-make" | head -20)
		if [ -z "$error_context" ]; then
			error_context=$(tail -12 "$error_log")
		fi
	fi

	local simple_msg="🎻 <b>Phrolova</b> · <code>${VERSION}</code>
━━━━━━━━━━━━━━━━━━━━
❌ <b>${error_type}</b>
<a href='${BUILD_URL}'>Check Log</a>"

	local target_group="${GROUP_ID:-$CHANNEL_ID}"
	if [ -n "$target_group" ]; then
		# Kirim ringkasan error ke topic ⁉️ Selene CI
		tg_send "$target_group" "$simple_msg" "$TOPIC_CI" && echo "Fail notification sent to CI topic." || echo "Fail notification to CI topic FAILED."

		# Kirim cuplikan log ke topic 🔍 log di supergroup
		if [ -n "$TOPIC_LOG" ]; then
			local log_lines=$(wc -l < "$error_log" 2>/dev/null || echo "0")
			local log_tail=$(tail -c 3000 "$error_log" 2>/dev/null)
			local topic_log_msg="📋 <b>Build Log (${log_lines} lines)</b>
<b>Tag:</b> <code>${TAG}</code>
<b>Step:</b> ${failed_step}

<pre><code>${log_tail}</code></pre>"
			tg_send "$target_group" "$topic_log_msg" "$TOPIC_LOG" && echo "Log sent to log topic." || echo "Log to log topic FAILED."
		fi
	fi

	# Kirim ke Gambar Kanan (Private Channel 'Nai Error Dump')
	if [ -n "$ERROR_CHANNEL_ID" ]; then
		local detail_msg="🎻 <b>Phrolova</b> · <code>${VERSION}</code>
<b>${error_type}</b> · ${failed_step}

<pre><code>${error_context}</code></pre>
<a href='${BUILD_URL}'>Full Log</a>"
		tg_send "$ERROR_CHANNEL_ID" "$detail_msg" && echo "Error log sent to Nai Error Dump." || echo "Error log to Nai Error Dump FAILED."
	fi
}

case "$STATUS" in
	start)
		build_start
		;;
	success)
		build_success "$4" "$5"
		;;
	failed)
		build_failed "$4"
		;;
	tested)
		build_tested "$4" "$5" "$6"
		;;
	*)
		echo "Unknown status: $STATUS"
		echo "Usage: notify-telegram.sh <start|success|failed|tested> <version> <tag> [arg4] [arg5] [arg6]"
		exit 1
		;;
esac
