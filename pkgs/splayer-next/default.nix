{ pkgs }:

# SPlayer-Next（跨平台音乐播放器，Electron + Vue3 + Rust）
# ⚠️ 非 nixpkgs 的 `splayer`（同名的另一个项目）
# "Simple Netease Cloud Music player"). This is SPlayer-Dev/SPlayer-Next, the
# real app the original Arch setup intended via the AUR `splayer-next-git`.
#
# Building an Electron app reproducibly from source in Nix is fragile: it needs
# an FHS build env, a system Electron, and prebuilt Rust native modules
# (audio-engine / media-ctrl / taskbar-lyric). The reliable, working approach
# used here is to wrap the official release AppImage with `appimage-run`.
#
# To build from source instead, use the AUR `splayer-next-git` PKGBUILD as a
# reference and adapt it into a `pkgs.buildFHSUserEnv` derivation — but expect
# to iterate (electron version pin, ffmpeg patch, native module compile).
(pkgs.appimageTools.wrapType2 {
  pname = "splayer-next";
  version = "1.0.0";
  src = pkgs.fetchurl {
    url = "https://github.com/SPlayer-Dev/SPlayer-Next/releases/download/v1.0.0/splayer-next-1.0.0-x86_64.AppImage";
    sha256 = "sha256-11aQDxg76QtHG8cuRFGZRb5is1Ne5YercPXaI8la9Ug=";
  };
  extraPkgs = pkgs: with pkgs; [ ffmpeg ];
}).overrideAttrs (old: {
  postInstall = (old.postInstall or "") + ''
    # wrapType2 的 desktop 在 $out/usr/share/applications（解包结构），
    # freedesktop 标准路径是 $out/share/applications → 补一份 + 修正 Exec 指向 wrapper
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
