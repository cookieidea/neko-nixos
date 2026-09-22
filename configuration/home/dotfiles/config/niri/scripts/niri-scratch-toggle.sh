#!/usr/bin/env bash
# NyxNiri scratchpad 窗口切换。

set -uo pipefail

TARGET_APP="${1:-kitty}"

LOCK_NAME=$(printf '%s' "$TARGET_APP" | tr -c 'a-zA-Z0-9_' '_')
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/nyxniri-scratch-${LOCK_NAME}.lock"
flock -n 9 || exit 0

active_workspace() {
    niri msg -j workspaces 2>/dev/null |
        jq -r '(.[] | select(.is_focused == true) | .id) // (.[] | select(.is_active == true) | .id)' |
        head -n1
}

find_window() {
    local app_id="$1"
    niri msg -j windows 2>/dev/null |
        jq -r --arg id "$app_id"             '.[] | select(.app_id == $id) | "\(.id) \(.workspace_id)"' |
        head -n1
}

window_on_other_workspace() {
    local active_ws="$1"
    local window_ws="$2"
    [ -n "$active_ws" ] && [ -n "$window_ws" ] && [ "$window_ws" != "$active_ws" ]
}

close_window() {
    niri msg action close-window --id "$1"
}

spawn_kitty() {
    local app_id="$1"
    local title="$2"

    if command -v tmux >/dev/null 2>&1; then
        niri msg action spawn --             kitty --app-id "$app_id" --title "$title"             tmux new-session -A -D -s scratch             "fish -C 'function fish_greeting; end' -C 'set -g fish_history scratchpad'"             \; set-option status off
    else
        niri msg action spawn -- kitty --app-id "$app_id" --title "$title"
    fi
}

spawn_missioncenter() {
    if command -v missioncenter >/dev/null 2>&1; then
        niri msg action spawn -- missioncenter
    elif command -v flatpak >/dev/null 2>&1 &&
        flatpak info io.missioncenter.MissionCenter >/dev/null 2>&1; then
        niri msg action spawn -- flatpak run io.missioncenter.MissionCenter
    fi
}

case "$TARGET_APP" in
    kitty|terminal|Kitty|Terminal)
        APP_ID="scratchpad"
        ACTIVE_WS="$(active_workspace)"
        read -r WIN_ID WIN_WS < <(find_window "$APP_ID")

        if [ -z "${WIN_ID:-}" ]; then
            spawn_kitty "$APP_ID" "Scratchpad"
        elif window_on_other_workspace "$ACTIVE_WS" "${WIN_WS:-}"; then
            close_window "$WIN_ID"
            sleep 0.05
            spawn_kitty "$APP_ID" "Scratchpad"
        else
            close_window "$WIN_ID"
        fi
        ;;

    missioncenter|monitor|"mission center"|"Mission Center"|MissionCenter)
        APP_ID="io.missioncenter.MissionCenter"
        ACTIVE_WS="$(active_workspace)"
        read -r WIN_ID WIN_WS < <(find_window "$APP_ID")

        if [ -z "${WIN_ID:-}" ]; then
            spawn_missioncenter
        elif window_on_other_workspace "$ACTIVE_WS" "${WIN_WS:-}"; then
            niri msg action focus-window --id "$WIN_ID"
        else
            close_window "$WIN_ID"
        fi
        ;;

    nautilus|files|Nautilus|Files)
        APP_ID="org.gnome.Nautilus"
        ACTIVE_WS="$(active_workspace)"
        read -r WIN_ID WIN_WS < <(find_window "$APP_ID")

        if [ -z "${WIN_ID:-}" ]; then
            niri msg action spawn -- nautilus --new-window
        elif window_on_other_workspace "$ACTIVE_WS" "${WIN_WS:-}"; then
            niri msg action focus-window --id "$WIN_ID"
        else
            close_window "$WIN_ID"
        fi
        ;;

    *)
        if [[ "$TARGET_APP" =~ ^~.* ]]; then
            TARGET_APP="${TARGET_APP/#\~/$HOME}"
        fi

        if [ "$TARGET_APP" = "clean" ] &&
            [ -x "$HOME/.local/bin/clean" ]; then
            TARGET_APP="$HOME/.local/bin/clean"
        fi

        if [ "$TARGET_APP" = "$HOME/.local/bin/clean" ] ||
            [[ "$TARGET_APP" == *bin/clean* ]]; then
            niri msg action spawn -- kitty --app-id scratchpad -e bash "$TARGET_APP"
        elif [ -x "$TARGET_APP" ] || command -v "$TARGET_APP" >/dev/null 2>&1; then
            niri msg action spawn -- "$TARGET_APP"
        else
            niri msg action spawn -- bash -c "$TARGET_APP"
        fi
        ;;
esac
