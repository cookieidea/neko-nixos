#!/usr/bin/env bash
## neko-nixos 安装与更新入口。
# 新安装：install.sh <用户名> <挂载点>
# 更新：install.sh [用户名]
#
set -euo pipefail

REPO="cookieidea/neko-nixos"
BRANCH="${BRANCH:-main}"
OLD_USER="cookie"

if [[ $EUID -ne 0 ]]; then
  echo "错误：请使用 root 运行（例如 sudo -E bash install.sh ...）。" >&2
  exit 1
fi

# 参数校验。
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

# Nix / flakes 检查。
if ! command -v nix >/dev/null 2>&1; then
  echo "错误：未检测到 nix 命令。" >&2
  exit 1
fi
if ! grep -q "flakes" /etc/nix/nix.conf 2>/dev/null; then
  echo "提示：/etc/nix/nix.conf 未检测到 'flakes'。若重建报错，请先加入："
  echo "      experimental-features = nix-command flakes"
fi

# 获取源码。
echo "==> 获取仓库代码 ..."
SRC=""
if [[ -f flake.nix && -d configuration ]]; then
  SRC="$PWD"                       # 已从仓库内运行，复用当前目录
else
  SRC="$(mktemp -d)"
  git clone --depth 1 --branch "$BRANCH" "https://github.com/$REPO" "$SRC"
fi
cd "$SRC"

# Host 从仓库内 flake.nix 读取。
if [[ -z "${FLAKE_HOST:-}" ]]; then
  FLAKE_HOST="$(sed -n 's/^ *hostname *= *"\([^"]*\)".*/\1/p' "$SRC/flake.nix" 2>/dev/null | head -1)"
  if [[ -z "$FLAKE_HOST" ]]; then
    echo "错误：无法从 $SRC/flake.nix 读取 hostname。" >&2
    exit 1
  fi
  echo "==> 使用 Host: $FLAKE_HOST"
fi

# 只修改 flake.nix 中的 username，不做全仓库文本替换。
if [[ "$TARGET_USER" != "$OLD_USER" ]]; then
  echo "==> 设置用户名为 $TARGET_USER（改 flake.nix 单一数据源）..."
  if ! grep -qE '^ *username = "' "$SRC/flake.nix"; then
    echo "错误：在 $SRC/flake.nix 中找不到 username 定义，无法设置用户名。" >&2
    exit 1
  fi
  sed -i -E "s|^( *username = )\"$OLD_USER\";|\1\"$TARGET_USER\";|" "$SRC/flake.nix"
  if ! grep -qE "^ *username = \"$TARGET_USER\";" "$SRC/flake.nix"; then
    echo "错误：用户名替换失败，请手工检查 $SRC/flake.nix。" >&2
    exit 1
  fi
  echo "      ✓ username = \"$TARGET_USER\""
else
  echo "==> 目标用户名即 cookie，跳过替换。"
fi

# 先单独构建自定义包，便于定位失败；成功结果会被后续安装复用。
SELF_PKGS=(niri-sidebar nyxniri-scratch-menu pins shorin-contrib splayer-next ab-download-manager tabby-terminal obs-vdoninja purevox bedrockboot astral)
echo "==> 预构建自构建程序（flake 包）..."
FAILED_PKGS=()
for p in "${SELF_PKGS[@]}"; do
  echo "    • 构建 $p ..."
  if nix build ".#$p" --no-link 2>"$SRC/.build-$p.log"; then
    echo "      ✓ $p 构建成功"
  else
    echo "      ✗ $p 构建失败" >&2
    FAILED_PKGS+=("$p")
  fi
done
if (( ${#FAILED_PKGS[@]} > 0 )); then
  echo "" >&2
  echo "错误：以下包构建失败，已中止安装：" >&2
  for p in "${FAILED_PKGS[@]}"; do
    echo "        · $p    （日志：$SRC/.build-$p.log）" >&2
  done
  echo "      这些包都在系统闭包内，继续只会让 rebuild 稍后以更难读的方式失败。" >&2
  echo "      修复后可重跑本脚本（已成功构建的包会被缓存，不会重复构建）。" >&2
  exit 1
fi

if [[ -n "$MNT" ]]; then
  # 新安装模式。
  DEST="$MNT/etc/nixos"
  # 硬件配置检查通过后再创建目标目录。

# 保留目标机生成的硬件配置，避免复用仓库中旧机器的分区 UUID。
  GEN_HW="$MNT/etc/nixos/hardware-configuration.nix"
  GEN_HW_ALT="$MNT/etc/nixos/configuration/device/hardware-config.nix"
  KEEP_HW=""
  if [[ -f "$GEN_HW" ]]; then
    KEEP_HW="$(mktemp)"
    cp -a "$GEN_HW" "$KEEP_HW"
    echo "      ✓ 保留目标机生成的 hardware-configuration.nix"
  elif [[ -f "$GEN_HW_ALT" ]]; then
    # 兼容已部署仓库结构。
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

  # 目标机硬件配置优先。
  cp -a "$KEEP_HW" "$DEST/configuration/device/hardware-config.nix"
  rm -f "$KEEP_HW"

  # 不在安装阶段写入密码；安装后通过 passwd 设置。

  echo "==> 执行 nixos-install --flake $DEST/#$FLAKE_HOST ..."
  nixos-install --flake "$DEST/#$FLAKE_HOST"
  echo ""
  echo "==> 安装完成！重启即可进入 greetd → niri + Noctalia。"
  echo "    Astral 首次使用：打开 GUI 会自动把 core 部署到 ~/.local/share/astral-core，"
  echo "    之后执行：sudo setcap cap_net_admin=ep ~/.local/share/astral-core/app/astral-core"
  echo "    （TUN 需要该权限；core 更新后需重设。core 由 GUI 管理，无常驻服务、无自启。）"
  echo "    若首次登录密码留空，重启后在 TTY 用 root（或 live 环境）执行：passwd $TARGET_USER"
else
  # 已安装系统更新模式。
  # 先在 staging 中检查和 dry-build，通过后再替换目标目录。
  DEST="/etc/nixos"
  # staging 与目标保持同一文件系统，便于安全交换。
  STAGE="$(dirname "$DEST")/.nixos-staging.$$"
  BACKUP="$(dirname "$DEST")/.nixos-backup.$$"
  trap 'rm -rf "$STAGE"' EXIT

  echo "==> 准备 staging：$STAGE ..."
  rm -rf "$STAGE"; mkdir -p "$STAGE"

  # 保留当前机器的硬件配置。
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
  # 交换目录；失败时回滚。
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
      # 只有确认目标路径已移走后才能恢复备份，避免 mv 嵌套目录。
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

  # switch 成功后删除备份。
  rm -rf "$BACKUP"
  echo ""
  echo "==> 完成！重启或重新登录以进入 niri + Noctalia 桌面。"
  echo "    Astral：core 由 GUI 管理（无常驻服务/自启）。GUI 内更新 core 后需重设权限："
  echo "    sudo setcap cap_net_admin=ep ~/.local/share/astral-core/app/astral-core"
  echo "    若 Home Manager 部分未生效，可再以该用户运行：home-manager switch --flake $DEST/#$FLAKE_HOST"
fi
