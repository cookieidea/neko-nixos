#!/usr/bin/env bash

# wallpaper_changed 钩子：视频壁纸被设为静态壁纸时，用当前帧生成缩略图并提取配色。
#
# 防重入（重要）：mpvpaper 插件在每次壁纸变更时都会重启 mpvpaper，而
# mpvpaper 启动又会经 mpv-hook.lua 调用 wallpaper-set → 再次触发本钩子 →
# 又重启 mpvpaper，形成每 6 秒一轮的闭环。实测该闭环曾持续 22 天、
# 单个缩略图被处理 7835 次，mpvpaper 每次仅存活 6 秒，
# 并伴随大量内存分配失败。
# 因此：只要当前壁纸来自本钩子或 mpvpaper 自身产出的目录，就直接返回。

if ! command -v noctalia >/dev/null 2>&1; then
    exit 1
fi

WP=$(noctalia msg wallpaper-get 2>/dev/null)

LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/noctalia"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/hook.log"

# 本钩子的产出目录与 mpvpaper 的缩略图缓存目录 —— 二者都是派生壁纸，
# 不是用户主动选择，不应触发后续处理（否则闭环）。
THUMB_DIR="${XDG_RUNTIME_DIR:-/tmp/noctalia-$USER}"
DERIVED_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/noctalia/mpvpaper"

if [[ "$WP" == "$THUMB_DIR/"* || "$WP" == "$DERIVED_DIR/"* ]]; then
    exit 0
fi

echo "$(date) wallpaper_changed hook triggered. WP=$WP" >> "$LOG_FILE"

# 仅处理视频文件。
if [[ -n "$WP" && -f "$WP" && "$WP" =~ \.(mp4|webm|mkv|mov|gif)$ ]]; then
    if ! command -v ffmpeg >/dev/null 2>&1; then
        echo "Error: ffmpeg is not installed." >> "$LOG_FILE"
        exit 1
    fi

    echo "Video detected, generating thumbnail and setting it as wallpaper..." >> "$LOG_FILE"

    mkdir -p "$THUMB_DIR"
    THUMB_PATH="$THUMB_DIR/mpvpaper_thumb.jpg"

    if ffmpeg -y -i "$WP" -ss 00:00:01 -vframes 1 "$THUMB_PATH" 2>/dev/null; then
        noctalia msg wallpaper-set "$THUMB_PATH" 2>/dev/null
    else
        echo "Error: ffmpeg failed to extract thumbnail from $WP" >> "$LOG_FILE"
    fi
fi
