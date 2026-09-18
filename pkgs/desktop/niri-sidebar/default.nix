{ pkgs }:

# niri-sidebar（Rust）— https://github.com/Vigintillionn/niri-sidebar
# builtins.fetchGit：codeload tar.gz 哈希环境相关（VM 与宿主机实测不一致）
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
