#!/usr/bin/env bash
## neko-nixos 安装与更新入口。
# 用法：install.sh <用户名> [挂载点]
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/scripts/lib.sh"

require_root

TARGET_USER="${1:-}"
MNT="${2:-}"

if [[ -z "$TARGET_USER" ]]; then
    read -r -p "请输入要部署配置的用户名: " TARGET_USER
fi
if [[ -z "$TARGET_USER" || "$TARGET_USER" == "root" ]]; then
    echo "错误：用户名不能为空或 root。" >&2
    exit 1
fi
if [[ ! "$TARGET_USER" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
    echo "错误：非法 Linux 用户名 '$TARGET_USER'。" >&2
    echo "      要求：小写字母或下划线开头，仅含小写字母、数字、下划线、连字符。" >&2
    exit 1
fi

if [[ -n "$MNT" && ! -d "$MNT" ]]; then
    echo "错误：挂载点 $MNT 不存在。请先分区并挂载到该目录。" >&2
    exit 1
fi

check_nix
prepare_source
resolve_host

CURRENT_USER_IN_SRC="$(sed -n 's/^ *username = "\([^"]*\)".*/\1/p' "$SRC/flake.nix" | head -1)"

if [[ "$SRC" == "$PWD" ]] && [[ -d "$SRC/.git" ]] && [[ "$TARGET_USER" != "$CURRENT_USER_IN_SRC" ]]; then
    if [[ "${ALLOW_INPLACE_USERNAME_CHANGE:-0}" == "1" ]]; then
        echo "警告：ALLOW_INPLACE_USERNAME_CHANGE=1，将直接修改 $SRC/flake.nix" >&2
    else
        echo "错误：拒绝在 git 工作区内修改用户名。" >&2
        echo "      当前 $SRC/flake.nix 的 username = \"$CURRENT_USER_IN_SRC\"。" >&2
        echo "      而你要求部署为 \"$TARGET_USER\" —— 这会改动工作区源码。" >&2
        echo "" >&2
        echo "      可从仓库外运行，或设置 ALLOW_INPLACE_USERNAME_CHANGE=1。" >&2
        exit 1
    fi
fi

set_username "$TARGET_USER"

if [[ -n "$MNT" ]]; then
    bash "$HERE/scripts/bootstrap.sh" "$TARGET_USER" "$MNT" "$SRC" "$FLAKE_HOST"
else
    bash "$HERE/scripts/update.sh" "$TARGET_USER" "$SRC" "$FLAKE_HOST"
fi
