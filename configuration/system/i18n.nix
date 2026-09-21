# 时区、locale 和输入法。
{ pkgs, ... }:

{
  time.timeZone = "Asia/Shanghai";
  i18n.defaultLocale = "zh_CN.UTF-8";

  # Fcitx5 + Rime / 雾凇拼音。
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      waylandFrontend = true;
      addons = with pkgs; [
        (fcitx5-rime.override {
          rimeDataPkgs = [ rime-data rime-ice ];
        })
        # 不使用 fcitx5-chinese-addons：其 QtWebEngine 依赖在当前工具链下无法构建。
      ];
    };
  };
}
