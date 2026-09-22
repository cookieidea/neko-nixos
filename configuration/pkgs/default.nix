# 自构建包聚合。
#
# 分为两组：
#   public    —— 用户可直接 `nix build .#<name>` 的成品，也是 flake 的
#                packages.<system> 输出（见 flake.nix）。
#   internal  —— 仅被其他派生引用的构建部件（如 vapoursynth 的各插件、
#                mark-shot 的 Python 运行环境）。它们仍可被引用，但不再
#                出现在 flake 顶层，安装脚本的预构建也就不会把它们当成
#                独立成品逐个构建。
#
# 顶层仍扁平展开两组属性（末尾的 // internal），这样消费方依旧写
# selfPackages.k7sfunc，无需改成 selfPackages.internal.k7sfunc。
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
