# Linux QQ 的 Wayland 修复：屏幕共享、剪贴板、截图闪退，以及语音通话
# 录音分片过大导致的延迟。上游模块同时负责安装 pkgs.qq 并接管桌面菜单项。
{ ... }:

{
  programs.linuxqq-wayland-fix.enable = true;
}
