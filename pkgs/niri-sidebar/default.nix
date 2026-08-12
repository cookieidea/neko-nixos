{ pkgs }:

# niri-sidebar — a lightweight, external sidebar manager for the Niri compositor.
# Upstream: https://github.com/Vigintillionn/niri-sidebar  (Rust / cargo)
# Arch AUR: niri-sidebar-git
pkgs.rustPlatform.buildRustPackage {
  pname = "niri-sidebar";
  version = "0.3.0-unstable-2026-08-12";

  src = pkgs.fetchFromGitHub {
    owner = "Vigintillionn";
    repo  = "niri-sidebar";
    rev   = "954f62e7e395ae14f01af582296e25a548133dc0";
    sha256 = "sha256-AJN43lsR24n0sd/8FvQOSksGaJpttQ6FzjeI2B+PgQ0=";
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
}
