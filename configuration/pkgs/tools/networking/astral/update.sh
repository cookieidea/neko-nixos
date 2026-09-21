#!/usr/bin/env bash
# Astral 更新脚本：更新 Release 版本、hash，并验证构建。
# 用法：sudo bash configuration/pkgs/tools/networking/astral/update.sh [TAG]
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

# 1. 确定目标版本。
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

# 2. 确认 Linux 产物。
if ! curl -fsSLI "$URL" >/dev/null 2>&1; then
  echo "错误：上游没有 $TARBALL" >&2
  echo "      该 release 可能未发布 Linux 产物，请核对：$REPO_URL/releases/tag/$TAG" >&2
  exit 1
fi

# 3. 预取并计算 SRI hash。
echo "==> 下载并计算 hash（约 47MB）..."
PREFETCH_JSON="$(nix store prefetch-file --json --hash-type sha256 "$URL")"
NEW_HASH="$(printf '%s' "$PREFETCH_JSON" | python3 -c 'import json,sys; print(json.load(sys.stdin)["hash"])')"
[[ -n "$NEW_HASH" ]] || { echo "错误：无法计算 hash。" >&2; exit 1; }
echo "      $NEW_HASH"

# 4. 更新 default.nix。
OLD_VER="$(sed -n 's/^ *version = "\(.*\)";/\1/p' "$PKG_NIX" | head -1)"
OLD_HASH="$(sed -n 's/^ *hash = "\(.*\)";/\1/p' "$PKG_NIX" | head -1)"

if [[ "$OLD_VER" == "$VER" && "$OLD_HASH" == "$NEW_HASH" ]]; then
  echo "==> 已是 $TAG 且 hash 未变，无需改动。"
else
  echo "==> 更新 default.nix（$OLD_VER → $VER）"
  sed -i "s|^\( *version = \) \".*\";|\1\"$VER\";|" "$PKG_NIX"
  sed -i "s|^\( *hash = \) \".*\";|\1\"$NEW_HASH\";|" "$PKG_NIX"
fi

# 5. 验证构建。
echo "==> 校验构建 ..."
if ! nix build "$REPO_ROOT#astral" --no-link; then
  echo "错误：新版本构建失败，已回滚 default.nix。" >&2
  sed -i "s|^\( *version = \) \".*\";|\1\"$OLD_VER\";|" "$PKG_NIX"
  sed -i "s|^\( *hash = \) \".*\";|\1\"$OLD_HASH\";|" "$PKG_NIX"
  exit 1
fi
NEW_OUT="$(nix path-info "$REPO_ROOT#packages.x86_64-linux.astral")"
echo "      ✓ $NEW_OUT"

# 6. 部署。
echo "==> rebuild ..."
nixos-rebuild switch --flake "$REPO_ROOT"

# core 由 GUI 生命周期管理，本仓库不创建 systemd 服务。
# 升级后删除用户目录中的旧 core，让 GUI 重新部署新版。
LOCAL_CORE_DIR="$TARGET_HOME/.local/share/astral-core"
if [[ -d "$LOCAL_CORE_DIR" ]]; then
  echo "==> 清除 GUI 部署的旧 core 副本（将由 GUI 重新部署）..."
  pkill -x astral-core 2>/dev/null || true
  sleep 1
  pkill -9 -x astral-core 2>/dev/null || true
  rm -rf "$LOCAL_CORE_DIR"
  echo "      ✓ 已删除 $LOCAL_CORE_DIR"
fi

# 7. 推缓存并提交。
echo "==> 推缓存 ..."
sudo -H -u "$TARGET_USER" cachix push nekobox "$NEW_OUT" \
  || echo "cachix 推送失败，稍后手动补推：cachix push nekobox $NEW_OUT" >&2

echo "==> 提交 ..."
git -C "$REPO_ROOT" add -A
git -C "$REPO_ROOT" commit -m "chore(astral): 升级到 $TAG" || true
git -C "$REPO_ROOT" push || echo "推送失败，稍后手动推" >&2

echo "==> 完成。GUI 若还开着旧窗口，关掉重开一次（版本号是进程启动时读的）。"
