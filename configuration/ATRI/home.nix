# Home Manager 用户配置入口：聚合 configuration/home/ 下的各模块
{ config, pkgs, lib, desktop, username, cooknixvim, bilihud, selfPackages, noctalia, bestclient, mark-shot, llm-agents-nix, ... }:

{
  imports = [
    # Noctalia V5（原生 C++ shell）HM 模块
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
