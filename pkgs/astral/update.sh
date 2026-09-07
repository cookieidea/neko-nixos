#!/usr/bin/env bash
# Astral 一键更新：查 release → 改 REF → 构建 → 重锁 → rebuild → 换 core → 推缓存 → 提交。
# 用法：sudo bash pkgs/astral/update.sh [GUI_TAG [CORE_TAG]]
#   不给参数则自动取 Astral 最新稳定版，core 版本从 release 正文解析。
set -euo pipefail

SCRIPT_DIR="$(dirname "$0")"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TARGET_USER="${SUDO_USER:-cookie}"
TARGET_HOME="/home/$TARGET_USER"
TARGET_UID="$(id -u "$TARGET_USER")"
export XDG_RUNTIME_DIR="/run/user/$TARGET_UID"
export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"

if [[ "$(id -u)" != "0" ]]; then
  echo "请用 sudo 运行：sudo bash $0 [GUI_TAG [CORE_TAG]]" >&2
  exit 1
fi

GUI_REF="${1:-}"
CORE_REF="${2:-}"

if [[ -z "$GUI_REF" ]]; then
  echo "==> 查询 Astral 最新稳定版 ..."
  GUI_REF="$(curl -fsSL "https://api.github.com/repos/AstralNext/Astral/releases/latest" | grep -o '"tag_name": *"[^"]*"' | head -1 | cut -d'"' -f4)"
  [[ -n "$GUI_REF" ]] || { echo "查不到最新版（GitHub API 可能限流），请手动传参：sudo bash $0 vX.Y.Z [CORE_TAG]" >&2; exit 1; }
fi
echo "==> GUI 版本：$GUI_REF"

if [[ -z "$CORE_REF" ]]; then
  echo "==> 从 release 正文解析 core 版本 ..."
  BODY="$(curl -fsSL "https://api.github.com/repos/AstralNext/Astral/releases/tags/$GUI_REF")"
  CORE_VER="$(printf '%s' "$BODY" | grep -o "astral-core v[0-9][0-9.]*" | head -1 | grep -o "v[0-9][0-9.]*")"
  [[ -n "$CORE_VER" ]] || { echo "解析不到 core 版本，请手动传参：sudo bash $0 $GUI_REF vA.B.C" >&2; exit 1; }
  CORE_REF="$CORE_VER"
fi
echo "==> Core 版本：$CORE_REF"

GUI_VER="${GUI_REF#v}"
sed -i "s/^REF=.*/REF=$GUI_REF/; s/^CORE_REF=.*/CORE_REF=$CORE_REF/" "$REPO_ROOT/pkgs/astral/build.sh"
sed -i "s/^  version = \".*\";/  version = \"$GUI_VER\";/" "$REPO_ROOT/pkgs/astral/default.nix"

echo "==> 联网构建（约 20 分钟）..."
bash "$REPO_ROOT/pkgs/astral/build.sh"

echo "==> rebuild ..."
nixos-rebuild switch --flake "$REPO_ROOT"

echo "==> 替换运行中的 core ..."
pkill -x astral-core || true
sleep 2
pkill -9 -x astral-core 2>/dev/null || true
sleep 1

NEW_OUT="$(nix path-info "$REPO_ROOT#packages.x86_64-linux.astral")"
NEW_CORE="$NEW_OUT/app/astral-core"
sudo -H -u "$TARGET_USER" "$NEW_CORE" service install --user \
  --listen 127.0.0.1:50051 --program "$NEW_CORE"
setcap cap_net_admin=ep "$TARGET_HOME/.local/share/astral-core/app/astral-core"
getcap "$TARGET_HOME/.local/share/astral-core/app/astral-core"
sudo -H -u "$TARGET_USER" env XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" \
  systemctl --user restart astral-core
sudo -H -u "$TARGET_USER" env XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" \
  systemctl --user is-active astral-core

echo "==> 推缓存 ..."
sudo -H -u "$TARGET_USER" cachix push nekobox "$NEW_OUT" || echo "cachix 推送失败，稍后手动补推：cachix push nekobox $NEW_OUT" >&2

echo "==> 提交 ..."
git -C "$REPO_ROOT" add -A
git -C "$REPO_ROOT" commit -m "feat: astral $GUI_VER（core $CORE_REF）" || true
git -C "$REPO_ROOT" push || echo "推送失败，稍后手动推" >&2

echo "==> 完成。GUI 若还开着旧窗口，关掉重开一次（版本号是进程启动时读的）。"
echo "    core 每次更新都要重设 cap，本脚本已处理；手动更新时别忘跑："
echo "    sudo setcap cap_net_admin=ep ~/.local/share/astral-core/app/astral-core"
