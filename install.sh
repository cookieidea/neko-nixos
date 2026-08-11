#!/usr/bin/env bash
#
# neko-nixos —— 一键安装脚本
# 把本仓库的 NixOS + Home Manager 配置（niri + Noctalia 桌面 rice）部署到目标机器并切换。
#
# 用法：
#   1) 在一台已装好 NixOS 26.05、且已启用 flakes 的机器上，以 root 运行：
#        sudo -E bash -c "$(curl -fsSL https://raw.githubusercontent.com/cookieidea/neko-nixos/main/install.sh)"
#   2) 或者先 clone 再本地运行：
#        git clone https://github.com/cookieidea/neko-nixos && cd neko-nixos
#        sudo ./install.sh [用户名]
#
# 说明：
#   - 配置里硬编码的用户名是 "cookie"，脚本会把它替换成你要部署的用户（默认 cookie）。
#   - 替换范围：flake.nix 的 username 变量，以及 dotfiles/ 下所有文本文件里的 /home/cookie 路径。
#   - 二进制文件会被自动跳过（本仓库目前没有二进制资源，全部是文本）。
#   - 部署目录固定为 /etc/nixos，完成后执行 nixos-rebuild switch --flake /etc/nixos/#nixos
#
set -euo pipefail

REPO="cookieidea/neko-nixos"
BRANCH="${BRANCH:-main}"
FLAKE_ATTR="${FLAKE_ATTR:-nixos}"
NIXOS_CONF="/etc/nixos"

# ---------- 0. 需要 root ----------
if [[ $EUID -ne 0 ]]; then
  echo "错误：请使用 root 运行（例如 sudo -E bash install.sh，或 sudo -E 之后执行）。" >&2
  exit 1
fi

# ---------- 1. 询问目标用户名 ----------
TARGET_USER="${1:-}"
if [[ -z "$TARGET_USER" ]]; then
  read -r -p "请输入要部署配置的用户名 [cookie]: " TARGET_USER
  TARGET_USER="${TARGET_USER:-cookie}"
fi
if [[ -z "$TARGET_USER" || "$TARGET_USER" == "root" ]]; then
  echo "错误：用户名不能为空或 root。" >&2
  exit 1
fi

# ---------- 2. 检查 nix / flakes ----------
if ! command -v nixos-rebuild >/dev/null 2>&1; then
  echo "错误：未检测到 nixos-rebuild，请在 NixOS 系统上运行本脚本。" >&2
  exit 1
fi
if ! grep -Rq "experimental-features" /etc/nix/nix.conf 2>/dev/null && \
   ! nix --version 2>/dev/null | grep -q .; then
  echo "错误：未检测到 nix 命令。" >&2
  exit 1
fi
# 简单提示：flake 需要 experimental-features 含 flakes
if ! grep -q "flakes" /etc/nix/nix.conf 2>/dev/null; then
  echo "提示：/etc/nix/nix.conf 未检测到 'flakes'。若重建报错，请先加入："
  echo "      experimental-features = nix-command flakes"
fi

# ---------- 3. 准备仓库副本 ----------
echo "==> 获取仓库代码 ..."
WORK_DIR="$(mktemp -d)"
cleanup() { rm -rf "$WORK_DIR"; }
trap cleanup EXIT

if [[ -d .git && -f flake.nix ]]; then
  # 本地已 clone，直接复用
  SRC_DIR="$PWD"
else
  git clone --depth 1 --branch "$BRANCH" "https://github.com/$REPO" "$WORK_DIR/repo"
  SRC_DIR="$WORK_DIR/repo"
fi
cd "$SRC_DIR"

# ---------- 4. 替换硬编码用户名 cookie -> TARGET_USER ----------
if [[ "$TARGET_USER" != "cookie" ]]; then
  echo "==> 将配置中的用户名 cookie 替换为 $TARGET_USER ..."
  # 仅处理文本文件，跳过二进制（grep -I 对二进制文件不命中）
  while IFS= read -r -d '' f; do
    if grep -Iq "cookie" "$f" 2>/dev/null; then
      sed -i "s/cookie/$TARGET_USER/g" "$f"
    fi
  done < <(find . -type f -not -path './.git/*' -print0)
else
  echo "==> 目标用户名即 cookie，跳过替换。"
fi

# ---------- 5. 部署到 /etc/nixos ----------
echo "==> 部署到 $NIXOS_CONF ..."
rm -rf "$NIXOS_CONF"
mkdir -p "$NIXOS_CONF"
# 复制全部内容（含 dotfiles/、home.nix、configuration.nix、flake.nix、gen_dotfiles.py）
cp -r "$SRC_DIR/." "$NIXOS_CONF/"

# ---------- 6. 切换系统 ----------
echo "==> 执行 nixos-rebuild switch --flake $NIXOS_CONF/#$FLAKE_ATTR ..."
nixos-rebuild switch --flake "$NIXOS_CONF/#$FLAKE_ATTR"

echo ""
echo "==> 完成！配置已切换到 $TARGET_USER @ $FLAKE_ATTR。"
echo "    重启或重新登录以进入 niri + Noctalia 桌面。"
echo "    若 Home Manager 部分未生效，可再以该用户运行：home-manager switch --flake $NIXOS_CONF/#$FLAKE_ATTR"
