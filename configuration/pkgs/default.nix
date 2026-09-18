# 自构建包聚合（按用途分类在 desktop/tools/media/games/terminal/data/file-managers）
{ pkgs, astral-bundle }:
let
  vsPlugins = import ./media/vs-plugins { inherit pkgs; };
in
rec {
  # VapourSynth 插件集（mpv RIFE 补帧）
  inherit (vsPlugins)
    l-smash
    vapoursynth-lsmash
    vapoursynth-akarin
    vapoursynth-rife-ncnn
    k7sfunc
    vapoursynth-with-plugins;

  # 桌面与窗口管理
  niri-sidebar         = import ./desktop/niri-sidebar   { inherit pkgs; };
  pins                 = import ./desktop/pins           { inherit pkgs; };
  shorin-contrib       = import ./desktop/shorin-contrib { inherit pkgs; };
  nyxniri-scratch-menu = import ./desktop/nyxniri-scratch-menu { inherit pkgs; };

  # 工具 / 网络
  ab-download-manager  = import ./tools/networking/ab-download-manager { inherit pkgs; };
  astral               = import ./tools/networking/astral { inherit pkgs; lib = pkgs.lib; src = astral-bundle; };

  # 影音 / 直播
  splayer-next         = import ./media/splayer-next { inherit pkgs; };
  obs-vdoninja         = import ./media/obs-vdoninja { inherit pkgs; };
  purevox              = import ./media/purevox      { inherit pkgs; };

  # 游戏
  bedrockboot          = import ./games/bedrockboot { inherit pkgs; };

  # 终端
  tabby-terminal       = import ./terminal/tabby { inherit pkgs; };

  # 资源 / 字体
  harmonyos-sans-sc    = import ./data/fonts/harmonyos-sans-sc { inherit pkgs; };

  # 文件管理器扩展
  nautilus-extensions  = import ./file-managers/nautilus-extensions { inherit pkgs; };
}
