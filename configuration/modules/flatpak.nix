# Flatpak：Flathub remote、应用集合与权限策略
{ pkgs, username, ... }:

{
  # Flatpak：启动时 one-shot 添加 remote + 自动装应用
  services.flatpak.enable = true;
  systemd.services.flatpak-repo = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    path = [ pkgs.flatpak pkgs.util-linux ];
    script = ''
      flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
      flatpak remote-modify flathub --url=https://mirrors.ustc.edu.cn/flathub
      flatpak install --noninteractive --or-update flathub com.tencent.WeChat com.qq.QQ com.github.tchx84.Flatseal io.github.kolunmi.Bazaar io.github.yucling.open-orpheus com.discordapp.Discord io.github.Predidit.Kazumi
      # QQ/微信：禁 fallback-x11 并给真 x11 socket（否则 Xvfb 起不来打不开）
      runuser -u ${username} -- flatpak --user override --nosocket=fallback-x11 --socket=x11 com.qq.QQ
      runuser -u ${username} -- flatpak --user override --nosocket=fallback-x11 --socket=x11 com.tencent.WeChat
      # Open Orpheus 托盘：放开 session-bus（SNI 总线名注册需要）
      runuser -u ${username} -- flatpak --user override --socket=session-bus io.github.yucling.open-orpheus
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };

}
