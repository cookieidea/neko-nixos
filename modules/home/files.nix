# home.file 部署（JDK 链、图标、desktop 入口等）
{ hmLib, pkgs, config, lib, username, selfPackages, ... }:

{

  home.file = {

    # ── HMCL Java 列表：HMCL 扫 ~/.jdks（IntelliJ 风格目录），链入各 zulu ──
    ".jdks/zulu25".source = "${pkgs.zulu25}";
    ".jdks/zulu21".source = "${pkgs.zulu21}";
    ".jdks/zulu17".source = "${pkgs.zulu17}";
    ".jdks/zulu8".source = "${pkgs.zulu8}";
    # ── 用户头像（freedesktop 标准 ~/.face，Noctalia Greeter 登录界面 + Noctalia 控制中心读取）──
    ".face".source = ../../config/avatar.png;
    # ── fastfetch logo 图片（kitty 图像协议；配置引用 ~/.local/share/fastfetch/NixOS.png）──
    ".local/share/fastfetch/NixOS.png".source = ../../config/config/fastfetch/NixOS.png;
    # ── 用户目录映射（nautilus 侧栏/模板目录定位，XDG_TEMPLATES_DIR=~/Templates）──
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
    # ── 新建文档模板（XDG_TEMPLATES_DIR=~/Templates；nautilus 右键「新建文档」读取）──
    "Templates/空白文本.txt" = { force = true; text = ""; };
    "Templates/空白文档.md" = { force = true; text = ""; };
    "Templates/空白文档.yaml" = { force = true; text = ""; };
    "Templates/空白文档.json" = { force = true; text = ""; };
    "Templates/空白文档.sh" = { force = true; text = "#!/usr/bin/env bash\n"; executable = true; };
    # ── Neovim wrapper 菜单条目修复 ──
    # nixvim 构建的 neovim 自带 nvim.desktop（Terminal=true，图形启动器打不开）。
    # flake overlay 覆盖不到 nixvim（它用自己 pin 的 nixpkgs 构建）→ 用用户级
    # ~/.local/share/applications 覆盖（freedesktop 优先级最高，启动器优先读这里）。
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
    # ── fcitx5 托盘/菜单图标 hicolor 兜底 ──
    # fcitx5 SNI 图标名（notificationitem.cpp）：托盘=input-keyboard-symbolic、
    # 菜单「重启」=view-refresh、「退出」=application-exit。Papirus 有这些图标，
    # 但若宿主/Qt 对 Papirus 查找失败，hicolor 是 XDG 最终兜底主题必查。
    # 不写用户级 index.theme（避免遮蔽系统 hicolor 的完整目录定义）。
    # 逐文件部署（目录级 source 在目标目录已存在时 ln 无法覆盖目录，即使 force=true）；
    # 文件级 force=true 覆盖手动复制过的同名文件。
    ".local/share/icons/hicolor/scalable/apps/input-keyboard-symbolic.svg" = {
      source = ../../config/icons/hicolor/scalable/apps/input-keyboard-symbolic.svg;
      force = true;
    };
    ".local/share/icons/hicolor/scalable/apps/view-refresh.svg" = {
      source = ../../config/icons/hicolor/scalable/apps/view-refresh.svg;
      force = true;
    };
    ".local/share/icons/hicolor/scalable/apps/application-exit.svg" = {
      source = ../../config/icons/hicolor/scalable/apps/application-exit.svg;
      force = true;
    };
    # ── KCalc 图标 hicolor 兜底 ──
    # kcalc.desktop 引用 Icon=accessories-calculator，该名仅 breeze/apps/48 有
    # （Papirus/hicolor 均无）；Noctalia V5 自研解析器走该链找不到 → 启动器无图标。
    # 放一份到 hicolor/scalable（全尺寸通配的最终兜底），与其他 symbolic 兜底同组。
    ".local/share/icons/hicolor/scalable/apps/accessories-calculator.svg" = {
      source = ../../config/icons/hicolor/scalable/apps/accessories-calculator.svg;
      force = true;
    };
    # ── 应用图标 hicolor 兜底（256x256）──
    # tabby/splayer-next（AppImage wrap 包自带 desktop 但图标不在标准路径）、
    # lunarclient（nixpkgs 包 desktop Icon=lunarclient 但无对应图标文件）。
    # 之前 VM 手动复制未固化 → 实体机重装后图标消失，收进仓库声明式部署。
    ".local/share/icons/hicolor/256x256/apps/tabby.png" = {
      source = ../../config/icons/hicolor/256x256/apps/tabby.png;
      force = true;
    };
    ".local/share/icons/hicolor/256x256/apps/splayer-next.png" = {
      source = ../../config/icons/hicolor/256x256/apps/splayer-next.png;
      force = true;
    };
    ".local/share/icons/hicolor/256x256/apps/lunarclient.png" = {
      source = ../../config/icons/hicolor/256x256/apps/lunarclient.png;
      force = true;
    };
    # ── AppImage wrap 包（tabby/splayer-next）的 desktop 入口 ──
    # wrapType2 26.05 FHS 输出不带标准路径 desktop；xdg.desktopEntries 在
    # useUserPackages 下未落到 ~/.local/share/applications → 用 home.file 强制写文件
    # force=true：更早的 xdg.desktopEntries 生成过普通文件，HM 拒绝覆盖
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
    # ── OBS VDO.Ninja 插件（pkgs/obs-vdoninja，autoPatchelf 修好依赖）──
    # ⚠️ 不能裸拷 .so（RPATH 指向构建机，依赖全丢）；链接 Nix 包产物，
    #    autoPatchelf 后 .so 的 RPATH 指向 store 里的 libobs/libdatachannel/ffmpeg 等
    ".config/scripts/noctalia-wallpaper-autostart.sh" = {
      source = ../../config/scripts/noctalia-wallpaper-autostart.sh;
      executable = true;
      force = true;
    };
    # obs-vdoninja 的部署已交给 programs.obs-studio 模块（wrapOBS 设 OBS_PLUGINS_PATH），
    # 原先往 ~/.config/obs-studio/plugins/ 塞的两个 symlink 已移除
    # ── 壁纸（原 resources/Wallpapers，noctalia 壁纸轮播/随机切换依赖 ~/Pictures/Wallpapers）──
    # ⚠️ 不用 home.file 软链（GC 后 store 路径失效会断链）→ 由下方
    #    home.activation.wallpaperRealFiles 复制为真实文件。
    # 视频壁纸（mpvpaper 播放；noctalia 壁纸组件已禁用，背景层由 mpvpaper 接管）
    # 原 .gtkrc-2.0 内容已并入 gtk.gtk2.extraConfig（fcitx 输入法），不再手动部署避免模块冲突
    ".local/bin/random-anime-wallpaper-noctalia" = {
      source = ../../config/local/bin/random-anime-wallpaper-noctalia;
      executable = true;
    };
    # SHORiN 私有脚本迁移（对应 binds.kdl：Mod+F3 录屏菜单、Mod+F5 快存、Mod+F8 快读）
    ".local/bin/quicksave" = {
      source = ../../config/local/bin/quicksave;
      executable = true;
    };
    ".local/bin/quickload" = {
      source = ../../config/local/bin/quickload;
      executable = true;
    };
    ".local/share/fcitx5/rime/default.custom.yaml".source = ../../config/local/share/fcitx5/rime/default.custom.yaml;
    ".local/share/fcitx5/rime/rime_ice.custom.yaml".source = ../../config/local/share/fcitx5/rime/rime_ice.custom.yaml;
    ".local/share/fcitx5/themes/Matugen/theme.conf".source = ../../config/local/share/fcitx5/themes/Matugen/theme.conf;
    ".local/share/fcitx5/themes/default/theme.conf".source = ../../config/local/share/fcitx5/themes/default/theme.conf;
    ".local/share/icons/Adwaita-Matugen-B/index.theme".source = ../../config/local/share/icons/Adwaita-Matugen-B/index.theme;
    ".local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/application-x-addon.svg".source = ../../config/local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/application-x-addon.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/application-x-executable.svg".source = ../../config/local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/application-x-executable.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/audio-x-generic.svg".source = ../../config/local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/audio-x-generic.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/font-x-generic.svg".source = ../../config/local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/font-x-generic.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/inode-directory.svg".source = ../../config/local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/inode-directory.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/text-html.svg".source = ../../config/local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/text-html.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/text-x-script.svg".source = ../../config/local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/text-x-script.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/x-office-document.svg".source = ../../config/local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/x-office-document.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/x-office-presentation.svg".source = ../../config/local/share/icons/Adwaita-Matugen-B/scalable/mimetypes/x-office-presentation.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/places/folder-documents.svg".source = ../../config/local/share/icons/Adwaita-Matugen-B/scalable/places/folder-documents.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/places/folder-download.svg".source = ../../config/local/share/icons/Adwaita-Matugen-B/scalable/places/folder-download.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/places/folder-drag-accept.svg".source = ../../config/local/share/icons/Adwaita-Matugen-B/scalable/places/folder-drag-accept.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/places/folder-music.svg".source = ../../config/local/share/icons/Adwaita-Matugen-B/scalable/places/folder-music.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/places/folder-pictures.svg".source = ../../config/local/share/icons/Adwaita-Matugen-B/scalable/places/folder-pictures.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/places/folder-publicshare.svg".source = ../../config/local/share/icons/Adwaita-Matugen-B/scalable/places/folder-publicshare.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/places/folder-remote.svg".source = ../../config/local/share/icons/Adwaita-Matugen-B/scalable/places/folder-remote.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/places/folder-templates.svg".source = ../../config/local/share/icons/Adwaita-Matugen-B/scalable/places/folder-templates.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/places/folder-videos.svg".source = ../../config/local/share/icons/Adwaita-Matugen-B/scalable/places/folder-videos.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/places/folder.svg".source = ../../config/local/share/icons/Adwaita-Matugen-B/scalable/places/folder.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/places/network-server.svg".source = ../../config/local/share/icons/Adwaita-Matugen-B/scalable/places/network-server.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/places/network-workgroup.svg".source = ../../config/local/share/icons/Adwaita-Matugen-B/scalable/places/network-workgroup.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/places/user-bookmarks.svg".source = ../../config/local/share/icons/Adwaita-Matugen-B/scalable/places/user-bookmarks.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/places/user-desktop.svg".source = ../../config/local/share/icons/Adwaita-Matugen-B/scalable/places/user-desktop.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/places/user-home.svg".source = ../../config/local/share/icons/Adwaita-Matugen-B/scalable/places/user-home.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/places/user-trash.svg".source = ../../config/local/share/icons/Adwaita-Matugen-B/scalable/places/user-trash.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/status/folder-open.svg".source = ../../config/local/share/icons/Adwaita-Matugen-B/scalable/status/folder-open.svg;
    ".local/share/icons/Adwaita-Matugen-B/scalable/status/user-trash-full.svg".source = ../../config/local/share/icons/Adwaita-Matugen-B/scalable/status/user-trash-full.svg;
    ".local/share/nwg-look/gsettings".source = ../../config/local/share/nwg-look/gsettings;
    # （.vimrc 已删：vim 未安装，编辑器 nvim=CookNixvim 不读 .vimrc）

    # ── SHORiN 私有 niri 脚本（配置迁移：从上游 noctalia-dotfiles 引入）──
    # 对应 binds.kdl 里直接调用 ~/.config/niri/scripts/* 的绑定：
    #   niri-binds（Mod+Shift+Slash 快捷键菜单）、niri-pick（Mod+P 取窗口/颜色信息）、
    #   niri-force-kill-window（Alt+F4 强杀窗口）。
    # random-anime-wallpaper-noctalia 已在上面 .local/bin 部署；niri-sidebar 走 selfPackages。
    ".config/niri/scripts/niri-binds" = {
      source = ../../config/config/niri/scripts/niri-binds;
      executable = true;
    };
    ".config/niri/scripts/niri-pick" = {
      source = ../../config/config/niri/scripts/niri-pick;
      executable = true;
    };
    ".config/niri/scripts/niri-force-kill-window" = {
      source = ../../config/config/niri/scripts/niri-force-kill-window;
      executable = true;
    };
    # ── NyxNiri 新增 niri 脚本（护眼模式 / Scratchpad 终端 / 星环菜单）──
    # 对应 NyxNiri 绑定：Mod+N（护眼）、Mod+Grave（scratch 终端）、Mod+A（星环菜单）。
    # 星环菜单本体由 selfPackages.nyxniri-scratch-menu 包装（提供 pygobject/GI 依赖）。
    ".config/niri/scripts/toggle-eyecare.sh" = {
      source = ../../config/config/niri/scripts/toggle-eyecare.sh;
      executable = true;
    };
    ".config/niri/scripts/niri-scratch-toggle.sh" = {
      source = ../../config/config/niri/scripts/niri-scratch-toggle.sh;
      executable = true;
    };
    ".config/niri/scripts/niri-scratch-menu.py" = {
      source = ../../config/config/niri/scripts/niri-scratch-menu.py;
      executable = true;
    };
    # NyxNiri fish 缓存清理脚本（星环菜单 clean-cache 入口）
    ".config/fish/clean-cache" = {
      source = ../../config/config/fish/clean-cache;
      executable = true;
    };
    # ── NyxMellow fcitx5 动态皮肤模板（Noctalia V5 模板输入，渲染到 themes/nyxmellow/）──
    ".local/share/fcitx5/themes/nyxmellow/templates/theme.conf" = {
      source = ../../config/local/share/fcitx5/themes/nyxmellow/templates/theme.conf;
    };
    ".local/share/fcitx5/themes/nyxmellow/templates/panel.svg" = {
      source = ../../config/local/share/fcitx5/themes/nyxmellow/templates/panel.svg;
    };
    ".local/share/fcitx5/themes/nyxmellow/templates/highlight.svg" = {
      source = ../../config/local/share/fcitx5/themes/nyxmellow/templates/highlight.svg;
    };

    # ── 开发工具链国内镜像源 ──
    # npm → npmmirror（淘宝镜像）；prefix 指向用户目录——NixOS 的 nodejs 在只读
    # store，npm -g 默认装 store 失败（ENOENT），用户前缀 + PATH 才可用
    ".npmrc".text = ''
      registry=https://registry.npmmirror.com
      prefix=/home/cookie/.npm-global
    '';
    # cargo → 中科大 crates.io 稀疏索引
    ".cargo/config.toml".text = ''
      [source.crates-io]
      replace-with = 'ustc'
      [source.ustc]
      registry = "sparse+https://mirrors.ustc.edu.cn/crates.io-index/"
      [net]
      git-fetch-with-cli = true
    '';
    # pip → 中科大 PyPI
    ".config/pip/pip.conf".text = ''
      [global]
      index-url = https://mirrors.ustc.edu.cn/pypi/simple
      trusted-host = mirrors.ustc.edu.cn
    '';
    # uv → 中科大 PyPI 作为默认源
    ".config/uv/uv.toml".text = ''
      [[index]]
      url = "https://mirrors.ustc.edu.cn/pypi/simple"
      default = true
    '';
  };
}
