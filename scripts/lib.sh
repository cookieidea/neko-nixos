# shellcheck shell=bash
# install.sh / bootstrap / update 共用的函数与变量。
# 由入口 source，不单独执行。

REPO="cookieidea/neko-nixos"
BRANCH="${BRANCH:-main}"

# 需要 root（写 /etc/nixos、nixos-install / nixos-rebuild）。
require_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "错误：请使用 root 运行（例如 sudo -E bash install.sh ...）。" >&2
        exit 1
    fi
}

# Nix 与 flakes 可用性检查。
check_nix() {
    if ! command -v nix >/dev/null 2>&1; then
        echo "错误：未检测到 nix 命令。" >&2
        exit 1
    fi
    if ! grep -q "flakes" /etc/nix/nix.conf 2>/dev/null; then
        echo "提示：/etc/nix/nix.conf 未检测到 'flakes'。若重建报错，请先加入："
        echo "      experimental-features = nix-command flakes"
    fi
}

# 准备源码：仓库内运行则复用当前目录，否则 clone 到临时目录。
# 结果写入全局变量 SRC。
prepare_source() {
    echo "==> 获取仓库代码 ..."
    SRC=""
    if [[ -f flake.nix && -d configuration ]]; then
        SRC="$PWD"
    else
        SRC="$(mktemp -d)"
        git clone --depth 1 --branch "$BRANCH" "https://github.com/$REPO" "$SRC"
    fi
    cd "$SRC" || { echo "错误：无法进入 $SRC。" >&2; exit 1; }
}

# Host 从仓库内 flake.nix 读取（单一数据源）。
resolve_host() {
    if [[ -z "${FLAKE_HOST:-}" ]]; then
        FLAKE_HOST="$(sed -n 's/^ *hostname *= *"\([^"]*\)".*/\1/p' "$SRC/flake.nix" 2>/dev/null | head -1)"
        if [[ -z "$FLAKE_HOST" ]]; then
            echo "错误：无法从 $SRC/flake.nix 读取 hostname。" >&2
            exit 1
        fi
        echo "==> 使用 Host: $FLAKE_HOST"
    fi
}

# 设置用户名：只改 flake.nix 的 username，不做全仓库文本替换。
# 先读出当前值再比较 —— 不能假设旧值固定，否则二次迁移会匹配不上。
set_username() {
    local target="$1"
    local current new
    current="$(sed -n 's/^ *username = "\([^"]*\)";.*/\1/p' "$SRC/flake.nix" | head -1)"
    if [[ -z "$current" ]]; then
        echo "错误：在 $SRC/flake.nix 中找不到 username 定义，无法设置用户名。" >&2
        exit 1
    fi
    if [[ "$target" == "$current" ]]; then
        echo "==> 用户名已是 $target，跳过替换。"
        return 0
    fi
    echo "==> 设置用户名：$current → $target（改 flake.nix 单一数据源）..."
    sed -i -E "s|^( *username = )\"$current\";|\1\"$target\";|" "$SRC/flake.nix"
    new="$(sed -n 's/^ *username = "\([^"]*\)";.*/\1/p' "$SRC/flake.nix" | head -1)"
    if [[ "$new" != "$target" ]]; then
        echo "错误：用户名替换失败（flake.nix 中仍为 $new），请手工检查。" >&2
        exit 1
    fi
    echo "      ✓ username = \"$target\""
}

# 预构建系统闭包。
#
# 原先遍历 packages.<system> 逐个构建「全部 public 包」—— 但 public 只是
# 「对外可单独 nix build」的集合，不等于系统实际用到的东西。结果是某个
# 根本没装进系统的自定义包一旦构建失败，就会阻断整个安装。
#
# 改为直接构建 system.build.toplevel：这正是系统真正需要的闭包，
# 未使用的 public 包自然不会被牵扯进来。
# 若失败，再逐个尝试自定义包，以便把问题定位到具体包（保留原有的可诊断性）。
prebuild_packages() {
    local target="${1:-$SRC}"   # 要构建的配置目录（新装=$DEST，更新=$STAGE）
    local log_dir failed=() p
    log_dir="$(mktemp -d "${TMPDIR:-/tmp}/neko-nixos-build.XXXXXX")"

    echo "==> 预构建系统闭包（$target 的 nixosConfigurations.${FLAKE_HOST}）..."
    echo "    首次安装需要下载/构建整个系统闭包，耗时较长属正常。"
    if nix build "$target#nixosConfigurations.${FLAKE_HOST}.config.system.build.toplevel" \
         --no-link 2>"$log_dir/toplevel.log"; then
        echo "      ✓ 系统闭包构建完成"
        rm -rf "$log_dir"
        return 0
    fi

    echo "" >&2
    echo "错误：系统闭包构建失败（完整日志：$log_dir/toplevel.log）。" >&2
    echo "      正在逐个尝试自定义包以定位问题 ..." >&2

    local system pkgs=()
    if system="$(nix eval --raw --impure --expr \
          "(builtins.getFlake \"$target\").nixosConfigurations.\"$FLAKE_HOST\".pkgs.stdenv.hostPlatform.system" \
          2>/dev/null)" && [[ -n "$system" ]]; then
        mapfile -t pkgs < <(nix eval --raw --impure --expr \
              "builtins.concatStringsSep \"\\n\" (builtins.attrNames (builtins.getFlake \"$target\").packages.\"$system\")" \
              2>/dev/null) || true
    fi

    for p in "${pkgs[@]}"; do
        nix build "$target#$p" --no-link 2>"$log_dir/build-$p.log" || failed+=("$p")
    done

    if (( ${#failed[@]} > 0 )); then
        echo "      以下自定义包构建失败，很可能就是闭包失败的原因：" >&2
        for p in "${failed[@]}"; do
            echo "        · $p    （$log_dir/build-$p.log）" >&2
        done
    else
        echo "      自定义包均可单独构建，问题可能出在系统模块或其它依赖；" >&2
    fi
    echo "      请查阅 $log_dir/toplevel.log 定位。" >&2
    echo "      修复后可重跑（已成功的部分会被缓存，不会重复构建）。" >&2
    exit 1
}

# 打印 Astral 的首次使用提示（两处共用）。
print_astral_hint() {
    echo "    Astral：core 由 GUI 管理（无常驻服务/自启）。首次打开 GUI 后需设权限："
    echo "    sudo setcap cap_net_admin=ep ~/.local/share/astral-core/app/astral-core"
}
