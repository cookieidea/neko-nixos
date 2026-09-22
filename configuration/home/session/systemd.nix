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
