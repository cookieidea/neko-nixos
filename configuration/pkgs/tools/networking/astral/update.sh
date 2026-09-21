#!/usr/bin/env bash
# Astral 更新：查上游最新 Release → 改 version → 重算 hash → 验证构建 → 部署运行中的 core。
#
# 用法：sudo bash configuration/pkgs/tools/networking/astral/update.sh [TAG]
#   不给参数则自动取 Astral 最新稳定版。
#
# 架构说明：Astral 现由 fetchurl 直接取上游 GitHub Release 的
#   astral-<ver>-linux-x64.tar.gz（含 GUI + 官方 astral-core），
#   故本脚本只负责「改版本号 + 更新 hash」，不再本机编译 Flutter/Rust。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../../.." && pwd)"
PKG_NIX="$SCRIPT_DIR/default.nix"
REPO_URL="https://github.com/AstralNext/Astral"

TARGET_USER="${SUDO_USER:-cookie}"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
TARGET_UID="$(id -u "$TARGET_USER")"
export XDG_RUNTIME_DIR="/run/user/$TARGET_UID"
export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"

if [[ "$(id -u)" != "0" ]]; then
  echo "请用 sudo 运行：sudo bash $0 [TAG]" >&2
  exit 1
fi

# ---------- 1. 确定目标版本 ----------
TAG="${1:-}"
if [[ -z "$TAG" ]]; then
  echo "==> 查询 Astral 最新稳定版 ..."
  TAG="$(curl -fsSL "https://api.github.com/repos/AstralNext/Astral/releases/latest" \
    | grep -o '"tag_name": *"[^"]*"' | head -1 | cut -d'"' -f4)"
  [[ -n "$TAG" ]] || {
    echo "查不到最新版（GitHub API 可能限流），请手动传参：sudo bash $0 vX.Y.Z" >&2
    exit 1
  }
fi
VER="${TAG#v}"
TARBALL="astral-${VER}-linux-x64.tar.gz"
URL="$REPO_URL/releases/download/${TAG}/${TARBALL}"
echo "==> 目标版本：$TAG"

# ---------- 2. 确认该 release 里确有 Linux 产物 ----------
if ! curl -fsSLI "$URL" >/dev/null 2>&1; then
  echo "错误：上游没有 $TARBALL" >&2
  echo "      该 release 可能未发布 Linux 产物，请核对：$REPO_URL/releases/tag/$TAG" >&2
  exit 1
fi

# ---------- 3. 预取并计算 hash（SRI） ----------
echo "==> 下载并计算 hash（约 47MB）..."
PREFETCH_JSON="$(nix store prefetch-file --json --hash-type sha256 "$URL")"
NEW_HASH="$(printf '%s' "$PREFETCH_JSON" | python3 -c 'import json,sys; print(json.load(sys.stdin)["hash"])')"
[[ -n "$NEW_HASH" ]] || { echo "错误：无法计算 hash。" >&2; exit 1; }
echo "      $NEW_HASH"

# ---------- 4. 写入 default.nix ----------
OLD_VER="$(sed -n 's/^ *version = "\(.*\)";/\1/p' "$PKG_NIX" | head -1)"
OLD_HASH="$(sed -n 's/^ *hash = "\(.*\)";/\1/p' "$PKG_NIX" | head -1)"

if [[ "$OLD_VER" == "$VER" && "$OLD_HASH" == "$NEW_HASH" ]]; then
  echo "==> 已是 $TAG 且 hash 未变，无需改动。"
else
  echo "==> 更新 default.nix（$OLD_VER → $VER）"
  sed -i "s|^\( *version = \) \".*\";|\1\"$VER\";|" "$PKG_NIX"
  sed -i "s|^\( *hash = \) \".*\";|\1\"$NEW_HASH\";|" "$PKG_NIX"
fi

# ---------- 5. 验证新版本能构建 ----------
echo "==> 校验构建 ..."
if ! nix build "$REPO_ROOT#astral" --no-link; then
  echo "错误：新版本构建失败，已回滚 default.nix。" >&2
  sed -i "s|^\( *version = \) \".*\";|\1\"$OLD_VER\";|" "$PKG_NIX"
  sed -i "s|^\( *hash = \) \".*\";|\1\"$OLD_HASH\";|" "$PKG_NIX"
  exit 1
fi
NEW_OUT="$(nix path-info "$REPO_ROOT#packages.x86_64-linux.astral")"
echo "      ✓ $NEW_OUT"

# ---------- 6. 部署 ----------
echo "==> rebuild ..."
nixos-rebuild switch --flake "$REPO_ROOT"

# 运行中的 core 来自 GUI 首次启动时自动部署的副本（~/.local/share/astral-core），
# 需同步更新并重设 cap_net_admin（TUN 依赖），否则仍跑旧 core。
NEW_CORE="$NEW_OUT/app/astral-core"
echo "==> 同步运行中的 core ..."
pkill -x astral-core 2>/dev/null || true
sleep 2
pkill -9 -x astral-core 2>/dev/null || true
sleep 1

sudo -H -u "$TARGET_USER" "$NEW_CORE" service install --user \
  --listen 127.0.0.1:50051 --program "$NEW_CORE"
setcap cap_net_admin=ep "$TARGET_HOME/.local/share/astral-core/app/astral-core"
getcap "$TARGET_HOME/.local/share/astral-core/app/astral-core"
sudo -H -u "$TARGET_USER" env XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" \
  DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" \
  systemctl --user restart astral-core
sudo -H -u "$TARGET_USER" env XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" \
  DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" \
  systemctl --user is-active astral-core

# ---------- 7. 推缓存 + 提交 ----------
echo "==> 推缓存 ..."
sudo -H -u "$TARGET_USER" cachix push nekobox "$NEW_OUT" \
  || echo "cachix 推送失败，稍后手动补推：cachix push nekobox $NEW_OUT" >&2

echo "==> 提交 ..."
git -C "$REPO_ROOT" add -A
git -C "$REPO_ROOT" commit -m "chore(astral): 升级到 $TAG" || true
git -C "$REPO_ROOT" push || echo "推送失败，稍后手动推" >&2

echo "==> 完成。GUI 若还开着旧窗口，关掉重开一次（版本号是进程启动时读的）。"
