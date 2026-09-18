# Home Manager 用户配置入口：聚合 configuration/home/ 下的各模块
{ config, pkgs, lib, desktop, username, cooknixvim, bilihud, selfPackages, noctalia, bestclient, mark-shot, llm-agents-nix, ... }:

{
  imports = [
    # Noctalia V5（原生 C++ shell）HM 模块
    noctalia.homeModules.default

    ../home/session          # 会话变量 + systemd user 服务
    ../home/packages         # home.packages（按用途分类）
    ../home/programs         # HM 程序选项（git/fish/noctalia…）
    ../home/desktop          # 桌面（polkit/GTK/KDE Connect/OBS）
    ../home/xdg              # xdg.configFile / xdg.dataFile
    ../home/files            # home.file + activation
  ];
}
