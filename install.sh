#!/usr/bin/env bash
#
# neko-nixos 一键安装脚本
#
# 两种模式：
#   1) 全新安装（minimal / 无图形界面 ISO）：
#        sudo bash install.sh <用户名> <挂载点>
#        例：sudo bash install.sh cookie /mnt
#      —— 会部署配置并跑 nixos-install --flake <挂载点>/etc/nixos/#nixos
#      —— 前置：先把磁盘分区格式化并挂载到 <挂载点>，再 nixos-generate-config --root <挂载点>
#   2) 已装系统应用 / 更新：
#        sudo bash install.sh [用户名]
#      —— 会部署到 /etc/nixos 并跑 nixos-rebuild switch --flake /etc/nixos/#nixos
#
# 说明：
#   - 配置里硬编码用户名 "cookie"，脚本会替换成你的用户名（默认 cookie）。
#   - 替换范围：flake.nix 的 username 变量 + dotfiles 下所有文本文件里的 /home/cookie 路径。
#   - 二进制文件自动跳过（本仓库目前无二进制资源）。
#
set -euo pipefail

REPO="cookieidea/neko-nixos"
BRANCH="${BRANCH:-main}"
FLAKE_HOST="${FLAKE_HOST:-nixos}"
OLD_USER="cookie"

if [[ $EUID -ne 0 ]]; then
  echo "错误：请使用 root 运行（例如 sudo -E bash install.sh ...）。" >&2
  exit 1
fi

# ---------- 参数 ----------
TARGET_USER="${1:-}"
MNT="${2:-}"            # 非空 => 全新安装模式（minimal ISO）

if [[ -z "$TARGET_USER" ]]; then
  read -r -p "请输入要部署配置的用户名 [cookie]: " TARGET_USER
  TARGET_USER="${TARGET_USER:-cookie}"
fi
if [[ -z "$TARGET_USER" || "$TARGET_USER" == "root" ]]; then
  echo "错误：用户名不能为空或 root。" >&2
  exit 1
fi

if [[ -n "$MNT" && ! -d "$MNT" ]]; then
  echo "错误：挂载点 $MNT 不存在。请先分区并挂载到该目录。" >&2
  exit 1
fi

# ---------- nix / flakes 检查 ----------
if ! command -v nix >/dev/null 2>&1; then
  echo "错误：未检测到 nix 命令。" >&2
  exit 1
fi
if ! grep -q "flakes" /etc/nix/nix.conf 2>/dev/null; then
  echo "提示：/etc/nix/nix.conf 未检测到 'flakes'。若重建报错，请先加入："
  echo "      experimental-features = nix-command flakes"
fi

# ---------- 获取源码 ----------
echo "==> 获取仓库代码 ..."
SRC=""
if [[ -f flake.nix && -d dotfiles ]]; then
  SRC="$PWD"                       # 已从仓库内运行，复用当前目录
else
  SRC="$(mktemp -d)"
  git clone --depth 1 --branch "$BRANCH" "https://github.com/$REPO" "$SRC"
fi
cd "$SRC"

# ---------- 替换硬编码用户名 cookie -> TARGET_USER ----------
if [[ "$TARGET_USER" != "$OLD_USER" ]]; then
  echo "==> 将配置中的用户名 cookie 替换为 $TARGET_USER ..."
  while IFS= read -r -d '' f; do
    if grep -Iq "$OLD_USER" "$f" 2>/dev/null; then
      sed -i "s/$OLD_USER/$TARGET_USER/g" "$f"
    fi
  done < <(find . -type f -not -path './.git/*' -print0)
else
  echo "==> 目标用户名即 cookie，跳过替换。"
fi

if [[ -n "$MNT" ]]; then
  # ================= 全新安装模式（minimal ISO） =================
  DEST="$MNT/etc/nixos"
  mkdir -p "$DEST"
  echo "==> 部署到 $DEST ..."
  # 复制全部；本仓库不含 hardware-configuration.nix，不会覆盖你 generate 出来的那份
  cp -r "$SRC/." "$DEST/"
  rm -rf "$DEST/.git"

  if [[ ! -f "$DEST/hardware-configuration.nix" ]]; then
    echo "错误：$DEST/hardware-configuration.nix 不存在。" >&2
    echo "请先在分区并挂载到 $MNT 后运行：  nixos-generate-config --root $MNT" >&2
    echo "（该命令会生成 hardware-configuration.nix，含根分区挂载 / EFI / swap 等）" >&2
    exit 1
  fi

  # 首次登录需要密码；可选设置 initialPassword
  PW=""
  read -r -s -p "设置首次登录密码（留空则装后手动 passwd）: " PW
  echo
  if [[ -n "$PW" ]]; then
    esc_pw="$(printf '%s' "$PW" | sed 's/[&/\]/\\&/g')"
    sed -i "s|# initialPassword = \"changeme\";|initialPassword = \"$esc_pw\";|" "$DEST/configuration.nix"
  fi

  echo "==> 执行 nixos-install --flake $DEST/#$FLAKE_HOST ..."
  nixos-install --flake "$DEST/#$FLAKE_HOST"
  echo ""
  echo "==> 安装完成！重启即可进入 greetd → niri + Noctalia。"
  echo "    若首次登录密码留空，重启后在 TTY 用 root（或 live 环境）执行：passwd $TARGET_USER"
else
  # ================= 已装系统：rebuild =================
  DEST="/etc/nixos"
  echo "==> 部署到 $DEST ..."
  rm -rf "$DEST"
  mkdir -p "$DEST"
  cp -r "$SRC/." "$DEST/"
  rm -rf "$DEST/.git"
  if [[ ! -f "$DEST/hardware-configuration.nix" ]]; then
    echo "警告：未找到 $DEST/hardware-configuration.nix。"
    echo "      若这是全新安装（minimal ISO），请改用：bash install.sh <用户> <挂载点>"
  fi
  echo "==> 执行 nixos-rebuild switch --flake $DEST/#$FLAKE_HOST ..."
  nixos-rebuild switch --flake "$DEST/#$FLAKE_HOST"
  echo ""
  echo "==> 完成！重启或重新登录以进入 niri + Noctalia 桌面。"
  echo "    若 Home Manager 部分未生效，可再以该用户运行：home-manager switch --flake $DEST/#$FLAKE_HOST"
fi
