# Home Manager 用户配置入口：聚合 configuration/home/ 下的各模块
#
# 共用 let 绑定在 configuration/home/lib.nix，经 flake.nix 的
# home-manager.extraSpecialArgs 注入为 hmLib。
{ config, pkgs, lib, desktop, username, cooknixvim, bilihud, selfPackages, noctalia, bestclient, mark-shot, llm-agents-nix, ... }:

{
  imports = [
    # Noctalia V5（原生 C++ shell）HM 模块：提供 programs.noctalia 声明式配置
    # （设置/壁纸/主题模板等），替代 v4 noctalia-shell。
    noctalia.homeModules.default

    ../home/session.nix
    ../home/packages.nix
    ../home/programs.nix
    ../home/systemd.nix
    ../home/xdg.nix
    ../home/activation.nix
    ../home/files.nix
    ../home/misc.nix
  ];
}
