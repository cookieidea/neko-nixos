# systemd user 服务与会话环境。
{ hmLib, pkgs, ... }:

{
  # 图形会话登录后启动的 user services。

  # nautilus-open-any-terminal 需要 GI/typelib 环境。
  # systemd 启动的程序不读取 ~/.profile，因此环境变量与 home.sessionVariables 共用 devEnv。
  systemd.user.sessionVariables = hmLib.devEnv // {
    GI_TYPELIB_PATH = "${pkgs.nautilus}/lib/girepository-1.0";
    NAUTILUS_4_EXTENSION_DIR = hmLib.nautilusExtensionDir;
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
