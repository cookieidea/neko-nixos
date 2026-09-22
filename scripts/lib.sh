# shellcheck shell=bash
# install.sh、bootstrap.sh、update.sh 共用函数。

REPO="cookieidea/neko-nixos"
BRANCH="${BRANCH:-main}"

# 引导阶段显式追加缓存，避免 live environment 尚未应用系统 nix.nix 时退回纯本地构建。
# 正式系统的缓存仍由 configuration/system/nix.nix 管理。
BOOTSTRAP_NIX_CONFIG='extra-substituters = https://mirrors.ustc.edu.cn/nix-channels/store https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store https://attic.xuyh0120.win/lantian https://noctalia.cachix.org https://nekobox.cachix.org https://cache.numtide.com https://cook-nixvim.cachix.org https://nix-community.cachix.org
extra-trusted-public-keys = lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc= noctalia.cachix.org-1:pCOR47nnMeo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4= nekobox.cachix.org-1:bRpp0vZK2Uq/vnydXC+uuOmFJW3W6fN4PI5PDy4iD+s= niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g= cook-nixvim.cachix.org-1:LjCZ3VSYrcwTQxHpd834EIswdkfHoSd/EsKUYLRruF4= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs='
export NIX_CONFIG="${NIX_CONFIG:+$NIX_CONFIG$'\n'}$BOOTSTRAP_NIX_CONFIG"

require_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "错误：请使用 root 运行（例如 sudo -E bash install.sh ...）。" >&2
        exit 1
    fi
}

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

# 仓库目录优先复用当前目录，否则 clone 到临时目录。
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

# 从 flake.nix 读取 hostname。
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

# 只修改 flake.nix 的 username。
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
    echo "==> 设置用户名：$current → $target ..."
    sed -i -E "s|^( *username = )\"$current\";|\1\"$target\";|" "$SRC/flake.nix"
    new="$(sed -n 's/^ *username = "\([^"]*\)";.*/\1/p' "$SRC/flake.nix" | head -1)"
    if [[ "$new" != "$target" ]]; then
        echo "错误：用户名替换失败（flake.nix 中仍为 $new），请手工检查。" >&2
        exit 1
    fi
}

# 构建目标系统闭包；失败后单独构建 public packages 定位问题。
prebuild_packages() {
    local target="${1:-$SRC}"
    local log_dir failed=() p
    log_dir="$(mktemp -d "${TMPDIR:-/tmp}/neko-nixos-build.XXXXXX")"

    echo "==> 预构建系统闭包（$target 的 nixosConfigurations.${FLAKE_HOST}）..."
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
        echo "      以下自定义包构建失败：" >&2
        for p in "${failed[@]}"; do
            echo "        · $p    （$log_dir/build-$p.log）" >&2
        done
    else
        echo "      自定义包均可单独构建；问题可能位于系统模块或其它依赖。" >&2
    fi
    echo "      请查阅 $log_dir/toplevel.log。" >&2
    exit 1
}

print_astral_hint() {
    echo "    Astral：core 由 GUI 管理（无常驻服务/自启）。首次打开 GUI 后需设权限："
    echo "    sudo setcap cap_net_admin=ep ~/.local/share/astral-core/app/astral-core"
}
