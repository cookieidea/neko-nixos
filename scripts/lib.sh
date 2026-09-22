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

# 预构建 flake 暴露的全部自定义包。
# 包列表从 flake 派生，不手写 —— 手写会与 configuration/pkgs 脱节。
prebuild_packages() {
    local system pkgs=() failed=() p
    local log_dir
    log_dir="$(mktemp -d "${TMPDIR:-/tmp}/neko-nixos-build.XXXXXX")"

    echo "==> 读取 flake 暴露的包列表 ..."
    if ! system="$(nix eval --raw --impure --expr \
          "(builtins.getFlake \"$SRC\").nixosConfigurations.\"$FLAKE_HOST\".pkgs.stdenv.hostPlatform.system" \
          2>"$log_dir/pkglist.log")" || [[ -z "$system" ]]; then
        echo "错误：无法确定 system（详见 $log_dir/pkglist.log）。" >&2
        exit 1
    fi
    # 用 nix eval --raw + concatStringsSep 直接取换行分隔的包名，
    # 避免依赖宿主的 jq（干净的安装环境未必有）。
    if ! mapfile -t pkgs < <(nix eval --raw --impure --expr \
          "builtins.concatStringsSep \"\\n\" (builtins.attrNames (builtins.getFlake \"$SRC\").packages.\"$system\")" \
          2>>"$log_dir/pkglist.log"); then
        echo "错误：无法读取 flake 包列表（详见 $log_dir/pkglist.log）。" >&2
        exit 1
    fi
    if (( ${#pkgs[@]} == 0 )); then
        echo "错误：flake 包列表为空。" >&2
        exit 1
    fi

    echo "      system=$system，共 ${#pkgs[@]} 个包"
    echo "==> 预构建自构建程序（flake 包）..."
    for p in "${pkgs[@]}"; do
        echo "    • 构建 $p ..."
        if nix build ".#$p" --no-link 2>"$log_dir/build-$p.log"; then
            echo "      ✓ $p 构建成功"
        else
            echo "      ✗ $p 构建失败" >&2
            failed+=("$p")
        fi
    done

    if (( ${#failed[@]} > 0 )); then
        echo "" >&2
        echo "错误：以下包构建失败，已中止：" >&2
        echo "      构建日志目录：$log_dir" >&2
        for p in "${failed[@]}"; do
            echo "        · $p    （$log_dir/build-$p.log）" >&2
        done
        echo "      这些包都在系统闭包内，继续只会让 rebuild 稍后以更难读的方式失败。" >&2
        echo "      修复后可重跑（已成功构建的包会被缓存，不会重复构建）。" >&2
        exit 1
    fi

    rm -rf "$log_dir"
}
# 打印 Astral 的首次使用提示（两处共用）。
print_astral_hint() {
    echo "    Astral：core 由 GUI 管理（无常驻服务/自启）。首次打开 GUI 后需设权限："
    echo "    sudo setcap cap_net_admin=ep ~/.local/share/astral-core/app/astral-core"
}
