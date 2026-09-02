# Tabby 终端（Electron）
# ⚠️ nixpkgs 的 `tabby` 是 TabbyML AI 助手，同名不同项目
# Electron 源码构建脆弱 → wrap 官方 release AppImage（同 splayer-next 法）
#
# wrapType2 会把 AppImage 解包到 $out/usr/share（desktop 在 usr/share/applications），
# 而 launcher/freedesktop 扫描的是 $out/share/applications → 手动补一份并修正 Exec。
{ pkgs }:

(pkgs.appimageTools.wrapType2 {
  pname = "tabby-terminal";
  version = "1.0.235";
  src = pkgs.fetchurl {
    url = "https://github.com/Eugeny/tabby/releases/download/v1.0.235/tabby-1.0.235-linux-x64.AppImage";
    sha256 = "sha256-DKXcAV/l7nhA8rIGhkzDfFL3w2t6c06GU6Oa6KV23O8=";
  };
  # Electron 终端需要 xterm 相关资源，extraPkgs 补常用运行时
  extraPkgs = pkgs: with pkgs; [ ];
}).overrideAttrs (old: {
  postInstall = (old.postInstall or "") + ''
    # wrapType2 的 desktop 在 $out/usr/share/applications（解包结构），
    # freedesktop 标准路径是 $out/share/applications → 补一份 + 修正 Exec 指向 wrapper
    binname=$(basename "$(find "$out/bin" -maxdepth 1 -type f -executable | head -1)")
    mkdir -p "$out/share/applications" "$out/share/pixmaps"
    # 图标：从 AppImage 解包内容里找
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
