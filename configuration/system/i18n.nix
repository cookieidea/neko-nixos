# 时区、locale、输入法（fcitx5 + rime-ice）
{ pkgs, ... }:

{
  time.timeZone = "Asia/Shanghai";
  i18n.defaultLocale = "zh_CN.UTF-8";

  # 输入法 fcitx5：rime + 雾凇拼音（rime-ice）。waylandFrontend（niri 走 text-input-v3）
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      waylandFrontend = true;
      addons = with pkgs; [
        (fcitx5-rime.override {
          rimeDataPkgs = [ rime-data rime-ice ];
        })
        # fcitx5-chinese-addons 不用：硬依赖 qtwebengine，其在 GCC 15 下编译崩溃
      ];
    };
  };
}
