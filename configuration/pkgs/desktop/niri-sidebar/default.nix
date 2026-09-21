{ pkgs }:

# niri-sidebar（Rust）。
# 使用 builtins.fetchGit，避免 codeload tarball hash 在不同环境间漂移。
pkgs.rustPlatform.buildRustPackage (rec {
  pname = "niri-sidebar";
  version = "0.3.0-unstable-2026-08-12";

  src = builtins.fetchGit {
    url = "https://github.com/Vigintillionn/niri-sidebar";
    rev = "954f62e7e395ae14f01af582296e25a548133dc0";
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
