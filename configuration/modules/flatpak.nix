# Flatpak：声明式管理 remote、应用与权限 override。
#
# 用 nix-flatpak（flake input）取代原先「systemd 脚本调 flatpak CLI」的写法 ——
# 那种写法属于运行时修改状态：回滚 NixOS generation 时 flatpak 内容不会跟着
# 回去，系统不再是完整的 transactional state。改由 Nix 描述后，remote / 应用 /
# override 都随 generation 回滚。
#
# 关于下载：用 USTC 镜像（各镜像实测比较后最快的一个）。
#   参考数据：装 Flatseal + org.gnome.Platform 等 runtime 共 1.6G，
#   实际耗时约 5.6 分钟（ostree 并发拉取，总吞吐约 4.7 MB/s）。
#   注意：不要用「单连接 curl 拉单个小文件」来估算 flatpak 速度 ——
#   ostree 是并发多对象拉取，单连接测速会严重低估（曾据此误判为需数小时）。
#   安装由 systemd 服务异步执行，不阻塞登录。
{ pkgs, ... }:

{
  services.flatpak = {
    enable = true;

    remotes = [
      {
        name = "flathub";
        # 直接指向镜像的 OSTree repo（USTC 不提供 .flatpakrepo 文件）。
        location = "https://mirrors.ustc.edu.cn/flathub";
        # 镜像与官方 Flathub 的 collection-id 一致，故用官方签名密钥即可验证。
        gpg-import = "/etc/flatpak/flathub.gpg";
      }
    ];

    packages = [
      "io.github.kolunmi.Bazaar"      # Flatpak 应用商店
      "com.github.tchx84.Flatseal"    # 权限管理 GUI

      # QQ 留在此处：nixpkgs 的 qq 固定到 2026-05-28 的构建，而腾讯已下架
      # 该 deb（URL 404，官方页与 web.archive.org 均无），故无法改用 nixpkgs。
      # 待 nixpkgs 更新 sources.nix 后可再评估迁移。
      # （微信已改用 nixpkgs 的 wechat，见 home/packages/Utility/communication.nix）
      "com.qq.QQ"

      # 其他。
      "io.github.yucling.open-orpheus"   # 音乐播放
      "io.github.Predidit.Kazumi"        # 漫画

      # 注：Discord 计划改用 nixcord（尚未接入）。
    ];

    # 应用级权限：默认最小权限，只对确有必要者放宽。
    overrides = {
      settings = {
        # QQ：sandbox 内 fallback-x11 不可用，需真实 X11 socket。
        # 属兼容性妥协，仅此应用放宽，不设为全局默认。
        "com.qq.QQ".Context.sockets = [ "!fallback-x11" "x11" ];

        # Open Orpheus：托盘图标需在 session bus 注册 SNI。
        "io.github.yucling.open-orpheus".Context.sockets = [ "session-bus" ];
      };
    };

    # 清理不再由本配置声明的应用与 override，使 flatpak 状态真正跟随 generation。
    uninstallUnmanaged = true;
    overrides.pruneUnmanagedOverrides = true;

    # 不自动更新：应用更新会脱离 generation 语义，需要时手动 flatpak update。
    update.auto.enable = false;
  };

  # nix-flatpak 的 remotes 只在 remote 不存在时执行 remote-add —— 它不会
  # 校正已存在 remote 的 URL。若此前用官方地址建过 flathub，镜像配置就会被
  # 跳过，导致之后每次都去访问 dl.flathub.org（本机网络下 SSL 不通）。
  # 这里补一个幂等的 remote-modify，确保 URL 始终指向镜像。
  systemd.services.flatpak-mirror = {
    description = "Point the flathub remote at the USTC mirror";
    wantedBy = [ "multi-user.target" ];
    # 先于 flatpak-managed-install 执行，使它在同一次启动内就能用对 URL：
    #   remote 不存在时本服务空转，随后由 managed-install 用上面的 location 创建；
    #   remote 已存在但 URL 不对时本服务先纠正，managed-install 再拉取即可成功。
    before = [ "flatpak-managed-install.service" ];
    path = [ pkgs.flatpak ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      # remote 尚不存在时 remote-modify 会失败，属预期，忽略即可。
      ${pkgs.flatpak}/bin/flatpak remote-modify --system \
        flathub --url=https://mirrors.ustc.edu.cn/flathub || true
    '';
  };

  # Flathub 官方签名密钥落到 /etc（remote 的 gpg-import 需要一个文件路径）。
  # 用 pkgs.fetchurl 而非 builtins.fetchurl：前者是固定输出派生，参与构建图，
  # 不依赖求值期联网，也不需要 --impure。
  environment.etc."flatpak/flathub.gpg".source = pkgs.fetchurl {
    url = "https://flathub.org/repo/flathub.gpg";
    sha256 = "1amf8767ipfvyb31k7lr2s3i793s1vz5psqb8sb0g771qjmj1p4b";
  };
}
