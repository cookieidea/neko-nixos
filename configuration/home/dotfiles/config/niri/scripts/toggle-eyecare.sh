#!/usr/bin/env bash
# NyxNiri EyeCare One-shot Self-Healing Toggle & Sync Script
# Zero background process besides wlsunset itself. Runs in < 2ms then exits.
#
# shellcheck disable=SC2317  # commands invoked via ||/&& intentional control flow
set -uo pipefail

# Ensure strict serialization to prevent any race conditions during rapid toggles or startup.
exec 9> "${XDG_RUNTIME_DIR:-/tmp}/nyxniri-eyecare.lock"
flock -w 5 9 || exit 1
#
# On/off state is derived from where effects.kdl points (eyecare target = ON)
# rather than tracked in a separate state file or inferred from the wlsunset
# process. effects.kdl survives niri restarts and is reset to Normal only by a
# config redeploy, so it is the persistent source of truth; wlsunset is the
# fragile runtime side (it can die or be missing on a fresh install) and is
# reconciled to the symlink state in --sync, so a dead wlsunset can never
# trap the toggle in EyeCare mode.

NIRI_DIR="$HOME/.config/niri"
EFFECTS_LINK="$NIRI_DIR/effects.kdl"
NORMAL_EFFECTS="$NIRI_DIR/effects_normal.kdl"
EYECARE_EFFECTS="$NIRI_DIR/effects_eyecare.kdl"

# Desired EyeCare warm color temperature (in Kelvin: 5500K for subtle natural warmth)
EYECARE_TEMP=5500

# Log for reload failures / self-healing events (empty on success)
LOG_FILE="${XDG_RUNTIME_DIR:-/tmp}/nyxniri-eyecare.log"

HAS_NOCTALIA=false
if command -v noctalia >/dev/null 2>&1; then
    HAS_NOCTALIA=true
fi

CURRENTLY_ON=false
if [ "$(readlink "$EFFECTS_LINK" 2>/dev/null)" = "$EYECARE_EFFECTS" ]; then
    CURRENTLY_ON=true
fi

# 切换 effects.kdl 后主动重载 niri，避免文件监听遗漏软链变化。
apply_effects() {
    local target
    if [ "$1" = "on" ]; then
        target="$EYECARE_EFFECTS"
    else
        target="$NORMAL_EFFECTS"
    fi

    ln -sfn "$target" "$EFFECTS_LINK"
    if [ "$(readlink "$EFFECTS_LINK" 2>/dev/null)" != "$target" ]; then
        echo "$(date '+%F %T') [eyecare] symlink swap failed (target=$target)" >> "$LOG_FILE"
    fi

    if command -v niri >/dev/null 2>&1; then
        if ! niri msg action load-config-file >>"$LOG_FILE" 2>&1; then
            sleep 0.2
            niri msg action load-config-file >>"$LOG_FILE" 2>&1 || true
        fi
    fi
}

# --sync 只做状态同步，不切换模式；用于 niri 启动时重新对齐 wlsunset。
# 同步时先清理旧的 wlsunset，再按持久化状态重新启动。
if [ "${1:-}" = "--sync" ]; then
    link_target="$(readlink "$EFFECTS_LINK" 2>/dev/null || true)"
    if [ "$link_target" != "$EYECARE_EFFECTS" ] && [ "$link_target" != "$NORMAL_EFFECTS" ]; then
        # effects.kdl missing/broken (manual deletion): recreate as Normal.
        ln -sfn "$NORMAL_EFFECTS" "$EFFECTS_LINK"
        CURRENTLY_ON=false
        echo "$(date '+%F %T') [eyecare] healed broken effects.kdl -> Normal" >> "$LOG_FILE"
        if command -v niri >/dev/null 2>&1; then
            niri msg action load-config-file >>"$LOG_FILE" 2>&1 || true
        fi
    fi
    # 等待 Wayland 和 Noctalia IPC 就绪。
    sleep 1
    if [ "$HAS_NOCTALIA" = "true" ]; then
        noctalia msg nightlight-disable 2>/dev/null || true
    fi
    pkill -x wlsunset 2>/dev/null || true
    if [ "$CURRENTLY_ON" = "true" ]; then
        if command -v wlsunset >/dev/null 2>&1; then
            nohup wlsunset -T 6500 -t "$EYECARE_TEMP" -d 0.3 -S 00:00 -s 00:00 >/dev/null 2>&1 9>&- &
        fi
    fi
    exit 0
fi

# 启动前先让 Noctalia 释放 gamma 控制。
if [ "$HAS_NOCTALIA" = "true" ]; then
    noctalia msg nightlight-disable 2>/dev/null || true
fi
pkill -x wlsunset 2>/dev/null || true

IS_TURNING_ON=false

if [ "$CURRENTLY_ON" = "true" ]; then
    # 关闭护眼模式。
    apply_effects off
else
    # 开启护眼模式。
    apply_effects on
    IS_TURNING_ON=true
fi

# 平滑调整色温，避免画面闪烁。
if [ "$IS_TURNING_ON" = "true" ]; then
    sleep 0.05
    nohup wlsunset -T 6500 -t "$EYECARE_TEMP" -d 0.3 -S 00:00 -s 00:00 >/dev/null 2>&1 9>&- &
fi

# 发送视觉提示。
if [ "$IS_TURNING_ON" = "true" ]; then
    notify-send -t 2000 "Eye Care : On"
else
    notify-send -t 2000 "Eye Care : OFF"
fi
