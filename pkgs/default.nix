# 自构建包聚合（flake packages + hosts/ATRI/home.nix 安装，`nix build .#<name>` 单独构建）
# rev 固定已知 commit 保可复现，升级改 rev + sha256
#
# 按用途分类（参照 yigexuanmu/my-nixos-config 的 pkgs 组织方式）：
#   desktop/        桌面与窗口管理
#   tools/          工具（networking = 下载 / 组网）
#   media/          影音与直播
#   games/          游戏
#   terminal/       终端
#   data/           数据资源（fonts = 字体）
#   file-managers/  文件管理器扩展
#
# 注：noctalia-shell 来自 nixpkgs（home.nix 直接装），不在这里
{ pkgs, astral-bundle }:
let
  vsPlugins = import ./media/vs-plugins { inherit pkgs; };
in
rec {
  # --- 影音：VapourSynth 插件集（mpv RIFE 补帧依赖）---
  inherit (vsPlugins)
    l-smash
    vapoursynth-lsmash
    vapoursynth-akarin
    vapoursynth-rife-ncnn
    k7sfunc
    vapoursynth-with-plugins;

  # --- 桌面与窗口管理 ---
  niri-sidebar         = import ./desktop/niri-sidebar   { inherit pkgs; };
  pins                 = import ./desktop/pins           { inherit pkgs; };
  shorin-contrib       = import ./desktop/shorin-contrib { inherit pkgs; };
  nyxniri-scratch-menu = import ./desktop/nyxniri-scratch-menu { inherit pkgs; };

  # --- 工具 / 网络 ---
  ab-download-manager  = import ./tools/networking/ab-download-manager { inherit pkgs; };
  # astral 的 bundle 由 pkgs/tools/networking/astral/build.sh 联网构建（flake 输入 astral-bundle）
  astral               = import ./tools/networking/astral { inherit pkgs; lib = pkgs.lib; src = astral-bundle; };

  # --- 影音 / 直播 ---
  splayer-next         = import ./media/splayer-next { inherit pkgs; };
  obs-vdoninja         = import ./media/obs-vdoninja { inherit pkgs; };
  purevox              = import ./media/purevox      { inherit pkgs; };

  # --- 游戏 ---
  bedrockboot          = import ./games/bedrockboot { inherit pkgs; };

  # --- 终端 ---
  tabby-terminal       = import ./terminal/tabby { inherit pkgs; };

  # --- 资源 / 字体 ---
  harmonyos-sans-sc    = import ./data/fonts/harmonyos-sans-sc { inherit pkgs; };

  # --- 文件管理器扩展（image-converter C 扩展 + video-audio-streams Python 扩展）---
  nautilus-extensions  = import ./file-managers/nautilus-extensions { inherit pkgs; };
}
