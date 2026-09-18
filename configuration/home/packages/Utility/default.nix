# 实用工具（系统信息、磁盘/硬件、网络代理、自建程序）
{ pkgs, selfPackages, bilihud, cooknixvim, ... }:

{
  home.packages = with pkgs; [
    gdu
    baobab
    file
    mission-center
    gnome-font-viewer
    virt-manager virt-viewer                  # KVM 虚拟机 GUI
    gnome-disk-utility                        # 磁盘管理 GUI
    usbutils
    pciutils
    wineWow64Packages.stable                   # wine
    icoextract                                 # Windows exe/ico 图标缩略图
    pipewire                                   # 提供 pw-play
    flclash                                   # 代理 GUI
    ayugram-desktop                           # Telegram 第三方客户端
    selfPackages.niri-sidebar     # niri-sidebar-git
    selfPackages.nyxniri-scratch-menu  # NyxNiri 星环菜单（Super+A）
    selfPackages.pins
    selfPackages.shorin-contrib
    selfPackages.splayer-next     # SPlayer-Next
    selfPackages.ab-download-manager  # AB Download Manager（多线程下载器）
    selfPackages.tabby-terminal       # Tabby 终端（Electron，自构建）
    selfPackages.astral               # Astral 组网客户端
    bilihud.packages.${pkgs.stdenv.hostPlatform.system}.default  # B 站直播弹幕阅读器
    cooknixvim.packages.${pkgs.stdenv.hostPlatform.system}.default        # nvim（CookNixvim）
  ];
}
