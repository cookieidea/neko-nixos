#!/usr/bin/env bash

# 获取当前主题模式，环境变量未提供时从 Noctalia 查询。
THEME_MODE="${NOCTALIA_THEME_MODE}"
if [ -z "$THEME_MODE" ]; then
    THEME_MODE=$(noctalia msg theme-mode-get 2>/dev/null || echo "dark")
fi

echo "Syncing theme mode to: $THEME_MODE"

set_gsettings() {
    local key="$1"
    local value="$2"

    if command -v gsettings >/dev/null 2>&1; then
        gsettings set org.gnome.desktop.interface "$key" "$value" 2>/dev/null || true
    fi
}

if [ "$THEME_MODE" = "light" ]; then
    set_gsettings color-scheme prefer-light
    set_gsettings gtk-theme adw-gtk3
else
    set_gsettings color-scheme prefer-dark
    set_gsettings gtk-theme adw-gtk3-dark
fi
