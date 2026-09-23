{ pkgs }:

# niri-sidebar（Rust）。
# 用 pkgs.fetchgit（固定输出派生）而非 builtins.fetchGit：后者在求值期联网，
# 会强制整个 flake 以 --impure 求值，且网络不可达时求值直接失败。
# fetchgit 是 clone 方式，hash 对 git 内容稳定，不存在 codeload tarball
# 那种跨环境漂移的问题。
pkgs.rustPlatform.buildRustPackage (rec {
  pname = "niri-sidebar";
  version = "0.3.0-unstable-2026-08-12";

  src = pkgs.fetchgit {
    url = "https://github.com/Vigintillionn/niri-sidebar";
    rev = "954f62e7e395ae14f01af582296e25a548133dc0";
    hash = "sha256-MYP1ZiwV9+yJhl0zpuri6NQkQHlaYZjGBhXpZEaPZyI=";
  };

  cargoLock.lockFile = "${src}/Cargo.lock";

  meta = {
    description = "A lightweight, external sidebar manager for the Niri window manager";
    homepage    = "https://github.com/Vigintillionn/niri-sidebar";
    license     = pkgs.lib.licenses.mit;
    mainProgram = "niri-sidebar";
    platforms   = pkgs.lib.platforms.linux;
  };
})
