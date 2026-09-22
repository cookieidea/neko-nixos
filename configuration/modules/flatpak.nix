# Flatpak：声明式管理 remote、应用与权限 override。
#
# 用 nix-flatpak（flake input）取代原先「systemd 脚本调 flatpak CLI」的写法 ——
# 那种写法属于运行时修改状态：回滚 NixOS generation 时 flatpak 内容不会跟着
# 回去，系统不再是完整的 transactional state。改由 Nix 描述后，remote / 应用 /
# override 都随 generation 回滚。
#
# 关于下载速度：实测各镜像（见 docs 或提交记录），USTC 的 flathub 镜像最快
# （~50-70 KB/s），而同期 USTC 的 ubuntu 镜像可达 950 KB/s —— 即瓶颈在
# flathub 镜像侧限速，不在本机带宽，换镜像收益有限。因此这里：
#   · 用 USTC 镜像（实测最快）
#   · 只在首次安装拉取，之后增量
#   · 服务异步执行，不阻塞登录
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
      # 权限管理：体积小，且后续排查沙箱问题必需。
      "com.github.tchx84.Flatseal"
    ];

    # 应用级权限：默认最小权限，只对确有必要者放宽。
    overrides = {
      settings = {
        # QQ / 微信：sandbox 内 fallback-x11 不可用，需真实 X11 socket。
        # 属兼容性妥协，仅这两个应用放宽，不设为全局默认。
        "com.qq.QQ".Context.sockets = [ "!fallback-x11" "x11" ];
        "com.tencent.WeChat".Context.sockets = [ "!fallback-x11" "x11" ];

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

  # Flathub 官方签名密钥落到 /etc（remote 的 gpg-import 需要一个文件路径）。
  # 用 pkgs.fetchurl 而非 builtins.fetchurl：前者是固定输出派生，参与构建图，
  # 不依赖求值期联网，也不需要 --impure。
  environment.etc."flatpak/flathub.gpg".source = pkgs.fetchurl {
    url = "https://flathub.org/repo/flathub.gpg";
    sha256 = "1amf8767ipfvyb31k7lr2s3i793s1vz5psqb8sb0g771qjmj1p4b";
  };
}
