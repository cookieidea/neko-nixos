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

  # 校正 flathub remote 的 URL。
  #
  # 为什么需要：nix-flatpak 的 remotes 只在 remote **不存在**时执行 remote-add
  # （见其 modules/flatpak/remotes.nix：`if ! flatpak remotes | grep -q '^name$'`），
  # 也就是说 location 对「已存在但 URL 不对」的 remote 不生效 —— remote-add 不具
  # 幂等性，不会校正既有 URL。
  # 实际后果（曾遇到）：若系统里已有指向 dl.flathub.org 的 flathub（例如迁移自旧
  # 机器），声明里的镜像地址会被跳过；而本机网络访问该域名不通，于是
  # flatpak-managed-install 反复失败、switch 报错。
  # 此服务用 remote-modify 幂等地把 URL 指回镜像。
  #
  # 排在 flatpak-managed-install 之前：remote 不存在时本步空转（|| true），
  # 随后由 managed-install 按 location 创建；已存在则先纠正 URL 再拉取，
  # 使同一次启动内即可用对地址。
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
