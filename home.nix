# Shorin Arch Setup → Home Manager user config
# 包来源：
#   common-applist.txt          (GNOME 基线)
#   kde-applist.txt             (shell/终端 + KDE 应用)
#   kde-common-applist.txt      (KDE 系统工具/磁盘/媒体)
# 桌面：niri (Wayland 滚动平铺 compositor) + Noctalia (桌面 shell)
# 编辑器：nixvim（替代 neovim + lazyvim）
# AUR-only 与 nixpkgs 差异见底部注释。

{ config, pkgs, lib, desktop, username, nixvim, noctalia, opencode, ... }:

{
  imports = [
    nixvim.homeModules.nixvim        # nixvim（Neovim 配置框架）
    # Noctalia 改用 flake 包（见 home.packages）+ settings.json（见 xdg.configFile），
    # 不再加载它的 HM 模块，避免 programs.noctalia.settings 和手写文件冲突。
  ];

  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "26.05";

  # ============================================================
  #  软件包（home.packages）
  #  左 = Nixpkgs 属性名，括号内 = 原 Arch 包名
  # ============================================================
  home.packages = with pkgs; [
    # --- Standard (common-applist.txt) ---
    gdu                                       # gdu
    baobab                                    # baobab
    mission-center                            # mission-center
    gnome-font-viewer                         # gnome-font-viewer
    firefox                                   # firefox
    transmission-gtk                          # transmission-gtk
    localsend                                 # localsend
    gnome-calendar                            # gnome-calendar
    gnome-clocks                              # gnome-clocks
    lutris                                    # lutris
    steam                                     # steam (系统服务在 configuration.nix)
    mangohud                                  # mangohud
    mpv                                       # mpv
    obs-studio                                # obs-studio
    upscaler                                  # upscaler
    yazi                                      # yazi
    flatseal                                  # flatseal
    pavucontrol                               # pavucontrol
    mousepad                                  # mousepad
    easyeffects                               # easyeffects
    fcitx5-mozc                               # fcitx5-mozc (日语)
    rime-wubi                                 # rime-wubi (五笔)

    # --- Shell & Terminal (kde-applist.txt) ---
    fish                                      # fish
    starship                                  # starship
    eza                                       # eza
    zoxide                                    # zoxide
    fastfetch                                 # fastfetch
    imagemagick                               # imagemagick
    jq                                        # jq
    timg                                      # timg
    bat                                       # bat
    btop                                      # btop（DE 无关，常驻）

    # --- 编辑器（替代 visual-studio-code-bin，AUR）---
    vscodium                                  # visual-studio-code-bin → 用 vscodium 去遥测

    # --- 已确认在 nixpkgs 26.05 存在的原 AUR 包 ---
    flclash                                   # flclash（代理 GUI）
    wechat                                    # wechat（腾讯官方原生 Linux 版，unfree，需 allowUnfree）
    qq                                        # qq（腾讯官方原生 Linux 版，unfree，需 allowUnfree）
    gearlever                                 # gearlever（管理 AppImage/flatpak）
    lsfg-vk                                   # lsfg-vk（FSR 帧生成 vulkan 层）
    protonplus                                # protonplus（Proton 管理）
    mangojuice                                # mangojuice（GTK 文件管理器）
    rime-wanxiang                             # rime-wanxiang（万象输入法词库）

    # --- 游戏 / 影音客户端（用户新增，已在 nixpkgs 26.05 核实存在）---
    hmcl                                      # hmcl（Minecraft 启动器，开源 GPL）
    animeko                                   # animeko（一站式追番/看番平台，开源 AGPL-3.0；替代原计划的 kazumi）
    lunarclient                                # lunarclient（Minecraft 客户端，unfree，allowUnfree 已在 configuration.nix 开启）
    taterclient-ddnet                         # taterclient-ddnet（DDNet Teeworlds 修改版客户端，Apache-2.0）

    # --- 原清单里有、之前漏加的 ---
    virt-manager                              # virt-manager（KVM 虚拟机 GUI，libvirtd 已在 configuration.nix 开）
    video-downloader                          # video-downloader（yt-dlp 图形前端）

    # --- niri 桌面生态依赖（config.kdl / binds.kdl 里用到的程序）---
    niri                                       # niri 合成器本体（greetd 直接调，也放这里保持 PATH 一致）
    kitty                                      # 终端（binds: Mod+Return / Mod+T / Mod+Slash / opencode）
    fuzzel                                     # 启动器兜底（binds: Mod+Z 失败回退 fuzzel）
    thunar                                     # 文件管理器（binds: Mod+E）
    satty                                      # 截图标注（binds: Mod+Shift+S）
    cliphist                                   # 剪贴板历史（noctalia config.toml 的 clipboard watch 命令）
    wl-clipboard                               # wl-paste / wl-copy（剪贴板 + 截图管道）
    xsettingsd                                 # GTK 主题/字体经 XSETTINGS 注入应用（niri 无 DE 时需要）
  ];

  # opencode（AI 编程 Agent）走 flake 装，拿最新版（不在 nixpkgs 核心）
  # noctalia（桌面 shell）同样走 flake 包
  ++ [
    opencode.packages.${pkgs.stdenv.hostPlatform.system}.default
    noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  # ============================================================
  #  Home Manager 托管的程序（自动写 dotfiles，替代手写配置）
  # ============================================================
  programs = {
    git = {
      enable = true;
      userName = "yourname";      # 改
      userEmail = "you@example.com"; # 改
    };
    starship.enable = true;       # starship
    zoxide.enable = true;         # zoxide
    eza.enable = true;            # eza
    bat.enable = true;            # bat
    fzf.enable = true;            # fzf（脚本里也装了）
    fish = {
      enable = true;
    };

    # ── nixvim：替代 neovim + lazyvim ─────────────────────
    # 在这里用 Nix 写 Neovim 配置（插件/配色/按键），不再需要 lazyvim。
    nixvim = {
      enable = true;
      # 示例：catppuccin 配色 + lualine 状态栏
      colorschemes.catppuccin.enable = true;
      plugins.lualine.enable = true;
      opts = {
        number = true;
        relativenumber = true;
        shiftwidth = 2;
        tabstop = 2;
      };
      # 想加插件：plugins.<name>.enable = true；
      # 想加原生 lua：extraConfigLua = '' ... '';
    };

    # ── niri：Wayland 滚动平铺 compositor ────────────────
    # 配置改用 dotfiles/niri/*.kdl，通过文件末尾的 xdg.configFile 部署，
    # 不再用 programs.niri.settings 生成，以免和手写的拆分 kdl 冲突。
  };

  # ============================================================
  #  Noctalia 桌面 shell（niri 之上的一层）
  #  用 flake 提供的 noctalia 包（见 home.packages）+ config.toml（v5 的 TOML 配置）
  #  通过 xdg.configFile 部署到 ~/.config/noctalia/config.toml
  #  （v5 不再读 v4 的 settings.json/plugins.json/colors.json；不用 programs.noctalia.settings）
  # ============================================================

  # ============================================================
  #  dotfiles（对应原仓库 noctalia-dotfiles 的 rice 配置）
  #  通过 xdg.configFile 部署到 ~/.config/
  # ============================================================
  xdg.configFile = {
    "Thunar/accels.scm".source = ./dotfiles/config/Thunar/accels.scm;
    "Thunar/uca.xml".source = ./dotfiles/config/Thunar/uca.xml;
    "fcitx5/conf/cached_layouts".source = ./dotfiles/config/fcitx5/conf/cached_layouts;
    "fcitx5/conf/chttrans.conf".source = ./dotfiles/config/fcitx5/conf/chttrans.conf;
    "fcitx5/conf/classicui.conf".source = ./dotfiles/config/fcitx5/conf/classicui.conf;
    "fcitx5/conf/notifications.conf".source = ./dotfiles/config/fcitx5/conf/notifications.conf;
    "fcitx5/conf/pinyin.conf".source = ./dotfiles/config/fcitx5/conf/pinyin.conf;
    "fcitx5/conf/punctuation.conf".source = ./dotfiles/config/fcitx5/conf/punctuation.conf;
    "fcitx5/config".source = ./dotfiles/config/fcitx5/config;
    "fcitx5/profile".source = ./dotfiles/config/fcitx5/profile;
    "fish/conf.d/shorin.fish".source = ./dotfiles/config/fish/conf.d/shorin.fish;
    "fish/fish_variables".source = ./dotfiles/config/fish/fish_variables;
    "fish/functions/apt.fish".source = ./dotfiles/config/fish/functions/apt.fish;
    "fish/functions/f.fish".source = ./dotfiles/config/fish/functions/f.fish;
    "fish/functions/fwatch.fish".source = ./dotfiles/config/fish/functions/fwatch.fish;
    "fontconfig/fonts.conf".source = ./dotfiles/config/fontconfig/fonts.conf;
    "fuzzel/fuzzel.ini".source = ./dotfiles/config/fuzzel/fuzzel.ini;
    "fuzzel/themes/noctalia".source = ./dotfiles/config/fuzzel/themes/noctalia;
    "gtk-3.0/bookmarks".source = ./dotfiles/config/gtk-3.0/bookmarks;
    "gtk-3.0/gtk.css".source = ./dotfiles/config/gtk-3.0/gtk.css;
    "gtk-3.0/noctalia.css".source = ./dotfiles/config/gtk-3.0/noctalia.css;
    "gtk-3.0/settings.ini".source = ./dotfiles/config/gtk-3.0/settings.ini;
    "gtk-4.0/gtk.css".source = ./dotfiles/config/gtk-4.0/gtk.css;
    "gtk-4.0/noctalia.css".source = ./dotfiles/config/gtk-4.0/noctalia.css;
    "gtk-4.0/settings.ini".source = ./dotfiles/config/gtk-4.0/settings.ini;
    "kitty/current-theme.conf".source = ./dotfiles/config/kitty/current-theme.conf;
    "kitty/kitty.conf".source = ./dotfiles/config/kitty/kitty.conf;
    "kitty/themes/kitty.conf".source = ./dotfiles/config/kitty/themes/kitty.conf;
    "kitty/themes/noctalia.conf".source = ./dotfiles/config/kitty/themes/noctalia.conf;
    "mimeapps.list".source = ./dotfiles/config/mimeapps.list;
    "mpv/config".source = ./dotfiles/config/mpv/config;
    "niri/animations.kdl".source = ./dotfiles/config/niri/animations.kdl;
    "niri/binds.kdl".source = ./dotfiles/config/niri/binds.kdl;
    "niri/blur.kdl".source = ./dotfiles/config/niri/blur.kdl;
    "niri/config.kdl".source = ./dotfiles/config/niri/config.kdl;
    "niri/cursor.kdl".source = ./dotfiles/config/niri/cursor.kdl;
    "niri/layout.kdl".source = ./dotfiles/config/niri/layout.kdl;
    "niri/noctalia.kdl".source = ./dotfiles/config/niri/noctalia.kdl;
    "niri/outputs.kdl".source = ./dotfiles/config/niri/outputs.kdl;
    "niri/supertab.kdl".source = ./dotfiles/config/niri/supertab.kdl;
    "niri/windowrules.kdl".source = ./dotfiles/config/niri/windowrules.kdl;
    # v5 配置（TOML）：替代 v4 的 settings.json/plugins.json/colors.json
    "noctalia/config.toml".source = ./dotfiles/config/noctalia/config.toml;
    "noctalia/templates/btop.theme".source = ./dotfiles/config/noctalia/templates/btop.theme;
    "noctalia/templates/cava-colors.ini".source = ./dotfiles/config/noctalia/templates/cava-colors.ini;
    "noctalia/templates/fastfetch-config.jsonc".source = ./dotfiles/config/noctalia/templates/fastfetch-config.jsonc;
    "noctalia/templates/fcitx5-theme.conf".source = ./dotfiles/config/noctalia/templates/fcitx5-theme.conf;
    "noctalia/templates/fuzzel.ini".source = ./dotfiles/config/noctalia/templates/fuzzel.ini;
    "noctalia/templates/gtk-folder/Adwaita-Matugen/index.theme".source = ./dotfiles/config/noctalia/templates/gtk-folder/Adwaita-Matugen/index.theme;
    "noctalia/templates/gtk-folder/Adwaita-Matugen/scalable/mimetypes/application-x-addon.svg".source = ./dotfiles/config/noctalia/templates/gtk-folder/Adwaita-Matugen/scalable/mimetypes/application-x-addon.svg;
    "noctalia/templates/gtk-folder/Adwaita-Matugen/scalable/mimetypes/application-x-executable.svg".source = ./dotfiles/config/noctalia/templates/gtk-folder/Adwaita-Matugen/scalable/mimetypes/application-x-executable.svg;
    "noctalia/templates/gtk-folder/Adwaita-Matugen/scalable/mimetypes/audio-x-generic.svg".source = ./dotfiles/config/noctalia/templates/gtk-folder/Adwaita-Matugen/scalable/mimetypes/audio-x-generic.svg;
    "noctalia/templates/gtk-folder/Adwaita-Matugen/scalable/mimetypes/font-x-generic.svg".source = ./dotfiles/config/noctalia/templates/gtk-folder/Adwaita-Matugen/scalable/mimetypes/font-x-generic.svg;
    "noctalia/templates/gtk-folder/Adwaita-Matugen/scalable/mimetypes/inode-directory.svg".source = ./dotfiles/config/noctalia/templates/gtk-folder/Adwaita-Matugen/scalable/mimetypes/inode-directory.svg;
    "noctalia/templates/gtk-folder/Adwaita-Matugen/scalable/mimetypes/text-html.svg".source = ./dotfiles/config/noctalia/templates/gtk-folder/Adwaita-Matugen/scalable/mimetypes/text-html.svg;
    "noctalia/templates/gtk-folder/Adwaita-Matugen/scalable/mimetypes/text-x-script.svg".source = ./dotfiles/config/noctalia/templates/gtk-folder/Adwaita-Matugen/scalable/mimetypes/text-x-script.svg;
    "noctalia/templates/gtk-folder/Adwaita-Matugen/scalable/mimetypes/x-office-document.svg".source = ./dotfiles/config/noctalia/templates/gtk-folder/Adwaita-Matugen/scalable/mimetypes/x-office-document.svg;
    "noctalia/templates/gtk-folder/Adwaita-Matugen/scalable/mimetypes/x-office-presentation.svg".source = ./dotfiles/config/noctalia/templates/gtk-folder/Adwaita-Matugen/scalable/mimetypes/x-office-presentation.svg;
    "noctalia/templates/gtk-folder/Adwaita-Matugen/scalable/places/folder-documents.svg".source = ./dotfiles/config/noctalia/templates/gtk-folder/Adwaita-Matugen/scalable/places/folder-documents.svg;
    "noctalia/templates/gtk-folder/Adwaita-Matugen/scalable/places/folder-download.svg".source = ./dotfiles/config/noctalia/templates/gtk-folder/Adwaita-Matugen/scalable/places/folder-download.svg;
    "noctalia/templates/gtk-folder/Adwaita-Matugen/scalable/places/folder-drag-accept.svg".source = ./dotfiles/config/noctalia/templates/gtk-folder/Adwaita-Matugen/scalable/places/folder-drag-accept.svg;
    "noctalia/templates/gtk-folder/Adwaita-Matugen/scalable/places/folder-music.svg".source = ./dotfiles/config/noctalia/templates/gtk-folder/Adwaita-Matugen/scalable/places/folder-music.svg;
    "noctalia/templates/gtk-folder/Adwaita-Matugen/scalable/places/folder-pictures.svg".source = ./dotfiles/config/noctalia/templates/gtk-folder/Adwaita-Matugen/scalable/places/folder-pictures.svg;
    "noctalia/templates/gtk-folder/Adwaita-Matugen/scalable/places/folder-publicshare.svg".source = ./dotfiles/config/noctalia/templates/gtk-folder/Adwaita-Matugen/scalable/places/folder-publicshare.svg;
    "noctalia/templates/gtk-folder/Adwaita-Matugen/scalable/places/folder-remote.svg".source = ./dotfiles/config/noctalia/templates/gtk-folder/Adwaita-Matugen/scalable/places/folder-remote.svg;
    "noctalia/templates/gtk-folder/Adwaita-Matugen/scalable/places/folder-templates.svg".source = ./dotfiles/config/noctalia/templates/gtk-folder/Adwaita-Matugen/scalable/places/folder-templates.svg;
    "noctalia/templates/gtk-folder/Adwaita-Matugen/scalable/places/folder-videos.svg".source = ./dotfiles/config/noctalia/templates/gtk-folder/Adwaita-Matugen/scalable/places/folder-videos.svg;
    "noctalia/templates/gtk-folder/Adwaita-Matugen/scalable/places/folder.svg".source = ./dotfiles/config/noctalia/templates/gtk-folder/Adwaita-Matugen/scalable/places/folder.svg;
    "noctalia/templates/gtk-folder/Adwaita-Matugen/scalable/places/network-server.svg".source = ./dotfiles/config/noctalia/templates/gtk-folder/Adwaita-Matugen/scalable/places/network-server.svg;
    "noctalia/templates/gtk-folder/Adwaita-Matugen/scalable/places/network-workgroup.svg".source = ./dotfiles/config/noctalia/templates/gtk-folder/Adwaita-Matugen/scalable/places/network-workgroup.svg;
    "noctalia/templates/gtk-folder/Adwaita-Matugen/scalable/places/user-bookmarks.svg".source = ./dotfiles/config/noctalia/templates/gtk-folder/Adwaita-Matugen/scalable/places/user-bookmarks.svg;
    "noctalia/templates/gtk-folder/Adwaita-Matugen/scalable/places/user-desktop.svg".source = ./dotfiles/config/noctalia/templates/gtk-folder/Adwaita-Matugen/scalable/places/user-desktop.svg;
    "noctalia/templates/gtk-folder/Adwaita-Matugen/scalable/places/user-home.svg".source = ./dotfiles/config/noctalia/templates/gtk-folder/Adwaita-Matugen/scalable/places/user-home.svg;
    "noctalia/templates/gtk-folder/Adwaita-Matugen/scalable/places/user-trash.svg".source = ./dotfiles/config/noctalia/templates/gtk-folder/Adwaita-Matugen/scalable/places/user-trash.svg;
    "noctalia/templates/gtk-folder/Adwaita-Matugen/scalable/status/folder-open.svg".source = ./dotfiles/config/noctalia/templates/gtk-folder/Adwaita-Matugen/scalable/status/folder-open.svg;
    "noctalia/templates/gtk-folder/Adwaita-Matugen/scalable/status/user-trash-full.svg".source = ./dotfiles/config/noctalia/templates/gtk-folder/Adwaita-Matugen/scalable/status/user-trash-full.svg;
    "noctalia/templates/gtk-folder/recolor.sh".source = ./dotfiles/config/noctalia/templates/gtk-folder/recolor.sh;
    "noctalia/templates/pywalfox-colors.json".source = ./dotfiles/config/noctalia/templates/pywalfox-colors.json;
    "noctalia/templates/starship-colors.toml".source = ./dotfiles/config/noctalia/templates/starship-colors.toml;
    "noctalia/templates/yazi-theme.toml".source = ./dotfiles/config/noctalia/templates/yazi-theme.toml;
    # user-templates.toml 已移植进 config.toml 的 [theme.templates.user.*]，不再单独部署
    "qq-flags.conf".source = ./dotfiles/config/qq-flags.conf;
    "satty/config.toml".source = ./dotfiles/config/satty/config.toml;
    "starship.toml".source = ./dotfiles/config/starship.toml;
    "xdg-desktop-portal/niri-portals.conf".source = ./dotfiles/config/xdg-desktop-portal/niri-portals.conf;
    "xdg-terminials.list".source = ./dotfiles/config/xdg-terminials.list;
    "xfce4/helpers.rc".source = ./dotfiles/config/xfce4/helpers.rc;
    "xfce4/xfconf/xfce-perchannel-xml/thunar-volman.xml".source = ./dotfiles/config/xfce4/xfconf/xfce-perchannel-xml/thunar-volman.xml;
    "xfce4/xfconf/xfce-perchannel-xml/thunar.xml".source = ./dotfiles/config/xfce4/xfconf/xfce-perchannel-xml/thunar.xml;
    "xsettingsd/xsettingsd.conf".source = ./dotfiles/config/xsettingsd/xsettingsd.conf;
  };

  home.file = {
    ".gtkrc-2.0".source = ./dotfiles/home/.gtkrc-2.0;
    ".local/bin/random-anime-wallpaper-noctalia".source = ./dotfiles/local/bin/random-anime-wallpaper-noctalia; executable = true;
    ".local/share/fcitx5/rime/default.custom.yaml".source = ./dotfiles/local/share/fcitx5/rime/default.custom.yaml;
    ".local/share/fcitx5/rime/rime_ice.custom.yaml".source = ./dotfiles/local/share/fcitx5/rime/rime_ice.custom.yaml;
    ".local/share/fcitx5/themes/Matugen/theme.conf".source = ./dotfiles/local/share/fcitx5/themes/Matugen/theme.conf;
    ".local/share/fcitx5/themes/default/theme.conf".source = ./dotfiles/local/share/fcitx5/themes/default/theme.conf;
    ".local/share/icons/Adwaita-Matugen-B/index.theme".source = ./dotfiles/local/share/icons/Adwaita-Matugen-B/index.theme;
    ".local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/application-x-addon.svg".source = ./dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/application-x-addon.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/application-x-executable.svg".source = ./dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/application-x-executable.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/audio-x-generic.svg".source = ./dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/audio-x-generic.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/font-x-generic.svg".source = ./dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/font-x-generic.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/inode-directory.svg".source = ./dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/inode-directory.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/text-html.svg".source = ./dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/text-html.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/text-x-script.svg".source = ./dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/text-x-script.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/x-office-document.svg".source = ./dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/x-office-document.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/x-office-presentation.svg".source = ./dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/x-office-presentation.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/places/folder-documents.svg".source = ./dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/places/folder-documents.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/places/folder-download.svg".source = ./dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/places/folder-download.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/places/folder-drag-accept.svg".source = ./dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/places/folder-drag-accept.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/places/folder-music.svg".source = ./dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/places/folder-music.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/places/folder-pictures.svg".source = ./dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/places/folder-pictures.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/places/folder-publicshare.svg".source = ./dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/places/folder-publicshare.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/places/folder-remote.svg".source = ./dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/places/folder-remote.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/places/folder-templates.svg".source = ./dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/places/folder-templates.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/places/folder-videos.svg".source = ./dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/places/folder-videos.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/places/folder.svg".source = ./dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/places/folder.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/places/network-server.svg".source = ./dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/places/network-server.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/places/network-workgroup.svg".source = ./dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/places/network-workgroup.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/places/user-bookmarks.svg".source = ./dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/places/user-bookmarks.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/places/user-desktop.svg".source = ./dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/places/user-desktop.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/places/user-home.svg".source = ./dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/places/user-home.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/places/user-trash.svg".source = ./dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/places/user-trash.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/status/folder-open.svg".source = ./dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/status/folder-open.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/status/user-trash-full.svg".source = ./dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/status/user-trash-full.svg;
    ".local/share/nwg-look/gsettings".source = ./dotfiles/local/share/nwg-look/gsettings;
    ".vimrc".source = ./dotfiles/home/.vimrc;
  };

  # polkit 认证代理：NixOS 上没有 Arch 的 /usr/lib/polkit-gnome，
  # 改用 Home Manager 的 polkit-gnome 用户服务拉起。
  services.polkit-gnome.enable = true;

  # ============================================================
  #  不在 nixpkgs 的包 → 走 flake / 自行打包
  #  （原脚本靠 shorin-arch 自建仓库与 AUR 提供，NixOS 无等价）
  # ============================================================
  # Flatpak 服务已在 configuration.nix 开启（services.flatpak.enable），
  # 但目前未声明任何 Flatpak 包：qq/wechat 都有 nixpkgs 原生版，其余缺失项无需 Flatpak。
  # 若想改用 Flatpak 版 qq/wechat 或装别的闭源 App，取消下面注释即可：
  #   services.flatpak.packages = [
  #     "flathub:org.tencent.qq"
  #   ];
  #
  # niri / Noctalia 以及其余 SHORiN rice 配置已落到 dotfiles/ 并通过 xdg.configFile / home.file 部署：
  #   - dotfiles/config/niri/*.kdl   （config.kdl + 9 个 include 拆分文件）
  #   - dotfiles/config/noctalia/config.toml   （v5 TOML 配置；v4 的 settings.json 已弃用）
  # 已针对 NixOS 适配：启动方式从 `qs -c noctalia-shell`（SHORiN 的 quickshell 写法）
  # 改为直接 `spawn-at-startup "noctalia"`；注释掉了 Arch 专用的 /usr/lib/polkit-gnome、
  # /usr/lib/xdg-desktop-portal-gnome，以及依赖私有脚本的截图音效、linuxqq-clipsync 等。
  # polkit 代理改用 services.polkit-gnome.enable。
  #
  # ⚠️ 想完全还原 SHORiN 原版交互（启动器/设置/壁纸/电源菜单/锁屏/音量亮度 等
  # 走 `qs -c noctalia-shell ipc call ...` 的绑定），需要：
  #   1) 在 home.packages 安装 quickshell（nixpkgs 有），
  #   2) 把 dotfiles/config/niri/config.kdl 的启动行改回 `spawn-sh-at-startup "qs -c noctalia-shell"`，
  #   3) 补充 SHORiN 私有脚本（~/.config/niri/scripts/*、niri-sidebar、quicksave、quickload、
  #      shorin-screenrec-menu、random-anime-wallpaper-noctalia 等，原仓库未纳入本转换）。
  #
  # 以下在 nixpkgs 暂无官方包，需自行打包或用其它渠道：
  #   pins-git                    → AUR 脚本工具，缺失
  #   kwin-effects-geometry-change→ KWin 特效，niri 用不上
  #   shorin-contrib-git           → 原仓库自用脚本，缺失
  #   shorin-proton-wrapper-git    → 原仓库自用 wrapper，缺失
  #   miyu                         → SHORiN-KiWATA/Miyu，仅 GitHub 源码，需自行 build
  #   opencode                     → 已用 flake 安装（见 flake.nix 的 opencode 输入）
  #   noctalia                     → 已用 flake 安装（见 flake.nix 的 noctalia 输入）
}
