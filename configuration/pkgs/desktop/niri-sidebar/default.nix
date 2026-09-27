{ pkgs }:

# niri-sidebar（Rust）。
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
