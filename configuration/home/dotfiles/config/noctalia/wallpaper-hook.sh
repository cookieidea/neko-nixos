#!/usr/bin/env bash

# 视频壁纸抽一帧设为静态壁纸，供 noctalia 提取配色

if ! command -v noctalia >/dev/null 2>&1; then
    exit 1
fi

WP=$(noctalia msg wallpaper-get 2>/dev/null)

LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/noctalia"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/hook.log"

# 跳过派生壁纸，否则与 mpvpaper 形成重启闭环
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
