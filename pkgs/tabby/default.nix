# Tabby 终端（Electron；⚠️ nixpkgs 的 `tabby` 是 TabbyML，同名不同项目）
# wrap 官方 release AppImage；postInstall 补 freedesktop 标准路径的 desktop
{ pkgs }:

(pkgs.appimageTools.wrapType2 {
  pname = "tabby-terminal";
  version = "1.0.235";
  src = pkgs.fetchurl {
    url = "https://github.com/Eugeny/tabby/releases/download/v1.0.235/tabby-1.0.235-linux-x64.AppImage";
    sha256 = "sha256-DKXcAV/l7nhA8rIGhkzDfFL3w2t6c06GU6Oa6KV23O8=";
  };
  extraPkgs = pkgs: with pkgs; [ ];
}).overrideAttrs (old: {
  postInstall = (old.postInstall or "") + ''
    # wrapType2 的 desktop 在 $out/usr/share/applications → 补标准路径 + 修 Exec
    binname=$(basename "$(find "$out/bin" -maxdepth 1 -type f -executable | head -1)")
    mkdir -p "$out/share/applications" "$out/share/pixmaps"
    icon=$(find "$out" -path "*icons*" -name "*.png" 2>/dev/null | head -1)
    if [ -n "$icon" ]; then
      cp "$icon" "$out/share/pixmaps/tabby.png"
    fi
    cat > "$out/share/applications/tabby.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Tabby
Name[zh_CN]=Tabby 终端
Comment=Terminal emulator
Exec=$binname
Icon=tabby
Terminal=false
Categories=System;TerminalEmulator;
StartupWMClass=tabby
EOF
  '';
})
