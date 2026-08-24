#!/usr/bin/env bash
# 手动联网构建 Astral 并更新本地 bundle（供 Nix 打包使用）。
#
# 上游（https://github.com/AstralNext/Astral）是 Flutter GUI + Rust/EasyTier 核心，
# 构建需要网络（dart pub get + cargokit 调 rustup/cargo 编译 Rust 核心），
# 无法在 Nix 沙箱内完成，因此：
#   1. 本脚本联网构建一次（产物 bundle）
#   2. bundle 落到 /home/cookie/.cache/astral/bundle
#   3. flake 通过 path 输入引用它，nixos-rebuild 按内容哈希自动打包
#
# 升级上游：改 REF，然后 `sudo bash build.sh`，再 `sudo nixos-rebuild switch`。
set -euo pipefail

WORK=/tmp/astral-build-work
CORE_WORK=/tmp/astral-core-build-work
BUNDLE_DEST=/home/cookie/.cache/astral/bundle
REPO_URL=https://github.com/AstralNext/Astral.git
CORE_REPO_URL=https://github.com/AstralNext/astral-core.git
REF=main

cd "$(dirname "$0")"

echo "==> 拉取上游 $REF"
rm -rf "$WORK"
git clone --depth 1 --branch "$REF" "$REPO_URL" "$WORK"

echo "==> 打 CMake 4.x 补丁（强制 install 前缀为 bundle 目录）"
# 上游 linux/CMakeLists.txt 用 CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT 守卫，
# CMake 4.x 下该变量不再置位 → 产物会被装到 /usr/local。改成无条件设到 bundle 目录。
sed -i '/^if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)$/,/^endif()$/c\  set(CMAKE_INSTALL_PREFIX "${BUILD_BUNDLE_DIR}" CACHE PATH "..." FORCE)' "$WORK/linux/CMakeLists.txt"

echo "==> 开发 shell 内构建（联网）"
nix develop ./dev-shell -c bash -c '
  set -euo pipefail
  cd "$1"
  flutter pub get
  flutter build linux --release
' _ "$WORK"

echo "==> 更新 bundle → $BUNDLE_DEST"
mkdir -p "$BUNDLE_DEST"
cp -r "$WORK/build/linux/x64/release/bundle/." "$BUNDLE_DEST/"
rm -rf "$WORK"

echo "==> 构建 astral-core（GUI 依赖的本机内核服务）"
rm -rf "$CORE_WORK"
git clone --depth 1 --branch "$REF" "$CORE_REPO_URL" "$CORE_WORK"
nix develop ./dev-shell -c bash -c '
  set -euo pipefail
  cd "$1"
  cargo build --release
' _ "$CORE_WORK"
cp "$CORE_WORK/target/release/astral-core" "$BUNDLE_DEST/astral-core"
rm -rf "$CORE_WORK"

echo "==> 完成。执行 sudo nixos-rebuild switch 重新打包。"
