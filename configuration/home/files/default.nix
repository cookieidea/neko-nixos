# home.file 部署：JDK 链、图标、desktop 入口、脚本、镜像源
{ hmLib, pkgs, ... }:

{
  imports = [ ./activation.nix ];

  home.file = {

    # HMCL 的 JDK 列表（扫 ~/.jdks）
    ".jdks/zulu25".source = "${pkgs.zulu25}";
    ".jdks/zulu21".source = "${pkgs.zulu21}";
    ".jdks/zulu17".source = "${pkgs.zulu17}";
    ".jdks/zulu8".source = "${pkgs.zulu8}";

    # 用户头像（greeter / 控制中心读取）
    ".face".source = ../dotfiles/avatar.png;

    # fastfetch logo
    ".local/share/fastfetch/NixOS.png".source = ../dotfiles/config/fastfetch/NixOS.png;

    # 用户目录映射
    ".config/user-dirs.dirs" = {
      force = true;
      text = ''
        XDG_DESKTOP_DIR="$HOME/Desktop"
        XDG_DOCUMENTS_DIR="$HOME/Documents"
        XDG_DOWNLOAD_DIR="$HOME/Downloads"
        XDG_MUSIC_DIR="$HOME/Music"
        XDG_PICTURES_DIR="$HOME/Pictures"
        XDG_PUBLICSHARE_DIR="$HOME/Public"
        XDG_TEMPLATES_DIR="$HOME/Templates"
        XDG_VIDEOS_DIR="$HOME/Videos"
      '';
    };

    # 新建文档模板
    "Templates/空白文本.txt" = { force = true; text = ""; };
    "Templates/空白文档.md" = { force = true; text = ""; };
    "Templates/空白文档.yaml" = { force = true; text = ""; };
    "Templates/空白文档.json" = { force = true; text = ""; };
    "Templates/空白文档.sh" = { force = true; text = "#!/usr/bin/env bash\n"; executable = true; };

    # nvim.desktop 覆盖（上游 Terminal=true，图形启动器打不开）
    ".local/share/applications/nvim.desktop" = {
      force = true;
      text = ''
      [Desktop Entry]
      Name=Neovim wrapper
      GenericName=Text Editor
      Comment=Edit text files
      TryExec=nvim
      Exec=kitty -e nvim %F
      Icon=nvim
      Type=Application
      Terminal=false
      Categories=Utility;TextEditor;Development;
      MimeType=text/plain;text/x-makefile;application/x-shellscript;text/x-c;text/x-c++src;text/markdown;application/json;text/x-yaml;application/yaml;text/yaml;application/x-yaml;application/x-zerosize;
      StartupNotify=false
      '';
    };

    # fcitx5 托盘 / 菜单图标（hicolor 兜底）
    ".local/share/icons/hicolor/scalable/apps/input-keyboard-symbolic.svg" = {
      source = ../dotfiles/icons/hicolor/scalable/apps/input-keyboard-symbolic.svg;
      force = true;
    };
    ".local/share/icons/hicolor/scalable/apps/view-refresh.svg" = {
      source = ../dotfiles/icons/hicolor/scalable/apps/view-refresh.svg;
      force = true;
    };
    ".local/share/icons/hicolor/scalable/apps/application-exit.svg" = {
      source = ../dotfiles/icons/hicolor/scalable/apps/application-exit.svg;
      force = true;
    };

    # KCalc 图标（accessories-calculator 仅 breeze 有）
    ".local/share/icons/hicolor/scalable/apps/accessories-calculator.svg" = {
      source = ../dotfiles/icons/hicolor/scalable/apps/accessories-calculator.svg;
      force = true;
    };

    # 应用图标（tabby / splayer-next / lunarclient）
    ".local/share/icons/hicolor/256x256/apps/tabby.png" = {
      source = ../dotfiles/icons/hicolor/256x256/apps/tabby.png;
      force = true;
    };
    ".local/share/icons/hicolor/256x256/apps/splayer-next.png" = {
      source = ../dotfiles/icons/hicolor/256x256/apps/splayer-next.png;
      force = true;
    };
    ".local/share/icons/hicolor/256x256/apps/lunarclient.png" = {
      source = ../dotfiles/icons/hicolor/256x256/apps/lunarclient.png;
      force = true;
    };

    # AppImage 包的 desktop 入口（上游不带标准路径 desktop）
    ".local/share/applications/tabby.desktop" = {
      text = ''
        [Desktop Entry]
        Type=Application
        Name=Tabby
        Comment=Terminal emulator
        Exec=tabby-terminal
        Icon=tabby
        Terminal=false
        Categories=System;TerminalEmulator;
      '';
      force = true;
    };
    ".local/share/applications/splayer-next.desktop" = {
      text = ''
        [Desktop Entry]
        Type=Application
        Name=SPlayer-Next
        Comment=Cross-platform desktop music player
        Exec=splayer-next
        Icon=splayer-next
        Terminal=false
        Categories=AudioVideo;Audio;Player;
      '';
      force = true;
    };

    # 随机壁纸脚本（noctalia IPC）
    ".config/scripts/noctalia-wallpaper-autostart.sh" = {
      source = ../dotfiles/scripts/noctalia-wallpaper-autostart.sh;
      executable = true;
      force = true;
    };

    # 壁纸 / 快照脚本
    ".local/bin/random-anime-wallpaper-noctalia" = {
      source = ../dotfiles/local/bin/random-anime-wallpaper-noctalia;
      executable = true;
    };
    ".local/bin/quicksave" = {
      source = ../dotfiles/local/bin/quicksave;
      executable = true;
    };
    ".local/bin/quickload" = {
      source = ../dotfiles/local/bin/quickload;
      executable = true;
    };

    # fcitx5 配置与主题
    ".local/share/fcitx5/rime/default.custom.yaml".source = ../dotfiles/local/share/fcitx5/rime/default.custom.yaml;
    ".local/share/fcitx5/rime/rime_ice.custom.yaml".source = ../dotfiles/local/share/fcitx5/rime/rime_ice.custom.yaml;
    ".local/share/fcitx5/themes/Matugen/theme.conf".source = ../dotfiles/local/share/fcitx5/themes/Matugen/theme.conf;
    ".local/share/fcitx5/themes/default/theme.conf".source = ../dotfiles/local/share/fcitx5/themes/default/theme.conf;

    # Adwaita-Matugen 图标主题
    ".local/share/icons/Adwaita-Matugen-B/index.theme".source = ../dotfiles/local/share/icons/Adwaita-Matugen-B/index.theme;
    ".local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/application-x-addon.svg".source = ../dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/application-x-addon.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/application-x-executable.svg".source = ../dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/application-x-executable.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/audio-x-generic.svg".source = ../dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/audio-x-generic.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/font-x-generic.svg".source = ../dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/font-x-generic.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/inode-directory.svg".source = ../dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/inode-directory.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/text-html.svg".source = ../dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/text-html.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/text-x-script.svg".source = ../dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/text-x-script.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/x-office-document.svg".source = ../dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/x-office-document.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/x-office-presentation.svg".source = ../dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/x-office-presentation.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/places/folder-documents.svg".source = ../dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/places/folder-documents.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/places/folder-download.svg".source = ../dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/places/folder-download.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/places/folder-drag-accept.svg".source = ../dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/places/folder-drag-accept.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/places/folder-music.svg".source = ../dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/places/folder-music.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/places/folder-pictures.svg".source = ../dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/places/folder-pictures.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/places/folder-publicshare.svg".source = ../dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/places/folder-publicshare.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/places/folder-remote.svg".source = ../dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/places/folder-remote.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/places/folder-templates.svg".source = ../dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/places/folder-templates.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/places/folder-videos.svg".source = ../dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/places/folder-videos.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/places/folder.svg".source = ../dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/places/folder.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/places/network-server.svg".source = ../dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/places/network-server.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/places/network-workgroup.svg".source = ../dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/places/network-workgroup.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/places/user-bookmarks.svg".source = ../dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/places/user-bookmarks.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/places/user-desktop.svg".source = ../dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/places/user-desktop.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/places/user-home.svg".source = ../dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/places/user-home.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/places/user-trash.svg".source = ../dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/places/user-trash.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/status/folder-open.svg".source = ../dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/status/folder-open.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/status/user-trash-full.svg".source = ../dotfiles/local/share/icons/Adwaita-Matugen-B/scalable/status/user-trash-full.svg;
    ".local/share/nwg-look/gsettings".source = ../dotfiles/local/share/nwg-look/gsettings;

    # niri 脚本（binds.kdl 直接调用）
    ".config/niri/scripts/niri-binds" = {
      source = ../dotfiles/config/niri/scripts/niri-binds;
      executable = true;
    };
    ".config/niri/scripts/niri-pick" = {
      source = ../dotfiles/config/niri/scripts/niri-pick;
      executable = true;
    };
    ".config/niri/scripts/niri-force-kill-window" = {
      source = ../dotfiles/config/niri/scripts/niri-force-kill-window;
      executable = true;
    };
    ".config/niri/scripts/toggle-eyecare.sh" = {
      source = ../dotfiles/config/niri/scripts/toggle-eyecare.sh;
      executable = true;
    };
    ".config/niri/scripts/niri-scratch-toggle.sh" = {
      source = ../dotfiles/config/niri/scripts/niri-scratch-toggle.sh;
      executable = true;
    };
    ".config/niri/scripts/niri-scratch-menu.py" = {
      source = ../dotfiles/config/niri/scripts/niri-scratch-menu.py;
      executable = true;
    };
    ".config/fish/clean-cache" = {
      source = ../dotfiles/config/fish/clean-cache;
      executable = true;
    };

    # fcitx5 动态皮肤模板（Noctalia 渲染到 themes/nyxmellow/）
    ".local/share/fcitx5/themes/nyxmellow/templates/theme.conf" = {
      source = ../dotfiles/local/share/fcitx5/themes/nyxmellow/templates/theme.conf;
    };
    ".local/share/fcitx5/themes/nyxmellow/templates/panel.svg" = {
      source = ../dotfiles/local/share/fcitx5/themes/nyxmellow/templates/panel.svg;
    };
    ".local/share/fcitx5/themes/nyxmellow/templates/highlight.svg" = {
      source = ../dotfiles/local/share/fcitx5/themes/nyxmellow/templates/highlight.svg;
    };

    # 国内镜像源（内容定义见 modules/home/lib.nix，单一数据源）
    ".npmrc".text = hmLib.npmrc;
    ".cargo/config.toml".text = hmLib.cargoConfig;
    ".config/pip/pip.conf".text = hmLib.pipConf;
    ".config/uv/uv.toml".text = hmLib.uvToml;
  };
}
