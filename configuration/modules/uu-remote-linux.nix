# 网易 UU 远程被控端（非官方 Linux 实现，uu-remote-linux）。
# 替代原先基于官方 deb 重打包的 uuyc：官方下载接口是「永远最新版」签名
# 链接，hash 不可复现，每次上游重传都会让构建失败。
{ ... }:

{
  services.uu-remote-linux = {
    enable = true;

    # niri 是 Wayland 会话，远程控制需要 uinput 注入键鼠。
    uinput.enable = true;

    settings = {
      UU_DESKTOP_BACKEND = "wayland";
    };
  };
}
