# systemd user 服务与 session 环境（astral 超时、随机壁纸）
{ hmLib, pkgs, username, selfPackages, ... }:

{
  # ============================================================
  #  systemd user 服务（登录图形会话后自启）
  # ============================================================
  # ABDM 不自启（其自身有 autostart 机制，双启会弹窗）；托盘由下方 drop-in 兜底

  # nautilus-open-any-terminal：nautilus 由 niri（systemd 服务）spawn，只继承
  # systemd 用户环境 → 注入 gi/typelib，"打开终端"才不消失
  systemd.user.sessionVariables = {
    PYTHONPATH = "${pkgs.python3Packages.pygobject3}/lib/python3.13/site-packages:${selfPackages.k7sfunc}/lib/python3.13/site-packages:${pkgs.python3Packages.vapoursynth}/lib/python3.13/site-packages";
    GI_TYPELIB_PATH = "${pkgs.nautilus}/lib/girepository-1.0";
    NAUTILUS_4_EXTENSION_DIR = "${selfPackages.nautilus-extensions.nautilus-with-extensions}/lib/nautilus/extensions-4";
    VAPOURSYNTH_EXTRA_PLUGIN_PATH = "${selfPackages.vapoursynth-with-plugins}/lib/vapoursynth";
  };

  # 关机时 astral handshake 超时导致 user@1000 等待90s；不等待优雅退出，
  # SIGTERM 后 100ms 未退出即 SIGKILL（注意 TimeoutStopSec=0 表示禁用超时）
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
