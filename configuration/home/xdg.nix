# XDG 数据与配置文件部署。
{ pkgs, username, ... }:

{
  # Nautilus Python 扩展。
  xdg.dataFile = {
    "nautilus-python/extensions/video-to-audio.py".source = ./dotfiles/config/nautilus-python/video-to-audio.py;
    # Lunar Client desktop entry 覆盖。
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
    # AB Download Manager 托盘 service drop-in。
    "systemd/user/app-com.abdownloadmanager@autostart.service.d/10-abdm-tray.conf".text = ''
      [Service]
      Environment=LD_LIBRARY_PATH=${pkgs.systemdLibs}/lib:${pkgs.pipewire.jack}/lib
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
    "fish/functions/f.fish".source = ./dotfiles/config/fish/functions/f.fish;
    "fish/functions/fwatch.fish".source = ./dotfiles/config/fish/functions/fwatch.fish;
    "fontconfig/fonts.conf".source = ./dotfiles/config/fontconfig/fonts.conf;
    "fuzzel/fuzzel.ini".source = ./dotfiles/config/fuzzel/fuzzel.ini;
    # 书签路径随用户名生成。
    "gtk-3.0/bookmarks".text = ''
      file:///home/${username}/Documents Documents
      file:///home/${username}/Pictures Pictures
      file:///home/${username}/Videos Videos
      file:///home/${username}/Music Music
      file:///home/${username}/Downloads Downloads
      file:///home/${username}/.config .config
      file:///home/${username}/.local
    '';
    "gtk-3.0/gtk.css".source = ./dotfiles/config/gtk-3.0/gtk.css;
    "gtk-4.0/gtk.css".source = ./dotfiles/config/gtk-4.0/gtk.css;
    "mimeapps.list".source = ./dotfiles/config/mimeapps.list;
    # mpv.conf 需要按 username 替换路径；运行时数据目录保持可写。
    "mpv/mpv.conf" = {
      text = builtins.replaceStrings
        [ "__NEKO_HOME__" ]
        [ "/home/${username}" ]
        (builtins.readFile ./dotfiles/mpv/mpv.conf);
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
    "mpv/scripts/uosc_danmaku".source = ./dotfiles/mpv/scripts/uosc_danmaku;
    "mpv/shaders".source = ./dotfiles/mpv/shaders;
    "mpv/vs".source = ./dotfiles/mpv/vs;
    "mpv/fonts".source = ./dotfiles/mpv/fonts;
    # niri 配置；effects.kdl 由护眼脚本维护。
    "niri/animations.kdl".source = ./dotfiles/config/niri/animations.kdl;
    "niri/binds.kdl" = {
      source = ./dotfiles/config/niri/binds.kdl;
      force = true;
    };
    "niri/config.kdl".text = builtins.replaceStrings
      [ "__NEKO_GIO_EXTRA_MODULES__" "__NEKO_HOME__" ]
      [ "${pkgs.gvfs}/lib/gio/modules:${pkgs.dconf}/lib/gio/modules" "/home/${username}" ]
      (builtins.readFile ./dotfiles/config/niri/config.kdl);
    "niri/cursor.kdl".source = ./dotfiles/config/niri/cursor.kdl;
    "niri/layout.kdl".source = ./dotfiles/config/niri/layout.kdl;
    "niri/monitor.kdl".source = ./dotfiles/config/niri/monitor.kdl;
    "niri/rules.kdl".source = ./dotfiles/config/niri/rules.kdl;
    "niri/effects_normal.kdl".source = ./dotfiles/config/niri/effects_normal.kdl;
    "niri/effects_eyecare.kdl".source = ./dotfiles/config/niri/effects_eyecare.kdl;
    "niri/__custom__.kdl".source = ./dotfiles/config/niri/__custom__.kdl;
    "niri/input__custom__.kdl".source = ./dotfiles/config/niri/input__custom__.kdl;
    "niri/scratchpad-items__custom__.toml".source = ./dotfiles/config/niri/scratchpad-items__custom__.toml;
    # Noctalia hooks；config.toml 由 activation 提供可写副本。
    "noctalia/config.toml".force = true;
    "noctalia/theme-sync.sh".source = ./dotfiles/config/noctalia/theme-sync.sh;
    "noctalia/wallpaper-hook.sh".source = ./dotfiles/config/noctalia/wallpaper-hook.sh;
    "noctalia/mpv-hook.lua".source = ./dotfiles/config/noctalia/mpv-hook.lua;
    # Kitty 配置；current-theme.conf 由 activation 初始化。
    "kitty/kitty.conf".source = ./dotfiles/config/kitty/kitty.conf;
    "kitty/__custom__.conf".source = ./dotfiles/config/kitty/__custom__.conf;
    "kitty/themes/noctalia.conf" = {
      source = ./dotfiles/config/kitty/themes/noctalia.conf;
      force = true;
    };
    "fish/conf.d/__custom__.fish".source = ./dotfiles/config/fish/conf.d/__custom__.fish;
    "fish/conf.d/ATRI.fish".source = ./dotfiles/config/fish/conf.d/ATRI.fish;
    # Fastfetch / Starship。
    "fastfetch/config.jsonc".source = ./dotfiles/config/fastfetch/config.jsonc;
    "starship.toml".source = ./dotfiles/config/starship.toml;
    "xdg-desktop-portal/niri-portals.conf".source = ./dotfiles/config/xdg-desktop-portal/niri-portals.conf;
    "xdg-terminals.list".source = ./dotfiles/config/xdg-terminals.list;
    "xsettingsd/xsettingsd.conf".source = ./dotfiles/config/xsettingsd/xsettingsd.conf;
  };
}
