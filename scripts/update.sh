#!/usr/bin/env bash
# 已安装系统的更新：staging 校验 → dry-build → 原子替换 → switch（失败回滚）。
# 由 install.sh 调用；也可单独用：bash scripts/update.sh <用户名>
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$HERE/lib.sh"

TARGET_USER="${1:-}"
SRC="${2:-$PWD}"          # 配置源码目录（由 install.sh 的 prepare_source 得到）
FLAKE_HOST="${3:-}"       # nixosConfigurations 的名字（由 resolve_host 得到）

if [[ -z "$TARGET_USER" ]]; then
    echo "用法：bash scripts/update.sh <用户名> [源码目录] [host]" >&2
    exit 1
fi
if [[ -z "$FLAKE_HOST" ]]; then
    echo "错误：未指定 FLAKE_HOST。" >&2
    exit 1
fi

require_root
DEST="/etc/nixos"
# staging 与备份都放在 DEST 同级，保证 mv 是同一文件系统内的原子操作。
STAGE="$(dirname "$DEST")/.nixos-staging.$$"
BACKUP="$(dirname "$DEST")/.nixos-backup.$$"
trap 'rm -rf "$STAGE"' EXIT

echo "==> 准备 staging：$STAGE ..."
rm -rf "$STAGE"; mkdir -p "$STAGE"

# 保留当前机器的硬件配置（不在 git 中，含本机 UUID）。
if [[ -f "$DEST/configuration/device/hardware-config.nix" ]]; then
    cp -a "$DEST/configuration/device/hardware-config.nix" "$STAGE/hardware-config.keep"
fi

cp -r "$SRC/." "$STAGE/"
rm -rf "$STAGE/.git"
[[ -f "$STAGE/hardware-config.keep" ]] && \
    mv "$STAGE/hardware-config.keep" "$STAGE/configuration/device/hardware-config.nix"

if [[ ! -f "$STAGE/configuration/device/hardware-config.nix" ]]; then
    echo "警告：未找到 configuration/device/hardware-config.nix。"
    echo "      若这是全新安装（minimal ISO），请改用：bash install.sh <用户> <挂载点>"
fi

echo "==> 校验 staging 配置 ..."
if ! (cd "$STAGE" && nix flake check 2>&1 | tail -20); then
    echo "错误：staging 配置未通过 nix flake check，已放弃更新（$DEST 未被改动）。" >&2
    exit 1
fi

echo "==> 试构建（dry-build）..."
if ! nixos-rebuild dry-build --flake "$STAGE/#$FLAKE_HOST" 2>&1 | tail -20; then
    echo "错误：dry-build 失败，已放弃更新（$DEST 未被改动）。" >&2
    exit 1
fi

echo "==> 校验通过，替换 $DEST ..."
rm -rf "$BACKUP"
if [[ -d "$DEST" ]]; then
    if ! mv "$DEST" "$BACKUP"; then
        echo "错误：无法移开 $DEST（权限或挂载问题），已放弃更新。" >&2
        exit 1
    fi
fi
if ! mv "$STAGE" "$DEST"; then
    echo "错误：无法将 staging 移入 $DEST，正在回滚 ..." >&2
    [[ -d "$BACKUP" ]] && mv "$BACKUP" "$DEST"
    exit 1
fi
trap - EXIT

echo "==> 执行 nixos-rebuild switch --flake $DEST/#$FLAKE_HOST ..."
# switch 成功前保留旧配置源，避免 generation 回滚与源码版本不一致。
if ! nixos-rebuild switch --flake "$DEST/#$FLAKE_HOST"; then
    echo "" >&2
    echo "错误：nixos-rebuild switch 失败。" >&2
    if [[ -d "$BACKUP" ]]; then
        echo "      正在恢复原配置源：$BACKUP → $DEST" >&2
        # 只有确认目标路径已移走后才恢复，否则 mv 会变成嵌套目录而非替换。
        rm -rf "$DEST.rollback-tmp"
        if [[ -e "$DEST" ]] && ! mv "$DEST" "$DEST.rollback-tmp"; then
            echo "      ✗ 无法移开 $DEST（可能是挂载点或正被占用）。" >&2
            echo "        原配置完整保留在：$BACKUP" >&2
            echo "        请手工恢复，例如：" >&2
            echo "          rm -rf '$DEST' && mv '$BACKUP' '$DEST'" >&2
            echo "        （若 $DEST 是挂载点，先 umount）" >&2
            exit 1
        fi
        if mv "$BACKUP" "$DEST"; then
            rm -rf "$DEST.rollback-tmp"
            echo "      ✓ 已恢复。可检查后重试。" >&2
        else
            # 恢复失败时尽量把原目录放回原位。
            [[ -e "$DEST.rollback-tmp" && ! -e "$DEST" ]] && mv "$DEST.rollback-tmp" "$DEST"
            echo "      ✗ 恢复失败；原配置在：$BACKUP" >&2
            echo "        （$DEST.rollback-tmp 是失败前移开的中间态，请手工处理）" >&2
        fi
    fi
    exit 1
fi

# switch 成功后才删除备份。
rm -rf "$BACKUP"
echo ""
echo "==> 完成！重启或重新登录以进入 niri + Noctalia 桌面。"
print_astral_hint
echo "    若 Home Manager 部分未生效，可再以该用户运行：home-manager switch --flake $DEST/#$FLAKE_HOST"
