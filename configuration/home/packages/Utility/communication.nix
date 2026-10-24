# 即时通讯客户端。
{ pkgs, selfPackages, ... }:

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

  # QQ 走 Wayland（XWayland 下输入框吞字）：只对 QQ 设 NIXOS_OZONE_WL，
  # 避免影响其他 Electron 应用。nixpkgs 的 qq wrapper 见到该变量会自行
  # 追加 --ozone-platform=wayland --enable-wayland-ime 等一整组参数。
  # LD_PRELOAD 修语音延迟：QQ 的语音引擎（libAVSDKPlugin.so）打开麦克风
  # 时 attr 传 NULL，pipewire-pulse 默认给 2 秒分片，对方听感 3 秒+；
  # 拦截后按 30ms 分片。仅作用于该引擎且未指定 fragsize 的录音流。
  qqWithWayland = pkgs.symlinkJoin {
    name = "qq-wayland";
    paths = [ pkgs.qq ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      rm -f $out/bin/qq
      makeWrapper ${pkgs.qq}/bin/qq $out/bin/qq \
        --set NIXOS_OZONE_WL 1 \
        --prefix LD_PRELOAD : ${selfPackages.qq-voice-latency}/lib/libqq-voice-latency.so

      # desktop entry 在 qq 包里是只读软链，需先删掉再生成指向本 wrapper 的实体。
      rm -f $out/share/applications/qq.desktop
      sed "s|${pkgs.qq}/bin/qq|$out/bin/qq|" \
        ${pkgs.qq}/share/applications/qq.desktop \
        > $out/share/applications/qq.desktop
      chmod 644 $out/share/applications/qq.desktop
    '';
  };
in
{
  home.packages = with pkgs; [
    ayugram-desktop   # Telegram（AyuGram 分支）
    qqWithWayland     # QQ（原 flatpak）

    # 微信：nixpkgs 包（原为 flatpak），外面套一层输入法 wrapper。
    # 注意 wechat 与 wechat-uos 是两个不同包：此处按需求用 wechat。
    wechatWithIme
  ];
}
