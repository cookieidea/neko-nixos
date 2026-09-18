{ pkgs }:

# shorin-contrib 通用脚本子集
pkgs.stdenv.mkDerivation {
  pname = "shorin-contrib";
  version = "unstable-2026-08-24";

  src = builtins.fetchGit {
    url = "https://github.com/SHORiN-KiWATA/shorin-contrib";
    rev = "c6a768a045a512148f5d99f90190a503f9b5037f";
  };

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/bin" "$out/share/shorin-contrib"
    for f in others/* terminal/lsi system/procusage system/timer; do
      [ -f "$f" ] || continue
      install -Dm755 "$f" "$out/share/shorin-contrib/$f"
      ln -sf "$out/share/shorin-contrib/$f" "$out/bin/$(basename "$f")"
    done
    runHook postInstall
  '';

  meta = {
    description = "SHORiN's contribute scripts (generic subset for NixOS)";
    homepage    = "https://github.com/SHORiN-KiWATA/shorin-contrib";
    license     = "see https://github.com/SHORiN-KiWATA/shorin-contrib";
    platforms   = pkgs.lib.platforms.linux;
  };
}