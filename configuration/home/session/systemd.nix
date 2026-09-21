# systemd user 服务与 session 环境（astral 超时、随机壁纸）
{ hmLib, pkgs, ... }:

{
  # systemd user 服务（登录图形会话后自启）

  # nautilus-open-any-terminal（niri 由 systemd 服务 spawn，需注入 gi/typelib）
  #
  # 这些值必须与 home.sessionVariables 一致：niri/nautilus 等由 systemd 拉起，
  # 不读 ~/.profile，只能靠 systemd.user.sessionVariables 注入。
  # 故 PYTHONPATH / VAPOURSYNTH_EXTRA_PLUGIN_PATH / JAVA_HOME / CARGO_HOME
  # 统一取自 lib.nix 的 devEnv（单一数据源，避免两处漂移）。
  systemd.user.sessionVariables = hmLib.devEnv // {
    GI_TYPELIB_PATH = "${pkgs.nautilus}/lib/girepository-1.0";
    NAUTILUS_4_EXTENSION_DIR = hmLib.nautilusExtensionDir;
  };

  # astral 关机超时（SIGTERM 后 100ms 未退出即 SIGKILL）
  xdg.configFile."systemd/user/astral-core.service.d/10-timeout.conf" = {
    force = true;
    text = ''
      [Service]
      TimeoutStopSec=100ms
    '';
  };

  # 开机随机壁纸（noctalia IPC）
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
