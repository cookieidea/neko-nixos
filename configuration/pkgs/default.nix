# 自构建包：public 进 flake 顶层，internal 只供内部引用。
{ pkgs }:
let
  vsPlugins = import ./media/vs-plugins { inherit pkgs; };
  markShotPython = import ./tools/mark-shot-python { inherit pkgs; };

  # 成品：会被装进用户环境或系统，或用户可能单独构建。
  public = {
    # 桌面和窗口管理。
    niri-sidebar         = import ./desktop/niri-sidebar   { inherit pkgs; };
    pins                 = import ./desktop/pins           { inherit pkgs; };
    nyxniri-scratch-menu = import ./desktop/nyxniri-scratch-menu { inherit pkgs; };

    # 工具和网络。
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
    inherit (import ./file-managers/nautilus-extensions { inherit pkgs; })
      nautilus-image-converter
      nautilus-with-extensions;

    # VapourSynth 插件集：作为整体被 mpv / hmLib 使用，属成品。
    inherit (vsPlugins) vapoursynth-with-plugins;
  };

  # 内部部件：只被上面的成品或 hmLib 引用。
  internal = {
    inherit (vsPlugins)
      l-smash
      vapoursynth-lsmash
      vapoursynth-akarin
      vapoursynth-rife-ncnn
      k7sfunc;

    inherit (markShotPython)
      markShotOcr
      markShotScan
      markShotOcrHelper
      markShotScanHelper;
  };
in
public // internal // { inherit public internal; }
