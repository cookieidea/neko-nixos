# Axolotl —— Minecraft Java 版启动器（替代 Prism Launcher / HMCL）
#
# 2026-08 起改为官方源码构建（vendored 自上游 PR #298 bfmhno3 的 nix 方案，
# 构建细节见同目录 src.nix）：Rust/Tauri + pnpm 前端 + Java 引擎全部从
# 官方仓库源码编译，外层 symlinkJoin + wrapGAppsHook 已带 flite/udev/alsa/jack/
# pulse/pipewire/jdk8/17/21/25 全套运行时（runtimeDependencies + PATH 注入）
# 以及启动器/游戏所需环境变量（SDL Wayland / WebKit 降级 / JNA flite 路径，
# 见 src.nix postBuild），桌面项与命令行均生效。
#
# 这里只是把源码包合并进 home 环境，并提供一个 `axolotl` 便捷命令。
#
# ⚠️ 升级：改 src.nix 的 src.rev/sha256（+cargoHash/pnpm hash 视锁文件而定）。
{ pkgs, rustToolchain }:

let
  inherit (pkgs) lib;
  srcPkg = import ./src.nix { inherit pkgs rustToolchain; };
  alias = pkgs.writeShellScriptBin "axolotl" ''
    exec '${srcPkg}/bin/Axolotl Launcher' "$@"
  '';
in
pkgs.symlinkJoin {
  name = "axolotl";
  paths = [
    alias
    srcPkg
  ];
  passthru = {
    inherit (srcPkg) gradle-deps-update;
  };
}
