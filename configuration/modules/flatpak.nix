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

  # flathub remote 由 nix-flatpak 的 remotes 声明统一管理，无需额外 systemd 同步服务。

  environment.etc."flatpak/flathub.gpg".source = pkgs.fetchurl {
    url = "https://flathub.org/repo/flathub.gpg";
    sha256 = "1amf8767ipfvyb31k7lr2s3i793s1vz5psqb8sb0g771qjmj1p4b";
  };
}
