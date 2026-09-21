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

# Host 名从仓库内 flake.nix 读取（唯一数据源）。
# 必须在 cd "$SRC" 之后提取 —— 否则从仓库外启动（走 git clone）时，
# 读的是脚本原位置而非刚克隆的仓库。
if [[ -z "${FLAKE_HOST:-}" ]]; then
  FLAKE_HOST="$(sed -n 's/^ *hostname *= *"\([^"]*\)".*/\1/p' "$SRC/flake.nix" 2>/dev/null | head -1)"
  if [[ -z "$FLAKE_HOST" ]]; then
    echo "错误：无法从 $SRC/flake.nix 读取 hostname。" >&2
    exit 1
  fi
  echo "==> 使用 Host: $FLAKE_HOST"
fi

# ---------- 设置用户名（只改单一数据源） ----------
# 用户名在 flake.nix 的 `username = "..."` 一处定义，其余模块均引用它。
#
# 这里刻意不做全仓库 `sed s/cookie/<new>/g`：那会连
#   · GitHub 账号   cookieidea            → aliceidea
#   · 插件命名空间  cookie/translator     → alice/translator
# 一起改坏（两者都含 "cookie" 子串，但语义无关）。
#
# 家目录路径也不再需要替换：原先硬编码的 /home/cookie 已改为
#   · Nix 插值（noctalia/mpv 的 settings、gtk bookmarks）
#   · 运行时变量（$HOME / ~ 用于脚本与配置）
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

# ---------- 预构建自构建程序（flake 包）----------
# 注：Astral 已改为 fetchurl 直接取上游 GitHub Release（见
# configuration/pkgs/tools/networking/astral/default.nix），
# 不再需要本机联网构建 bundle，故此处无 Astral 专属步骤。

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

  # 保留目标机由 nixos-generate-config 生成的硬件配置。
  #
  # nixos-generate-config --root /mnt 写到 $MNT/etc/nixos/hardware-configuration.nix
  # （源文件名；见 nixpkgs 的 nixos-generate-config.pl），而本仓库的结构是
  # configuration/device/hardware/hardware-config.nix —— 需转换路径。
  #
  # 仓库里那份绑定 ATRI 的分区 UUID（/ 与 /boot 的 by-uuid），若不加处理
  # 会被全量复制覆盖，导致新机器按 ATRI 的分区表安装。
  GEN_HW="$MNT/etc/nixos/hardware-configuration.nix"
  KEEP_HW=""
  if [[ -f "$GEN_HW" ]]; then
    KEEP_HW="$(mktemp)"
    cp -a "$GEN_HW" "$KEEP_HW"
    echo "      ✓ 保留目标机生成的 hardware-configuration.nix"
  elif [[ -f "$MNT/etc/nixos/configuration/device/hardware/hardware-config.nix" ]]; then
    # 兼容：目标位置已有本仓库结构的硬件配置
    KEEP_HW="$(mktemp)"
    cp -a "$MNT/etc/nixos/configuration/device/hardware/hardware-config.nix" "$KEEP_HW"
    echo "      ✓ 保留目标机已有的 hardware-config.nix"
  fi

  cp -r "$SRC/." "$DEST/"
  rm -rf "$DEST/.git"

  # 目标机自己生成的硬件配置优先于仓库里 ATRI 的那份
  if [[ -n "$KEEP_HW" ]]; then
    cp -a "$KEEP_HW" "$DEST/configuration/device/hardware/hardware-config.nix"
    rm -f "$KEEP_HW"
  fi

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
  echo "    Astral 首次使用：打开 GUI 会自动把 core 部署到 ~/.local/share/astral-core，"
  echo "    之后执行：sudo setcap cap_net_admin=ep ~/.local/share/astral-core/app/astral-core"
  echo "    （TUN 需要该权限；core 更新后需重设。core 由 GUI 管理，无常驻服务、无自启。）"
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
  # 原子交换：先把旧目录移开，再把 staging 移入；任一步失败都回滚，绝不删原目录
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
  # backup 保留到 switch 成功之后：NixOS generation 可回滚，但 /etc/nixos
  # 的源码树不会随之回退，故 switch 失败时一并恢复配置源。
  if ! nixos-rebuild switch --flake "$DEST/#$FLAKE_HOST"; then
    echo "" >&2
    echo "错误：nixos-rebuild switch 失败。" >&2
    if [[ -d "$BACKUP" ]]; then
      echo "      正在恢复原配置源：$BACKUP → $DEST" >&2
      rm -rf "$DEST.rollback-tmp"
      mv "$DEST" "$DEST.rollback-tmp" 2>/dev/null || true
      if mv "$BACKUP" "$DEST"; then
        rm -rf "$DEST.rollback-tmp"
        echo "      ✓ 已恢复。可检查后重试。" >&2
      else
        echo "      ✗ 恢复失败；原配置仍在 $BACKUP，请手工处理。" >&2
      fi
    fi
    exit 1
  fi

  # switch 成功 → 清理 backup
  rm -rf "$BACKUP"
  echo ""
  echo "==> 完成！重启或重新登录以进入 niri + Noctalia 桌面。"
  echo "    Astral：core 由 GUI 管理（无常驻服务/自启）。GUI 内更新 core 后需重设权限："
  echo "    sudo setcap cap_net_admin=ep ~/.local/share/astral-core/app/astral-core"
  echo "    若 Home Manager 部分未生效，可再以该用户运行：home-manager switch --flake $DEST/#$FLAKE_HOST"
fi
