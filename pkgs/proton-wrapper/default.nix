{ pkgs }:

# shorin-proton-wrapper — a simple wrapper to run EXE files via Proton (Steam).
# Upstream: https://github.com/SHORiN-KiWATA/proton-wrapper
# Arch AUR: shorin-proton-wrapper-git
pkgs.stdenv.mkDerivation {
  pname = "shorin-proton-wrapper";
  version = "unstable-2026-08-12";

  src = builtins.fetchGit {
    url = "https://github.com/SHORiN-KiWATA/proton-wrapper";
    rev = "7e70126ecae420f00783d0375b72451c06956549";
  };

  nativeBuildInputs = [ pkgs.makeWrapper ];

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/bin" "$out/share/applications" "$out/share/icons/hicolor/256x256/apps"
    for s in shorin-proton-wrapper shorin-proton-wrapper-configure shorin-proton-wrapper-manager; do
      install -Dm755 "$s" "$out/bin/$s"
    done
    install -Dm644 *.desktop -t "$out/share/applications/" 2>/dev/null || true
    # 图标必须放 hicolor/<size>/apps/ 结构才会被图标主题扫描；
    # 之前 cp 到 hicolor/ 根目录（找不到，desktop Icon=shorin-proton 无图）
    [ -d icons ] && cp icons/*.png "$out/share/icons/hicolor/256x256/apps/" 2>/dev/null || true
    runHook postInstall
  '';

  meta = {
    description = "A simple wrapper to run EXEs via Proton";
    homepage    = "https://github.com/SHORiN-KiWATA/proton-wrapper";
    license     = "see https://github.com/SHORiN-KiWATA/proton-wrapper";
    mainProgram = "shorin-proton-wrapper";
    platforms   = pkgs.lib.platforms.linux;
  };
}
