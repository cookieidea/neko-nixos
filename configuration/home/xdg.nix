# XDG 数据/配置部署（nautilus 扩展、niri、fish、kitty、mpv…）
{ hmLib, pkgs, config, lib, username, selfPackages, noctalia, ... }:

{
  # nautilus Python 扩展部署（nautilus-python 扫描 ~/.local/share/nautilus-python/extensions）
  xdg.dataFile = {
    "nautilus-python/extensions/video-to-audio.py".source = ./dotfiles/config/nautilus-python/video-to-audio.py;
    # lunarclient 覆盖（Exec 加 %u、补 discord scheme）
    "applications/lunarclient.desktop".text = ''
      [Desktop Entry]
      Name=Lunar Client
      Exec=lunarclient %u
      Terminal=false
      Type=Application
      Icon=lunarclient
      StartupWMClass=Lunar Client
      Comment=Electron launcher for Lunar Client
      MimeType=application/x-lcpack;x-scheme-handler/lunarclient;x-scheme-handler/discord-562286213059444737;
      Categories=Game;
    '';
  };

  xdg.configFile = {
    # ABDM 托盘（unit drop-in 注入 LD_LIBRARY_PATH 与 log 目录）
    "systemd/user/app-com.abdownloadmanager@autostart.service.d/10-abdm-tray.conf".text = ''
      [Service]
      Environment=LD_LIBRARY_PATH=${pkgs.systemdLibs}/lib:/nix/store/zcqp398mxlw62jl02sx0rsc7gvcl1qhc-pipewire-1.6.6-jack/lib
      ExecStartPre=${pkgs.coreutils}/bin/mkdir -p %h/.abdm/system/log
    '';
    "fcitx5/conf/cached_layouts".source = ./dotfiles/config/fcitx5/conf/cached_layouts;
    "fcitx5/conf/chttrans.conf".source = ./dotfiles/config/fcitx5/conf/chttrans.conf;
    "fcitx5/conf/classicui.conf".source = ./dotfiles/config/fcitx5/conf/classicui.conf;
    "fcitx5/conf/notifications.conf".source = ./dotfiles/config/fcitx5/conf/notifications.conf;
    "fcitx5/conf/pinyin.conf".source = ./dotfiles/config/fcitx5/conf/pinyin.conf;
    "fcitx5/conf/punctuation.conf".source = ./dotfiles/config/fcitx5/conf/punctuation.conf;
    "fcitx5/config".source = ./dotfiles/config/fcitx5/config;
    "fcitx5/profile".source = ./dotfiles/config/fcitx5/profile;
    "fish/functions/apt.fish".source = ./dotfiles/config/fish/functions/apt.fish;
    "fish/functions/f.fish".source = ./dotfiles/config/fish/functions/f.fish;
    "fish/functions/fwatch.fish".source = ./dotfiles/config/fish/functions/fwatch.fish;
    "fontconfig/fonts.conf".source = ./dotfiles/config/fontconfig/fonts.conf;
    "fuzzel/fuzzel.ini".source = ./dotfiles/config/fuzzel/fuzzel.ini;
    "gtk-3.0/bookmarks".source = ./dotfiles/config/gtk-3.0/bookmarks;
    "gtk-3.0/gtk.css".source = ./dotfiles/config/gtk-3.0/gtk.css;
    "gtk-4.0/gtk.css".source = ./dotfiles/config/gtk-4.0/gtk.css;
    "mimeapps.list".source = ./dotfiles/config/mimeapps.list;
    # mpv（配置本体是真实目录，watch_later 需写入）
    "mpv/mpv.conf" = {
      source = ./dotfiles/mpv/mpv.conf;
      force = true;
    };
    "mpv/input.conf".source = ./dotfiles/mpv/input.conf;
    "mpv/contextmenu.conf".source = ./dotfiles/mpv/contextmenu.conf;
    "mpv/t2s.json".source = ./dotfiles/mpv/t2s.json;
    "mpv/s2t.json".source = ./dotfiles/mpv/s2t.json;
    "mpv/script-opts/check_settings.conf".source = ./dotfiles/mpv/script-opts/check_settings.conf;
    "mpv/script-opts/input_plus.conf".source = ./dotfiles/mpv/script-opts/input_plus.conf;
    "mpv/script-opts/playlist_osd.conf".source = ./dotfiles/mpv/script-opts/playlist_osd.conf;
    "mpv/script-opts/thumbfast.conf".source = ./dotfiles/mpv/script-opts/thumbfast.conf;
    "mpv/script-opts/uosc.conf".source = ./dotfiles/mpv/script-opts/uosc.conf;
    "mpv/script-opts/uosc_danmaku.conf".source = ./dotfiles/mpv/script-opts/uosc_danmaku.conf;
    "mpv/scripts/auto_itm.lua".source = ./dotfiles/mpv/scripts/auto_itm.lua;
    "mpv/scripts/auto_sub_fonts_dir.lua".source = ./dotfiles/mpv/scripts/auto_sub_fonts_dir.lua;
    "mpv/scripts/check_settings.lua".source = ./dotfiles/mpv/scripts/check_settings.lua;
    "mpv/scripts/contextmenu.lua".source = ./dotfiles/mpv/scripts/contextmenu.lua;
    "mpv/scripts/input_plus.lua".source = ./dotfiles/mpv/scripts/input_plus.lua;
    "mpv/scripts/opencc.lua".source = ./dotfiles/mpv/scripts/opencc.lua;
    "mpv/scripts/playlist_osd.lua".source = ./dotfiles/mpv/scripts/playlist_osd.lua;
    "mpv/scripts/shaders.lua".source = ./dotfiles/mpv/scripts/shaders.lua;
    "mpv/scripts/ssdm.lua".source = ./dotfiles/mpv/scripts/ssdm.lua;
    "mpv/scripts/thumbfast.lua".source = ./dotfiles/mpv/scripts/thumbfast.lua;
    "mpv/scripts/vapoursynth.lua".source = ./dotfiles/mpv/scripts/vapoursynth.lua;
    "mpv/scripts/uosc".source = ./dotfiles/mpv/scripts/uosc;
    # ziggy 辅助二进制（补 executable 执行位）
    ".config/mpv/scripts/uosc/bin/ziggy-linux" = {
      source = ./dotfiles/mpv/scripts/uosc/bin/ziggy-linux;
      force = true;
    };
    "mpv/scripts/uosc_danmaku".source = ./dotfiles/mpv/scripts/uosc_danmaku;
    "mpv/shaders".source = ./dotfiles/mpv/shaders;
    "mpv/vs".source = ./dotfiles/mpv/vs;
    "mpv/fonts".source = ./dotfiles/mpv/fonts;
    # niri 配置（effects.kdl 为软链由 toggle-eyecare.sh 维护）
    "niri/animations.kdl".source = ./dotfiles/config/niri/animations.kdl;
    "niri/binds.kdl" = {
      source = ./dotfiles/config/niri/binds.kdl;
      force = true;
    };
    "niri/config.kdl" = {
      source = ./dotfiles/config/niri/config.kdl;
      force = true;
    };
    "niri/cursor.kdl".source = ./dotfiles/config/niri/cursor.kdl;
    "niri/layout.kdl".source = ./dotfiles/config/niri/layout.kdl;
    "niri/monitor.kdl".source = ./dotfiles/config/niri/monitor.kdl;
    "niri/rules.kdl".source = ./dotfiles/config/niri/rules.kdl;
    "niri/effects_normal.kdl".source = ./dotfiles/config/niri/effects_normal.kdl;
    "niri/effects_eyecare.kdl".source = ./dotfiles/config/niri/effects_eyecare.kdl;
    "niri/__custom__.kdl".source = ./dotfiles/config/niri/__custom__.kdl;
    "niri/input__custom__.kdl".source = ./dotfiles/config/niri/input__custom__.kdl;
    "niri/scratchpad-items__custom__.toml".source = ./dotfiles/config/niri/scratchpad-items__custom__.toml;
    # noctalia hook 脚本；config.toml 由 activation 复制为可写真实文件
    "noctalia/config.toml".force = true;
    "noctalia/theme-sync.sh".source = ./dotfiles/config/noctalia/theme-sync.sh;
    "noctalia/wallpaper-hook.sh".source = ./dotfiles/config/noctalia/wallpaper-hook.sh;
    "noctalia/mpv-hook.lua".source = ./dotfiles/config/noctalia/mpv-hook.lua;
    # kitty（current-theme.conf 由 activation 种子写入）
    "kitty/kitty.conf".source = ./dotfiles/config/kitty/kitty.conf;
    "kitty/__custom__.conf".source = ./dotfiles/config/kitty/__custom__.conf;
    "kitty/themes/noctalia.conf" = {
      source = ./dotfiles/config/kitty/themes/noctalia.conf;
      force = true;
    };
    "fish/conf.d/nyxniri-path.fish".source = ./dotfiles/config/fish/conf.d/nyxniri-path.fish;
    "fish/conf.d/nyxniri.fish".source = ./dotfiles/config/fish/conf.d/nyxniri.fish;
    "fish/conf.d/__custom__.fish".source = ./dotfiles/config/fish/conf.d/__custom__.fish;
    "fish/conf.d/shorin.fish".source = ./dotfiles/config/fish/conf.d/shorin.fish;
    "fish/completions/nyxniri.fish".source = ./dotfiles/config/fish/completions/nyxniri.fish;
    # fastfetch / starship
    "fastfetch/config.jsonc".source = ./dotfiles/config/fastfetch/config.jsonc;
    "starship.toml".source = ./dotfiles/config/starship.toml;
    "xdg-desktop-portal/niri-portals.conf".source = ./dotfiles/config/xdg-desktop-portal/niri-portals.conf;
    ".local/share/applications/qq.desktop" = {
      force = true;
      text = ''
[Desktop Entry]
Type=Application
Name=QQ
Exec=env PULSE_LATENCY_MSEC=30 PIPEWIRE_LATENCY=512/48000 flatpak run --branch=stable --arch=x86_64 --command=qq --file-forwarding com.qq.QQ --enable-features=UseOzonePlatform --ozone-platform=wayland @@u %U
Icon=com.qq.QQ
Terminal=false
Categories=Network;InstantMessaging;
MimeType=x-scheme-handler/tencent;
X-Flatpak=com.qq.QQ
      '';
    };
    "xdg-terminals.list".source = ./dotfiles/config/xdg-terminals.list;
    "xsettingsd/xsettingsd.conf".source = ./dotfiles/config/xsettingsd/xsettingsd.conf;
  };
}
