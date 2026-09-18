# 实用工具（系统信息、磁盘/硬件、网络代理、自建程序）
{ pkgs, selfPackages, bilihud, cooknixvim, ... }:

{
  home.packages = with pkgs; [
    gdu
    baobab
    file                                      # file 命令（random-anime-wallpaper-noctalia 壁纸脚本依赖）
    mission-center                            # mission-center
    gnome-font-viewer                         # gnome-font-viewer
    virt-manager virt-viewer                  # KVM 虚拟机 GUI
    gnome-disk-utility                        # 磁盘管理 GUI
    usbutils
    pciutils
    wineWow64Packages.stable                   # wine（原 99-apps 的 wine 全家；26.05 弃用 wineWowPackages）
    icoextract                                 # Windows exe/ico 图标缩略图（原 FM_PKGS1）
    pipewire                                   # 提供 pw-play（截图/强杀音效脚本依赖；服务已在 configuration.nix 开启）
    flclash                                   # 代理 GUI
    ayugram-desktop                           # Telegram 第三方客户端
    selfPackages.niri-sidebar     # niri-sidebar-git
    selfPackages.nyxniri-scratch-menu  # NyxNiri 星环菜单（GTK3+LayerShell，Super+A）
    selfPackages.pins
    selfPackages.shorin-contrib   # shorin-contrib-git
    selfPackages.splayer-next     # SPlayer-Dev/SPlayer-Next（非 nixpkgs 的 splayer）
    selfPackages.ab-download-manager  # AB Download Manager（多线程下载器，Compose Desktop；自构建）
    selfPackages.tabby-terminal       # Tabby 终端（eugeny/tabby，Electron；自构建，nixpkgs 的 tabby 是 TabbyML AI 助手）
    (pkgs.writeShellScriptBin "hmcl" ''
      export SDL_VIDEO_DRIVER=wayland
      export LD_PRELOAD="${pkgs.stdenv.cc.cc.lib}/lib/libstdc++.so.6''${LD_PRELOAD:+:$LD_PRELOAD}"
      exec ${pkgs.hmcl}/bin/hmcl "$@"
    '')
    (pkgs.runCommand "hmcl-assets" { } ''
      mkdir -p $out/share
      cp -r ${pkgs.hmcl}/share/applications $out/share/
      cp -r ${pkgs.hmcl}/share/icons $out/share/
    '')
    selfPackages.astral               # Astral 组网客户端（Flutter+Rust；bundle 由 pkgs/astral/build.sh 联网构建）
    bilihud.packages.${pkgs.stdenv.hostPlatform.system}.default  # B 站直播弹幕阅读器（PyQt6 + layer-shell 全屏浮窗）
    cooknixvim.packages.${pkgs.stdenv.hostPlatform.system}.default        # nvim（CookNixvim）
  ];
}
