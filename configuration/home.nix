# Home Manager 用户配置入口：聚合 configuration/home/ 下的各模块
{ noctalia, ... }:

{
  imports = [
    # Noctalia V5（原生 C++ shell）HM 模块
    noctalia.homeModules.default

    ./home/session          # 会话变量 + systemd user 服务
    ./home/packages         # home.packages（按用途分类）
    ./home/programs.nix         # HM 程序选项（git/fish/noctalia…）
    ./home/desktop.nix          # 桌面（polkit/GTK/KDE Connect/OBS）
    ./home/xdg.nix              # xdg.configFile / xdg.dataFile
    ./home/files            # home.file + activation
  ];
}
