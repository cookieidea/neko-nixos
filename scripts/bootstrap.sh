#!/usr/bin/env bash
# 全新安装：把配置部署到挂载点并执行 nixos-install。
# 由 install.sh 调用；也可单独用：bash scripts/bootstrap.sh <用户名> <挂载点>
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$HERE/lib.sh"

TARGET_USER="${1:-}"
MNT="${2:-}"
SRC="${3:-$PWD}"          # 配置源码目录（由 install.sh 的 prepare_source 得到）
FLAKE_HOST="${4:-}"       # nixosConfigurations 的名字（由 resolve_host 得到）

if [[ -z "$TARGET_USER" || -z "$MNT" ]]; then
    echo "用法：bash scripts/bootstrap.sh <用户名> <挂载点> [源码目录] [host]" >&2
    exit 1
fi
if [[ -z "$FLAKE_HOST" ]]; then
    echo "错误：未指定 FLAKE_HOST。" >&2
    exit 1
fi

require_root
DEST="$MNT/etc/nixos"

# 硬件配置检查通过后才创建目标目录 —— 避免留下半安装状态。
# 保留目标机生成的配置，不复用仓库里旧机器的分区 UUID。
GEN_HW="$MNT/etc/nixos/hardware-configuration.nix"
GEN_HW_ALT="$MNT/etc/nixos/configuration/device/hardware-config.nix"
KEEP_HW=""
if [[ -f "$GEN_HW" ]]; then
    KEEP_HW="$(mktemp)"
    cp -a "$GEN_HW" "$KEEP_HW"
    echo "      ✓ 保留目标机生成的 hardware-configuration.nix"
elif [[ -f "$GEN_HW_ALT" ]]; then
    # 兼容已部署仓库结构的目标机。
    KEEP_HW="$(mktemp)"
    cp -a "$GEN_HW_ALT" "$KEEP_HW"
    echo "      ✓ 保留目标机已有的 hardware-config.nix"
else
    echo "错误：未找到目标机的硬件配置，已中止（未写入 $DEST）。" >&2
    echo "      期望其一：" >&2
    echo "        $GEN_HW" >&2
    echo "        $GEN_HW_ALT" >&2
    echo "      请先在分区并挂载到 $MNT 后运行：" >&2
    echo "        nixos-generate-config --root $MNT" >&2
    echo "      （该命令生成 hardware-configuration.nix，含根分区挂载 / EFI / swap）" >&2
    exit 1
fi

mkdir -p "$DEST"
echo "==> 部署到 $DEST ..."
cp -r "$SRC/." "$DEST/"
rm -rf "$DEST/.git"

# 目标机硬件配置优先于仓库里的那份。
cp -a "$KEEP_HW" "$DEST/configuration/device/hardware-config.nix"
rm -f "$KEEP_HW"

echo "==> 执行 nixos-install --flake $DEST/#$FLAKE_HOST ..."
nixos-install --flake "$DEST/#$FLAKE_HOST"

echo ""
echo "==> 设置 $TARGET_USER 的登录密码 ..."
if ! nixos-enter --root "$MNT" -c "passwd $TARGET_USER"; then
    echo "错误：用户密码设置失败。系统已安装，但请在重启前运行：" >&2
    echo "      nixos-enter --root $MNT -c 'passwd $TARGET_USER'" >&2
    exit 1
fi

echo ""
echo "==> 安装完成！重启即可进入 Noctalia Greeter → niri + Noctalia。"
print_astral_hint
