# nixpkgs overlays 列表（供 flake 与 NixOS 模块共用）。
#
# 抽成独立文件的原因：flake.nix 需要用它构造自己的 pkgs 实例，而 NixOS 的
# nixpkgs.overlays 选项只在 module 系统里可见 —— 两边必须用同一份定义，
# 否则会退化成「两个 pkgs 实例配置不一致」（hmLib/selfPackages 走 flake pkgs，
# 系统与 Home Manager 走 NixOS pkgs）。
#
# 返回 overlay 列表（每个元素为 final: prev: {...} 形式的函数）。
{ nix-cachyos-kernel }:

[
  # CachyOS RT-BORE 内核。用上游 pinned overlay 才能命中其二进制缓存；
  # 该 input 刻意不 follows nixpkgs（见 flake.nix 注释）。
  nix-cachyos-kernel.overlays.pinned

  # 覆盖 neovim 的 nvim.desktop：
  # 上游为 Terminal=true，图形启动器点不开（freedesktop 规范下会尝试在终端
  # 里跑 GUI 程序）。改为 kitty 打开，MimeType 与用户级覆盖保持一致。
  (_final: prev: {
    neovim = prev.neovim.overrideAttrs (old: {
      postInstall = (old.postInstall or "") + ''
        rm -f "$out/share/applications/nvim.desktop"
        cat > "$out/share/applications/nvim.desktop" <<'DESKTOP'
[Desktop Entry]
Name=Neovim wrapper
GenericName=Text Editor
Comment=Edit text files
TryExec=nvim
Exec=kitty -e nvim %F
Icon=nvim
Type=Application
Terminal=false
Categories=Utility;TextEditor;Development;
MimeType=text/plain;text/x-makefile;application/x-shellscript;text/x-c;text/x-c++src;
StartupNotify=false
DESKTOP
      '';
    });
  })
]
