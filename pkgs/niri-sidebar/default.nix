{ pkgs }:

# niri-sidebar — a lightweight, external sidebar manager for the Niri compositor.
# Upstream: https://github.com/Vigintillionn/niri-sidebar  (Rust / cargo)
# Arch AUR: niri-sidebar-git
pkgs.rustPlatform.buildRustPackage (rec {
  pname = "niri-sidebar";
  version = "0.3.0-unstable-2026-08-12";

  # 用 builtins.fetchGit（git 协议按 commit 内容寻址，免哈希、确定性）替代 fetchFromGitHub——
  # codeload 的 tar.gz 对不同网络/客户端会生成不同字节，哈希环境相关（VM 与宿主机实测不一致）。
  src = builtins.fetchGit {
    url = "https://github.com/Vigintillionn/niri-sidebar";
    rev = "954f62e7e395ae14f01af582296e25a548133dc0";
  };

  # Upstream builds with `cargo build --release --locked`; we vendor from the
  # committed Cargo.lock (buildRustPackage derives the vendor hash from it).
  cargoLock.lockFile = "${src}/Cargo.lock";

  meta = {
    description = "A lightweight, external sidebar manager for the Niri window manager";
    homepage    = "https://github.com/Vigintillionn/niri-sidebar";
    license     = pkgs.lib.licenses.mit;
    mainProgram = "niri-sidebar";
    platforms   = pkgs.lib.platforms.linux;
  };
})
