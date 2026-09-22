# Flatpak 声明式配置。
{ pkgs, ... }:

{
  services.flatpak = {
    enable = true;

    remotes = [
      {
        name = "flathub";
        location = "https://mirrors.ustc.edu.cn/flathub";
        gpg-import = "/etc/flatpak/flathub.gpg";
      }
    ];

    packages = [
      "io.github.kolunmi.Bazaar"
      "com.github.tchx84.Flatseal"
      "com.qq.QQ"
      "io.github.yucling.open-orpheus"
      "io.github.Predidit.Kazumi"
    ];

    overrides = {
      settings = {
        "com.qq.QQ".Context.sockets = [ "!fallback-x11" "x11" ];
        "io.github.yucling.open-orpheus".Context.sockets = [ "session-bus" ];
      };
    };

    # 未声明的应用和 override 会在 activation 时删除。
    uninstallUnmanaged = true;
    overrides.pruneUnmanagedOverrides = true;
    update.auto.enable = false;
  };

  # 保证已有 flathub remote 使用配置中的镜像地址。
  systemd.services.flatpak-mirror = {
    description = "Point the flathub remote at the USTC mirror";
    wantedBy = [ "multi-user.target" ];
    before = [ "flatpak-managed-install.service" ];
    path = [ pkgs.flatpak ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${pkgs.flatpak}/bin/flatpak remote-modify --system \
        flathub --url=https://mirrors.ustc.edu.cn/flathub || true
    '';
  };

  environment.etc."flatpak/flathub.gpg".source = pkgs.fetchurl {
    url = "https://flathub.org/repo/flathub.gpg";
    sha256 = "1amf8767ipfvyb31k7lr2s3i793s1vz5psqb8sb0g771qjmj1p4b";
  };
}
