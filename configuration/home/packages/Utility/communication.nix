# 即时通讯客户端。
{ pkgs, ... }:

let
  # 微信在 bwrap 沙箱内运行（AppImage + XWayland），没有走 Wayland 原生的
  # text-input 协议，因此需要 GTK_IM_MODULE 才能加载 fcitx immodule 输入中文。
  #
  # 这里用 wrapper 只为该程序注入，而不是设成全局会话变量 ——
  # 全局强制 immodule 会让 Wayland 原生程序绕开 text-input 协议，
  # fcitx5 会因此发出「Wayland 诊断」告警。
  # 与仓库既有的故障域限定做法一致（见 home/lib/runtime.nix 的 mpv / lunarclient）。
  wechatWithIme = pkgs.symlinkJoin {
    name = "wechat-with-ime";
    paths = [ pkgs.wechat ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      rm -f $out/bin/wechat
      makeWrapper ${pkgs.wechat}/bin/wechat $out/bin/wechat \
        --set GTK_IM_MODULE fcitx \
        --set QT_IM_MODULE fcitx \
        --set XMODIFIERS @im=fcitx
    '';
  };
in
{
  home.packages = with pkgs; [
    ayugram-desktop   # Telegram（AyuGram 分支）

    # 微信：nixpkgs 包（原为 flatpak），外面套一层输入法 wrapper。
    # 注意 wechat 与 wechat-uos 是两个不同包：此处按需求用 wechat。
    wechatWithIme

    # QQ 暂时无法启用：nixpkgs 的 qq 固定到 2026-05-28 的构建，
    # 而腾讯已下架该 deb（URL 404，官方页与 web.archive.org 均无）。
    # 待 nixpkgs 更新 sources.nix 后再加入 qq。
    # qq
  ];
}
