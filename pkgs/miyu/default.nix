{ pkgs }:

# Miyu — SHORiN's AI assistant (Rust).
# Upstream: https://github.com/SHORiN-KiWATA/Miyu
# Arch AUR: miyu
#
# Native dependencies:
#   - syntect (regex-onig feature) -> oniguruma
#   - rodio (audio playback)       -> alsa-lib
#   - cosmic-text / fontdb          -> fontconfig
# Requires a recent Rust toolchain (Cargo.toml: rust-version = "1.89").
pkgs.rustPlatform.buildRustPackage {
  pname = "miyu";
  version = "0.4.0-unstable-2026-08-12";

  src = pkgs.fetchFromGitHub {
    owner = "SHORiN-KiWATA";
    repo  = "Miyu";
    rev   = "58dba4025da4af9e3b0f84f0e39a4188ec9a446a";
    sha256 = "sha256-cc4f7866d6cda9c8e31ac17fbc81ac50db5ccc97ac40f3436f2128bf07d4b519";
  };

  cargoLock.lockFile = "${src}/Cargo.lock";

  nativeBuildInputs = [ pkgs.pkg-config ];
  buildInputs = [ pkgs.oniguruma pkgs.alsa-lib pkgs.fontconfig ];

  # Miyu embeds its resources (kb/, resources/, web/, ...) at build time via
  # build.rs, so no runtime data path needs to be set. Ship them for reference.
  postInstall = ''
    for d in kb resources assets pics web; do
      [ -d "$d" ] && mkdir -p "$out/share/miyu" && cp -r "$d" "$out/share/miyu/"
    done
  '';

  meta = {
    description = "Miyu — an AI assistant";
    homepage    = "https://github.com/SHORiN-KiWATA/Miyu";
    license     = "see https://github.com/SHORiN-KiWATA/Miyu/blob/main/LICENSE";
    mainProgram = "miyu";
    platforms   = pkgs.lib.platforms.linux;
  };
}
