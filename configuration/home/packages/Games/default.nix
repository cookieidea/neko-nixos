# 游戏（管理器、性能监控、MC 启动器、兼容层）
{ pkgs, bestclient, selfPackages, hmLib, ... }:

{
  home.packages = with pkgs; [
    lutris
    mangohud
    protonplus                                # protonplus（Proton 管理）
    mangojuice
    hmLib.lunarclientWayland                       # lunar-client + SDL_VIDEO_DRIVER=wayland
    bestclient.packages.${pkgs.stdenv.hostPlatform.system}.default
    # HMCL（Java 版 MC 启动器）：强制 Wayland + 补 MC natives 所需运行库
    # LD_PRELOAD 补 libstdc++（natives 的 NEEDED）；LD_LIBRARY_PATH 补
    # libjack（libopenal 的可选后端，运行时 dlopen，NEEDED 查不到）
    (pkgs.writeShellScriptBin "hmcl" ''
      export SDL_VIDEO_DRIVER=wayland
      export LD_PRELOAD="${pkgs.stdenv.cc.cc.lib}/lib/libstdc++.so.6''${LD_PRELOAD:+:$LD_PRELOAD}"
      export LD_LIBRARY_PATH="${hmLib.mcJavaLibPath}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
      exec ${pkgs.hmcl}/bin/hmcl "$@"
    '')
    (pkgs.runCommand "hmcl-assets" { } ''
      mkdir -p $out/share
      cp -r ${pkgs.hmcl}/share/applications $out/share/
      cp -r ${pkgs.hmcl}/share/icons $out/share/
    '')
    selfPackages.bedrockboot          # BedrockBoot（MC 基岩版启动器）
    selfPackages.purevox              # PureVox（实时 AI 音频降噪）
  ];
}
