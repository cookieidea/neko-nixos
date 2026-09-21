# Denial：Flutter 原生 Wayland 合成器（注册为可选登录会话，与 niri 并存）
#
# 上游为 public beta；仅在 main 分支提供 flake + NixOS 模块。
# 关键：denial 的 Flutter 引擎构建依赖其 pin 的 nixpkgs，故 flake 输入不能
# follows nixpkgs；但命中 denial.cachix.org 缓存时无需编译（实测仅需下载 ~48MiB）。
# 缓存与公钥已加在 configuration/system/nix.nix。
#
# 模块副作用（均为 mkDefault 或有开关，可覆盖）：
#   注册 sessionPackages、启用 xdg-desktop-portal（gtk/denial/wlr 截图）、
#   polkit agent、rtkit、dconf、xwayland、CJK 回退字体 source-han-sans。
{ pkgs, denial, ... }:

{
  imports = [ denial.nixosModules.default ];

  programs.denial = {
    enable = true;

    # DDC 显示器亮度控制（I2C）。本机显示器支持 DDC/CI（/dev/i2c-6 已用），
    # 若日后 I2C 冲突导致启动缓慢可置 false。
    ddc.enable = true;

    # 会话内已有其他 polkit agent 时可关；保持默认启用。
    polkitAgent.enable = true;
  };
}
