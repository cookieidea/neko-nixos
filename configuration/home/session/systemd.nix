# systemd user 服务与会话环境。
{ hmLib, pkgs, ... }:

{
  # 图形会话登录后启动的 user services。

  # nautilus-open-any-terminal 需要 GI/typelib 环境。
  # systemd 启动的程序不读取 ~/.profile，因此环境变量与 home.sessionVariables 共用 devEnv。
  systemd.user.sessionVariables = hmLib.devEnv // {
    GI_TYPELIB_PATH = "${pkgs.nautilus}/lib/girepository-1.0";
    NAUTILUS_4_EXTENSION_DIR = hmLib.nautilusExtensionDir;

    # Flatpak 导出的 desktop 文件目录。
    # 这些路径本由 environment.profiles 写入 /etc/set-environment，但该文件
    # 只被 login shell（/etc/profile）读取；niri 由 systemd --user 启动、
    # 不经 login shell，所以启动器/菜单看不到 flatpak 应用。
    # 显式加入后，systemd --user 及其子进程（含启动器）即可索引到。
    XDG_DATA_DIRS = "$HOME/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:${pkgs.nautilus}/share";

    # GTK/Qt 的输入法模块。
    # 系统级 i18n.inputMethod 设了 waylandFrontend = true，此时 NixOS 的
    # fcitx5 模块**刻意不设置** GTK_IM_MODULE / QT_IM_MODULE（Wayland 原生
    # 应用应走 text-input-v3 协议）。
    # 但部分应用仍走 X11/XWayland 路径 —— 典型是 nixpkgs 的 wechat
    # （AppImage + bwrap 沙箱，不清环境，故继承会话变量）。这类应用没有
    # GTK_IM_MODULE 就无法加载 immodule，表现为「无法输入中文」。
    # 显式补上即可，不影响 Wayland 原生应用。
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
  };

  # 登录后通过 Noctalia IPC 设置随机壁纸。
  systemd.user.services.noctalia-wallpaper = {
    Unit = {
      Description = "Set random anime wallpaper via noctalia";
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "%h/.config/scripts/noctalia-wallpaper-autostart.sh";
      TimeoutStartSec = 300;
      Restart = "on-failure";
      RestartSec = 15;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
