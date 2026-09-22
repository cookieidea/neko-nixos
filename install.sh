#!/usr/bin/env bash
## neko-nixos 安装与更新入口。
#   全新安装：sudo bash install.sh <用户名> <挂载点>
#   已装更新：sudo bash install.sh [用户名]
#
# 只做参数校验与环境检查，实际工作分发到 scripts/ 下的子脚本：
#   scripts/lib.sh        共用函数（源码准备、用户名、预构建包）
#   scripts/bootstrap.sh  全新安装（挂载点 → nixos-install）
#   scripts/update.sh     已装系统更新（staging → 原子替换 → switch）
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib.sh
source "$HERE/scripts/lib.sh"

require_root

# ---- 参数 ----
TARGET_USER="${1:-}"
MNT="${2:-}"            # 非空 => 全新安装模式

if [[ -z "$TARGET_USER" ]]; then
    read -r -p "请输入要部署配置的用户名: " TARGET_USER
fi
if [[ -z "$TARGET_USER" || "$TARGET_USER" == "root" ]]; then
    echo "错误：用户名不能为空或 root。" >&2
    exit 1
fi
# 用户名会写入 flake.nix 并参与路径拼接，因此只接受安全字符。
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

# ---- 准备源码并解析参数（子脚本依赖这些全局变量）----
prepare_source
resolve_host

# 就地运行（当前目录即仓库）时，set_username 会直接 sed 修改 flake.nix。
# 若该目录是 git 工作区，这等于在部署过程中改掉你正在维护的源码。
# 故：只有当用户名与当前值一致时才允许就地运行；否则要求从仓库外运行
# （那样会 clone 到临时目录，不碰原仓库）。
CURRENT_USER_IN_SRC="$(sed -n 's/^ *username = "\([^"]*\)";.*/\1/p' "$SRC/flake.nix" | head -1)"
# 注意判断条件：只有真正「就地运行」才拦截。prepare_source 从仓库外运行时
# 会 clone 到临时目录（SRC != 原目录），那是安全的，不应拦。
if [[ "$SRC" == "$PWD" ]] && [[ -d "$SRC/.git" ]] && [[ "$TARGET_USER" != "$CURRENT_USER_IN_SRC" ]]; then
    if [[ "${ALLOW_INPLACE_USERNAME_CHANGE:-0}" == "1" ]]; then
        echo "警告：ALLOW_INPLACE_USERNAME_CHANGE=1，将直接修改 $SRC/flake.nix" >&2
    else
        echo "错误：拒绝在 git 工作区内修改用户名。" >&2
        echo "      当前 $SRC/flake.nix 的 username = \"$CURRENT_USER_IN_SRC\"，" >&2
        echo "      而你要求部署为 \"$TARGET_USER\" —— 这会改动工作区源码。" >&2
        echo "" >&2
        echo "      二选一：" >&2
        echo "        1. 从仓库外运行（会 clone 到临时目录，不碰原仓库）：" >&2
        echo "             cd /tmp && sudo bash $SRC/install.sh $TARGET_USER" >&2
        echo "        2. 确需就地修改，则显式允许：" >&2
        echo "             sudo ALLOW_INPLACE_USERNAME_CHANGE=1 bash install.sh $TARGET_USER" >&2
        exit 1
    fi
fi

set_username "$TARGET_USER"

# ---- 两种模式共同的前置：先构建自定义包，便于把失败定位到具体包 ----
prebuild_packages

# ---- 分发 ----
if [[ -n "$MNT" ]]; then
    bash "$HERE/scripts/bootstrap.sh" "$TARGET_USER" "$MNT" "$SRC" "$FLAKE_HOST"
else
    bash "$HERE/scripts/update.sh" "$TARGET_USER" "$SRC" "$FLAKE_HOST"
fi
