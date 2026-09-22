# Flatpak 声明式配置。
{ pkgs, ... }:

{
  services.flatpak = {
    enable = true;

    remotes = [
      {
        name = "flathub";
        # USTC 提供 Flathub 缓存；未命中时仍可能访问 Flathub 源站。
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

    # 配置即状态：未声明应用和未声明 override 会在 activation 时清理。
    uninstallUnmanaged = true;
    overrides.pruneUnmanagedOverrides = true;
    update.auto.enable = false;
  };

  # 兼容已有系统中的 flathub remote，确保地址与声明保持一致。
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
