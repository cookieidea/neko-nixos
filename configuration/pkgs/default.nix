# 自构建包聚合。
{ pkgs }:
let
  vsPlugins = import ./media/vs-plugins { inherit pkgs; };
in
# 非 rec：块内各属性互不引用（全部是独立的 import / inherit）。
# 若日后新增属性间引用（如 A 的取值用到 B），需改回 rec。
{
  # VapourSynth / RIFE。
  inherit (vsPlugins)
    l-smash
    vapoursynth-lsmash
    vapoursynth-akarin
    vapoursynth-rife-ncnn
    k7sfunc
    vapoursynth-with-plugins;

  # 桌面和窗口管理。
  niri-sidebar         = import ./desktop/niri-sidebar   { inherit pkgs; };
  pins                 = import ./desktop/pins           { inherit pkgs; };
  nyxniri-scratch-menu = import ./desktop/nyxniri-scratch-menu { inherit pkgs; };

  # 工具和网络。
  # mark-shot Python 环境。
  inherit (import ./tools/mark-shot-python { inherit pkgs; })
    markShotOcr
    markShotScan;

  ab-download-manager  = import ./tools/networking/ab-download-manager { inherit pkgs; };
  astral               = import ./tools/networking/astral { inherit pkgs; lib = pkgs.lib; fetchurl = pkgs.fetchurl; };

  # 影音和直播。
  splayer-next         = import ./media/splayer-next { inherit pkgs; };
  obs-vdoninja         = import ./media/obs-vdoninja { inherit pkgs; };
  purevox              = import ./media/purevox      { inherit pkgs; };

  # 游戏。
  bedrockboot          = import ./games/bedrockboot { inherit pkgs; };

  # 终端。
  tabby-terminal       = import ./terminal/tabby { inherit pkgs; };

  # 数据和字体。
  harmonyos-sans-sc    = import ./data/fonts/harmonyos-sans-sc { inherit pkgs; };

  # 文件管理器扩展。
  # 此处平铺导出 derivation，供 flake packages 直接消费。
  inherit (import ./file-managers/nautilus-extensions { inherit pkgs; })
    nautilus-image-converter
    nautilus-with-extensions;
}
