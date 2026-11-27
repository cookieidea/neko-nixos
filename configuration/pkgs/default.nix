# 自构建包的实际定义在独立仓库 cookieidea/nur-packages，
# 通过 flake input `neko-pkgs` 的 overlay 注入 pkgs。
# 此文件只维持原有的 public / internal 接口，供 hmLib 等内部引用。
{ pkgs }:

let
  public = {
    # 桌面和窗口管理。
    niri-sidebar = pkgs.niri-sidebar;
    pins = pkgs.pins;
    nyxniri-scratch-menu = pkgs.nyxniri-scratch-menu;

    # 工具和网络。
    ab-download-manager = pkgs.ab-download-manager;
    astral = pkgs.astral;

    # 影音和直播。
    obs-vdoninja = pkgs.obs-vdoninja;
    purevox = pkgs.purevox;

    # 游戏。
    bedrockboot = pkgs.bedrockboot;

    # 终端。
    tabby-terminal = pkgs.tabby-terminal;

    # 数据和字体。
    harmonyos-sans-sc = pkgs.harmonyos-sans-sc;

    # 文件管理器扩展。
    nautilus-image-converter = pkgs.nautilus-image-converter;
    nautilus-with-extensions = pkgs.nautilus-with-extensions;

    # 壁纸管理器（含 open-wallpaper-engine 场景插件）。
    waywallen = pkgs.waywallen;

    # VapourSynth 插件集：作为整体被 mpv / hmLib 使用，属成品。
    vapoursynth-with-plugins = pkgs.vapoursynth-with-plugins;
  };

  # 内部部件：只被上面的成品或 hmLib 引用。
  internal = {
    l-smash = pkgs.l-smash;
    vapoursynth-lsmash = pkgs.vapoursynth-lsmash;
    vapoursynth-akarin = pkgs.vapoursynth-akarin;
    vapoursynth-rife-ncnn = pkgs.vapoursynth-rife-ncnn;
    k7sfunc = pkgs.k7sfunc;

    markShotOcr = pkgs.markShotOcr;
    markShotScan = pkgs.markShotScan;
    markShotOcrHelper = pkgs.markShotOcrHelper;
    markShotScanHelper = pkgs.markShotScanHelper;
  };
in
public // internal // { inherit public internal; }
