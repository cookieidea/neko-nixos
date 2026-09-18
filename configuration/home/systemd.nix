# systemd user 服务与 session 环境（astral 超时、随机壁纸）
{ hmLib, pkgs, username, selfPackages, ... }:

{
  # systemd user 服务（登录图形会话后自启）

  # nautilus-open-any-terminal（niri 由 systemd 服务 spawn，需注入 gi/typelib）
  systemd.user.sessionVariables = {
    PYTHONPATH = "${pkgs.python3Packages.pygobject3}/lib/python3.13/site-packages:${selfPackages.k7sfunc}/lib/python3.13/site-packages:${pkgs.python3Packages.vapoursynth}/lib/python3.13/site-packages";
    GI_TYPELIB_PATH = "${pkgs.nautilus}/lib/girepository-1.0";
    NAUTILUS_4_EXTENSION_DIR = "${selfPackages.nautilus-extensions.nautilus-with-extensions}/lib/nautilus/extensions-4";
    VAPOURSYNTH_EXTRA_PLUGIN_PATH = "${selfPackages.vapoursynth-with-plugins}/lib/vapoursynth";
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
