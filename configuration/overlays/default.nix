# nixpkgs overlays（从 flake.nix 拆出）
#
# 以 NixOS module 形式提供 overlays —— 因为 overlay 必须作用于
# `nixpkgs.overlays`（pkgs 实例），而该选项只在 module 系统里可见。
{ nix-cachyos-kernel, ... }:

{
  nixpkgs.overlays = [
    # CachyOS RT-BORE 内核。用上游 pinned overlay 才能命中其二进制缓存；
    # 注意该 input 刻意不 follows nixpkgs（见 flake.nix 注释）
    nix-cachyos-kernel.overlays.pinned

    # 覆盖 neovim 的 nvim.desktop
    # 上游：Terminal=true → 图形启动器点不开（freedesktop 规范下会尝试在
    # 终端里跑 GUI 程序）。此处改为 kitty 打开，并让 MimeType 与
    # files/default.nix 里的用户级覆盖保持一致。
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
  ];
}
