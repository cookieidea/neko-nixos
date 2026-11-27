# Wayland 工具（截图、通知、X11 兼容等）
{ pkgs, mark-shot, ... }:

let
  # 上游 Cargo.toml 没声明 onig（onig_sys）需要的系统库，0.2.5 起构建会因为
  # 找不到 oniguruma.pc 直接失败。这里补上。
  markShot = (mark-shot.packages.${pkgs.stdenv.hostPlatform.system}.default).overrideAttrs (old: {
    buildInputs = (old.buildInputs or [ ]) ++ [ pkgs.oniguruma ];
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.pkg-config ];
  });
in
{
  home.packages = with pkgs; [
    markShot # 截图标注 + OCR（为 niri 设计）
    zenity
    xdg-terminal-exec
    libnotify
    xsettingsd
    xprop
    xhost
  ];
}
