# polkit、OBS、KDE Connect、GTK 主题
{ hmLib, pkgs, config, lib, username, selfPackages, ... }:

{
  services.polkit-gnome.enable = true;   # polkit 认证代理

  # ── OBS Studio（占用 HM 模块而非裸包，插件走 wrapOBS 统一注入）──
  # VDO.Ninja 是自建包（pkgs/obs-vdoninja，预编译 .so + autoPatchelf）。
  # 它的产物路径（lib/obs-plugins、share/obs/obs-plugins）正好是 wrapOBS 期望的
  # 布局 → 直接作为 plugin 传入，由模块设 OBS_PLUGINS_PATH/OBS_PLUGINS_DATA_PATH，
  # 不再需要手工往 ~/.config/obs-studio/plugins/ 里塞 symlink。
  programs.obs-studio = {
    enable = true;
    plugins = [ selfPackages.obs-vdoninja ];
  };

  # ── KDE Connect（手机 ↔ 电脑：文件互传/剪贴板同步/媒体控制/通知转发）──
  # 走 HM 模块而非 NixOS programs.kdeconnect：niri 不是 Plasma，不读 XDG autostart，
  # 需要 HM 生成的 systemd user 单元（kdeconnectd 挂 graphical-session.target）才能自启。
  # indicator 依赖 tray.target → Noctalia 实现了 StatusNotifierWatcher，托盘图标可用。
  # 防火墙端口范围在 configuration.nix（HM 管不到系统防火墙）。
  services.kdeconnect = {
    enable = true;
    indicator = true;
  };

  # ── gvfs 已移至系统层（configuration.nix `services.gvfs.enable`）──
  # 原因：polkitd 只扫描系统路径，而 gvfs 的 polkit policy
  # （org.gtk.vfs.file-operations）必须在那里注册，否则文件管理器进 /root 报
  # "Action ... is not registered"。该模块同时提供 gvfsd/metadata/volume-monitor
  # 等 systemd user 单元与 GIO_EXTRA_MODULES，此处不再重复声明。

  # ── GTK 主题/图标（noctalia launcher、GTK 应用图标解析依赖 freedesktop 主题）──
  # 由 home-manager gtk 模块全权写 settings.ini（不部署 dotfiles 的 settings.ini，
  # 避免只读 symlink 挡住模块写入导致图标主题失效）。
  # 图标用 Papirus（覆盖最广：Steam/Flatpak/Electron/GTK），Adwaita 兜底由包提供；
  # 主题 adw-gtk3-dark（libadwaita 风格，flatpak 应用 GTK_THEME 也指向它）。
  gtk = {
    enable = true;
    iconTheme = {
      name = "Papirus";
      package = pkgs.papirus-icon-theme;
    };
    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };
    cursorTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };
    font = {
      name = "HarmonyOS Sans SC";
      size = 10;
    };
    # 原 dotfiles/home/.gtkrc-2.0 的 fcitx 输入法配置合并进模块（避免 .gtkrc-2.0 管理冲突）
    gtk2.extraConfig = ''
      gtk-im-module="fcitx"
    '';
    # 原 dotfiles gtk-3.0/settings.ini 的其余设置（去掉 gtk-im-module，Wayland 前端不需要；
    # 26.05 HM 的 gtk3.extraConfig 是 attrset 类型）
    gtk3.extraConfig = {
      gtk-toolbar-style = "GTK_TOOLBAR_ICONS";
      gtk-toolbar-icon-size = "GTK_ICON_SIZE_LARGE_TOOLBAR";
      gtk-button-images = "0";
      gtk-menu-images = "0";
      gtk-enable-event-sounds = "1";
      gtk-enable-input-feedback-sounds = "0";
      gtk-xft-antialias = "1";
      gtk-xft-hinting = "1";
      gtk-xft-hintstyle = "hintslight";
      gtk-xft-rgba = "rgb";
      gtk-application-prefer-dark-theme = "1";
    };
    gtk4.extraConfig = {
      # 注：不再设 gtk-application-prefer-dark-theme —— libadwaita 不支持该
      # 设置（启动报 "Using GtkSettings:gtk-application-prefer-dark-theme with
      # libadwaita is unsupported" 警告），暗色由 noctalia 主题/GTK3 处理。
    };
  };

  # 不在 nixpkgs 的包走 flake / ./packages 自构建（见 README 自构建一节）
  # 闭源 App（微信/QQ/Discord）走 Flatpak（configuration.nix 的 flatpak-repo 自动装）
}
