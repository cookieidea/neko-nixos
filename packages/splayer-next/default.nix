{ pkgs }:

# SPlayer-Next（Electron 音乐播放器；⚠️ 非 nixpkgs 的 `splayer`）
# wrap 官方 release AppImage（Electron 源码构建脆弱）
(pkgs.appimageTools.wrapType2 {
  pname = "splayer-next";
  version = "1.1.0";
  src = pkgs.fetchurl {
    url = "https://github.com/SPlayer-Dev/SPlayer-Next/releases/download/v1.1.0/splayer-next-1.1.0-x86_64.AppImage";
    sha256 = "sha256-ycwZdd5LPM16y9bPuFfSfYlxWun19bmbO1EerDBcURY=";
  };
  extraPkgs = pkgs: with pkgs; [ ffmpeg ];
}).overrideAttrs (old: {
  postInstall = (old.postInstall or "") + ''
    # wrapType2 的 desktop 在 $out/usr/share/applications → 补标准路径 + 修 Exec
    binname=$(basename "$(find "$out/bin" -maxdepth 1 -type f -executable | head -1)")
    mkdir -p "$out/share/applications" "$out/share/pixmaps"
    icon=$(find "$out" -path "*icons*" -name "*.png" 2>/dev/null | head -1)
    if [ -n "$icon" ]; then
      cp "$icon" "$out/share/pixmaps/splayer-next.png"
    fi
    cat > "$out/share/applications/splayer-next.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=SPlayer-Next
Comment=Cross-platform desktop music player
Exec=$binname
Icon=splayer-next
Terminal=false
Categories=AudioVideo;Audio;Player;
StartupWMClass=splayer-next
EOF
  '';
})
