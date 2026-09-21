#!/usr/bin/env bash
#
# neko-nixos 一键安装/更新脚本
#   全新安装： sudo bash install.sh <用户名> <挂载点>   （挂载点需已分区+generate-config）
#   已装更新： sudo bash install.sh [用户名]
# 会把配置里硬编码的用户名 cookie 与 /home/cookie 路径替换成你的用户名（默认 cookie）
#
set -euo pipefail

REPO="cookieidea/neko-nixos"
BRANCH="${BRANCH:-main}"
# Host 名从 flake.nix 读取（唯一数据源），避免脚本与配置脱节
FLAKE_HOST="${FLAKE_HOST:-$(sed -n 's/^ *hostname *= *"\([^"]*\)".*/\1/p' "$(dirname "$0")/flake.nix" 2>/dev/null | head -1)}"
FLAKE_HOST="${FLAKE_HOST:-ATRI}"
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
if [[ -f flake.nix && -d configuration ]]; then
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

# ---------- 预构建自构建程序（flake 包）----------
# ---------- Astral bundle（联网构建，flake path 输入所必需）----------
# astral 的 bundle（约 75MB）不入 git；若本地没有，后面所有 nix 求值直接失败。
# 检测到缺失就在此构建（约 20～30 分钟，无需值守）；build.sh 收尾会自动重锁 flake。
BUNDLE_DIR="/home/$TARGET_USER/.cache/astral/bundle"
if [[ ! -x "$BUNDLE_DIR/astral" || ! -x "$BUNDLE_DIR/astral-core" ]]; then
  echo "==> Astral bundle 缺失，联网构建（约 20～30 分钟）..."
  bash "$SRC/configuration/pkgs/tools/networking/astral/build.sh"
  chown -R "$TARGET_USER" "$BUNDLE_DIR"
else
  echo "==> Astral bundle 已存在，跳过构建。"
fi

# 这些程序不在 nixpkgs 核心，由 ./configuration/pkgs 里的派生从源码 / 发布构建
# 这些程序不在 nixpkgs 核心，由 ./configuration/pkgs 里的派生构建。这里先单独构建，便于提前暴露
# 错误；后续 nixos-install / nixos-rebuild 会复用已构建的结果。
SELF_PKGS=(niri-sidebar nyxniri-scratch-menu pins shorin-contrib splayer-next ab-download-manager tabby-terminal obs-vdoninja purevox bedrockboot astral)
echo "==> 预构建自构建程序（flake 包）..."
for p in "${SELF_PKGS[@]}"; do
  echo "    • 构建 $p ..."
  if nix build ".#$p" --no-link 2>"$SRC/.build-$p.log"; then
    echo "      ✓ $p 构建成功"
  else
    # 不中断整体安装：后续 nixos-rebuild 会再次报错并给出完整信息
    echo "      ✗ $p 构建失败（详见 $SRC/.build-$p.log）；继续。" >&2
  fi
done

if [[ -n "$MNT" ]]; then
  # ================= 全新安装模式（minimal ISO） =================
  DEST="$MNT/etc/nixos"
  mkdir -p "$DEST"
  echo "==> 部署到 $DEST ..."
  # 全量复制。hardware-config.nix 由 nixos-generate-config 生成（已被 git 跟踪，
  # 内容是 ATRI 本机的分区 UUID），若目标机硬件不同需重新生成覆盖。
  cp -r "$SRC/." "$DEST/"
  rm -rf "$DEST/.git"

  if [[ ! -f "$DEST/configuration/device/hardware/hardware-config.nix" ]]; then
    echo "错误：$DEST/configuration/device/hardware/hardware-config.nix 不存在。" >&2
    echo "请先在分区并挂载到 $MNT 后运行：  nixos-generate-config --root $MNT" >&2
    echo "（该命令会生成 hardware-configuration.nix，含根分区挂载 / EFI / swap 等）" >&2
    exit 1
  fi

  # 密码不在安装时注入（配置里已无 initialPassword 占位，sed 注入属失效逻辑）。
  # 装完在 TTY 用 root 执行 passwd <用户> 设置即可，下方提示会说明。

  echo "==> 执行 nixos-install --flake $DEST/#$FLAKE_HOST ..."
  nixos-install --flake "$DEST/#$FLAKE_HOST"
  echo ""
  echo "==> 安装完成！重启即可进入 greetd → niri + Noctalia。"
  echo "    Astral 首次使用前：进 GUI 连一次自动部署 core，之后跑：sudo setcap cap_net_admin=ep ~/.local/share/astral-core/app/astral-core（否则 TUN 起不来；每次更新 core 都要重跑一次）。"
  echo "    若首次登录密码留空，重启后在 TTY 用 root（或 live 环境）执行：passwd $TARGET_USER"
else
  # ================= 已装系统：rebuild =================
  # 事务式更新：先在 staging 目录校验，通过后才替换 /etc/nixos。
  # 避免旧写法 `rm -rf /etc/nixos` 在中途失败时留下残缺配置。
  DEST="/etc/nixos"
  # $DEST 可能是挂载点（/etc/nixos 常为 bind mount / 独立分区），
  # 故 staging 放在同级的隐藏目录，保证最终 mv 是同一文件系统内的原子操作。
  STAGE="$(dirname "$DEST")/.nixos-staging.$$"
  BACKUP="$(dirname "$DEST")/.nixos-backup.$$"
  # shellcheck disable=SC2064
  trap 'rm -rf "$STAGE"' EXIT

  echo "==> 准备 staging：$STAGE ..."
  rm -rf "$STAGE"; mkdir -p "$STAGE"

  # 保留目标机现有的 hardware-config（含该机分区 UUID；仓库里那份属 ATRI，
  # 换机时不应被覆盖）
  if [[ -f "$DEST/configuration/device/hardware/hardware-config.nix" ]]; then
    cp -a "$DEST/configuration/device/hardware/hardware-config.nix" "$STAGE/hardware-config.keep"
  fi

  cp -r "$SRC/." "$STAGE/"
  rm -rf "$STAGE/.git"
  [[ -f "$STAGE/hardware-config.keep" ]] && \
    mv "$STAGE/hardware-config.keep" "$STAGE/configuration/device/hardware/hardware-config.nix"

  if [[ ! -f "$STAGE/configuration/device/hardware/hardware-config.nix" ]]; then
    echo "警告：未找到 configuration/device/hardware/hardware-config.nix。"
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
  if [[ -d "$DEST" ]]; then mv "$DEST" "$BACKUP" || { rm -rf "$DEST"; }; fi
  mv "$STAGE" "$DEST"
  trap - EXIT
  rm -rf "$BACKUP"

  echo "==> 执行 nixos-rebuild switch --flake $DEST/#$FLAKE_HOST ..."
  nixos-rebuild switch --flake "$DEST/#$FLAKE_HOST"
  echo ""
  echo "==> 完成！重启或重新登录以进入 niri + Noctalia 桌面。"
  echo "    Astral core 若更新：GUI 里同步后跑 sudo setcap cap_net_admin=ep ~/.local/share/astral-core/app/astral-core，否则 TUN 起不来。"
  echo "    若 Home Manager 部分未生效，可再以该用户运行：home-manager switch --flake $DEST/#$FLAKE_HOST"
fi
