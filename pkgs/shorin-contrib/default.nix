{ pkgs }:

# shorin-contrib — SHORiN's collection of helper shell scripts.
# Upstream: https://github.com/SHORiN-KiWATA/shorin-contrib
# Arch AUR: shorin-contrib-git
#
# NOTE: the `shorin link` meta-command referenced by the original Arch setup is
# NOT part of this repo (there is no `shorin` script in it). Install the
# individual scripts you need and call them directly, e.g. `shorin-contrib/clean`.
pkgs.stdenv.mkDerivation {
  pname = "shorin-contrib";
  version = "unstable-2026-08-12";

  src = pkgs.fetchFromGitHub {
    owner = "SHORiN-KiWATA";
    repo  = "shorin-contrib";
    rev   = "1a7cc34c54dd734c64ed4fd202c74ffaf7c26ec1";
    sha256 = "sha256-d6419eb62b3c4e9b8ca610084d5abfb61a5dac216e755b4c9681c4f25ec27249";
  };

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/bin" "$out/share/shorin-contrib"
    find . -type f -not -path './.git/*' | while read -r f; do
      rel="''${f#./}"
      if head -c2 "$f" | grep -q '#!'; then
        install -Dm755 "$f" "$out/share/shorin-contrib/$rel"
        ln -sf "$out/share/shorin-contrib/$rel" "$out/bin/$(basename "$rel")"
      fi
    done
    runHook postInstall
  '';

  meta = {
    description = "SHORiN's contribute scripts";
    homepage    = "https://github.com/SHORiN-KiWATA/shorin-contrib";
    license     = "see https://github.com/SHORiN-KiWATA/shorin-contrib";
    platforms   = pkgs.lib.platforms.linux;
  };
}
