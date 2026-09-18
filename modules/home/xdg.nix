# XDG 数据/配置部署（nautilus 扩展、niri、fish、kitty、mpv…）
{ hmLib, pkgs, config, lib, username, selfPackages, noctalia, ... }:

{
  # dotfiles 部署到 ~/.config/（原 noctalia-dotfiles rice 配置）
  # ── nautilus Python 扩展部署（nautilus-python 扫描 ~/.local/share/nautilus-python/extensions）──
  xdg.dataFile = {
    "nautilus-python/extensions/video-to-audio.py".source = ../../config/config/nautilus-python/video-to-audio.py;
    # lunarclient 覆盖：原包 Exec 无 %u（discord-RPC 邀请链接丢参数只开启动器不进服），
    # 且未声明 discord-562286213059444737 scheme；用户级覆盖优先级最高
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
    # ABDM 托盘：autostart 重写绕过 makeWrapper → 无 systemdLibs → 托盘消失；
    # systemd user 服务不经过 login shell → 用 unit drop-in 注入 + 建 log 目录
    "systemd/user/app-com.abdownloadmanager@autostart.service.d/10-abdm-tray.conf".text = ''
      [Service]
      Environment=LD_LIBRARY_PATH=${pkgs.systemdLibs}/lib:/nix/store/zcqp398mxlw62jl02sx0rsc7gvcl1qhc-pipewire-1.6.6-jack/lib
      ExecStartPre=${pkgs.coreutils}/bin/mkdir -p %h/.abdm/system/log
    '';
    "fcitx5/conf/cached_layouts".source = ../../config/config/fcitx5/conf/cached_layouts;
    "fcitx5/conf/chttrans.conf".source = ../../config/config/fcitx5/conf/chttrans.conf;
    "fcitx5/conf/classicui.conf".source = ../../config/config/fcitx5/conf/classicui.conf;
    "fcitx5/conf/notifications.conf".source = ../../config/config/fcitx5/conf/notifications.conf;
    "fcitx5/conf/pinyin.conf".source = ../../config/config/fcitx5/conf/pinyin.conf;
    "fcitx5/conf/punctuation.conf".source = ../../config/config/fcitx5/conf/punctuation.conf;
    "fcitx5/config".source = ../../config/config/fcitx5/config;
    "fcitx5/profile".source = ../../config/config/fcitx5/profile;
    # ⚠️ fish/fish_variables 不部署（store 只读链接，fish 运行时写会 EROFS），让 fish 自己生成
    "fish/functions/apt.fish".source = ../../config/config/fish/functions/apt.fish;
    "fish/functions/f.fish".source = ../../config/config/fish/functions/f.fish;
    "fish/functions/fwatch.fish".source = ../../config/config/fish/functions/fwatch.fish;
    "fontconfig/fonts.conf".source = ../../config/config/fontconfig/fonts.conf;
    "fuzzel/fuzzel.ini".source = ../../config/config/fuzzel/fuzzel.ini;
    # fuzzel/themes/noctalia 由模板生成，不部署
    "gtk-3.0/bookmarks".source = ../../config/config/gtk-3.0/bookmarks;
    "gtk-3.0/gtk.css".source = ../../config/config/gtk-3.0/gtk.css;
    # gtk-3.0/noctalia.css 与 settings.ini 不部署（Noctalia 模板生成 / gtk 模块写入）
    "gtk-4.0/gtk.css".source = ../../config/config/gtk-4.0/gtk.css;
    # gtk-4.0/noctalia.css、settings.ini 同上不部署
    "mimeapps.list".source = ../../config/config/mimeapps.list;
    # mpv（自 Windows mpv.lite 迁移并 Linux 适配）；目录级只读内容用 symlink，
    # ~/.config/mpv 本体是真实目录（watch_later 需写入）
    "mpv/mpv.conf" = {
      source = ../../config/mpv/mpv.conf;
      force = true;
    };
    "mpv/input.conf".source = ../../config/mpv/input.conf;
    "mpv/contextmenu.conf".source = ../../config/mpv/contextmenu.conf;
    "mpv/t2s.json".source = ../../config/mpv/t2s.json;
    "mpv/s2t.json".source = ../../config/mpv/s2t.json;
    "mpv/script-opts/check_settings.conf".source = ../../config/mpv/script-opts/check_settings.conf;
    "mpv/script-opts/input_plus.conf".source = ../../config/mpv/script-opts/input_plus.conf;
    "mpv/script-opts/playlist_osd.conf".source = ../../config/mpv/script-opts/playlist_osd.conf;
    "mpv/script-opts/thumbfast.conf".source = ../../config/mpv/script-opts/thumbfast.conf;
    "mpv/script-opts/uosc.conf".source = ../../config/mpv/script-opts/uosc.conf;
    "mpv/script-opts/uosc_danmaku.conf".source = ../../config/mpv/script-opts/uosc_danmaku.conf;
    "mpv/scripts/auto_itm.lua".source = ../../config/mpv/scripts/auto_itm.lua;
    "mpv/scripts/auto_sub_fonts_dir.lua".source = ../../config/mpv/scripts/auto_sub_fonts_dir.lua;
    "mpv/scripts/check_settings.lua".source = ../../config/mpv/scripts/check_settings.lua;
    "mpv/scripts/contextmenu.lua".source = ../../config/mpv/scripts/contextmenu.lua;
    "mpv/scripts/input_plus.lua".source = ../../config/mpv/scripts/input_plus.lua;
    "mpv/scripts/opencc.lua".source = ../../config/mpv/scripts/opencc.lua;
    "mpv/scripts/playlist_osd.lua".source = ../../config/mpv/scripts/playlist_osd.lua;
    "mpv/scripts/shaders.lua".source = ../../config/mpv/scripts/shaders.lua;
    "mpv/scripts/ssdm.lua".source = ../../config/mpv/scripts/ssdm.lua;
    "mpv/scripts/thumbfast.lua".source = ../../config/mpv/scripts/thumbfast.lua;
    "mpv/scripts/vapoursynth.lua".source = ../../config/mpv/scripts/vapoursynth.lua;
    "mpv/scripts/uosc".source = ../../config/mpv/scripts/uosc;
    # ziggy 辅助二进制：目录 symlink 到 store 会丢执行位 → 单独部署补 executable
    ".config/mpv/scripts/uosc/bin/ziggy-linux" = {
      source = ../../config/mpv/scripts/uosc/bin/ziggy-linux;
      force = true;
    };
    "mpv/scripts/uosc_danmaku".source = ../../config/mpv/scripts/uosc_danmaku;
    "mpv/shaders".source = ../../config/mpv/shaders;
    "mpv/vs".source = ../../config/mpv/vs;
    "mpv/fonts".source = ../../config/mpv/fonts;
    # niri 配置（迁移自 NyxNiri）；effects.kdl 为软链由 toggle-eyecare.sh 维护
    "niri/animations.kdl".source = ../../config/config/niri/animations.kdl;
    "niri/binds.kdl" = {
      source = ../../config/config/niri/binds.kdl;
      force = true;
    };
    "niri/config.kdl" = {
      source = ../../config/config/niri/config.kdl;
      force = true;
    };
    "niri/cursor.kdl".source = ../../config/config/niri/cursor.kdl;
    "niri/layout.kdl".source = ../../config/config/niri/layout.kdl;
    "niri/monitor.kdl".source = ../../config/config/niri/monitor.kdl;
    "niri/rules.kdl".source = ../../config/config/niri/rules.kdl;
    "niri/effects_normal.kdl".source = ../../config/config/niri/effects_normal.kdl;
    "niri/effects_eyecare.kdl".source = ../../config/config/niri/effects_eyecare.kdl;
    "niri/__custom__.kdl".source = ../../config/config/niri/__custom__.kdl;
    "niri/input__custom__.kdl".source = ../../config/config/niri/input__custom__.kdl;
    "niri/scratchpad-items__custom__.toml".source = ../../config/config/niri/scratchpad-items__custom__.toml;
    # noctalia hook 脚本；mpv-hook.lua 缺失会致 mpvpaper 视频壁纸失败
    # config.toml 由 programs.noctalia.settings 部署为 symlink，activation 会复制为
    # 可写真实文件（V5 面板回写）→ 配置变更时 force 覆盖避免 clobber
    "noctalia/config.toml".force = true;
    "noctalia/theme-sync.sh".source = ../../config/config/noctalia/theme-sync.sh;
    "noctalia/wallpaper-hook.sh".source = ../../config/config/noctalia/wallpaper-hook.sh;
    "noctalia/mpv-hook.lua".source = ../../config/config/noctalia/mpv-hook.lua;
    # kitty（current-theme.conf 由 Noctalia 模板生成，首次 activation 种子写入）
    "kitty/kitty.conf".source = ../../config/config/kitty/kitty.conf;
    "kitty/__custom__.conf".source = ../../config/config/kitty/__custom__.conf;
    "kitty/themes/noctalia.conf" = {
      source = ../../config/config/kitty/themes/noctalia.conf;
      force = true;
    };
    "fish/conf.d/nyxniri-path.fish".source = ../../config/config/fish/conf.d/nyxniri-path.fish;
    "fish/conf.d/nyxniri.fish".source = ../../config/config/fish/conf.d/nyxniri.fish;
    "fish/conf.d/__custom__.fish".source = ../../config/config/fish/conf.d/__custom__.fish;
    "fish/conf.d/shorin.fish".source = ../../config/config/fish/conf.d/shorin.fish;
    "fish/completions/nyxniri.fish".source = ../../config/config/fish/completions/nyxniri.fish;
    # fastfetch / starship（starship.toml 的 palette 段由 Noctalia 生成，只读部署 base 版）
    "fastfetch/config.jsonc".source = ../../config/config/fastfetch/config.jsonc;
    "starship.toml".source = ../../config/config/starship.toml;
    # v4 版 noctalia 配置已全部移除（V5 用 config.toml，见 programs.noctalia 与上方 noctalia 部署）
    "xdg-desktop-portal/niri-portals.conf".source = ../../config/config/xdg-desktop-portal/niri-portals.conf;
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
    "xdg-terminals.list".source = ../../config/config/xdg-terminals.list;
    "xsettingsd/xsettingsd.conf".source = ../../config/config/xsettingsd/xsettingsd.conf;
  };
}
