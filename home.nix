# Home Manager 用户配置入口（聚合 modules/home/ 下的各模块）
#
# 原 984 行单文件按职责拆分；共用 let 绑定移入 modules/home/lib.nix，
# 经 flake.nix 的 home-manager.extraSpecialArgs 注入为 hmLib。
{ config, pkgs, lib, desktop, username, cooknixvim, bilihud, selfPackages, noctalia, bestclient, mark-shot, llm-agents-nix, ... }:

{
  imports = [
    # Noctalia V5（原生 C++ shell）HM 模块：提供 programs.noctalia 声明式配置
    # （设置/壁纸/主题模板等），替代 v4 noctalia-shell。
    noctalia.homeModules.default

    ./modules/home/session.nix
    ./modules/home/packages.nix
    ./modules/home/programs.nix
    ./modules/home/systemd.nix
    ./modules/home/xdg.nix
    ./modules/home/activation.nix
    ./modules/home/files.nix
    ./modules/home/misc.nix
  ];
}
