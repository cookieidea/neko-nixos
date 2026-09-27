# 即时通讯客户端。
{ pkgs, ... }:

let
  # 微信（AppImage + XWayland）的输入法环境，仅注入该程序。
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

      # QQ 暂不可用：nixpkgs 固定的下载 URL 已被腾讯下架。
  ];
}
