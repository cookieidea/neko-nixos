{ hmLib, ... }:

{
  systemd.user.sessionVariables = hmLib.devEnv // {
    # XDG_DATA_DIRS 由系统环境提供，不在此覆盖。
    # 不在此设置 GTK_IM_MODULE / QT_IM_MODULE。
    # 系统级 i18n.inputMethod 用 waylandFrontend = true，Wayland 原生程序
    # 走 text-input 协议；全局强制 immodule 会绕过该路径（fcitx5 会就此告警）。
    # 少数走 X11/XWayland 的程序（如 bwrap 沙箱内的 wechat）改用各自的
    # wrapper 注入这两个变量，见 packages/Utility/communication.nix。
  };

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
