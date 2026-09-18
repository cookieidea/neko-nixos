# 游戏（管理器、性能监控、MC 启动器、兼容层）
{ pkgs, bestclient, selfPackages, hmLib, ... }:

{
  home.packages = with pkgs; [
    lutris
    mangohud
    protonplus                                # protonplus（Proton 管理）
    mangojuice                                # mangojuice（GTK 文件管理器）
    hmLib.lunarclientWayland                       # lunar-client + SDL_VIDEO_DRIVER=wayland（见上方 let 块）
    bestclient.packages.${pkgs.stdenv.hostPlatform.system}.default
    selfPackages.bedrockboot          # BedrockBoot（MC 基岩版启动器，Avalonia；AppImage+FHS）
    selfPackages.purevox              # PureVox（实时 AI 音频降噪，AppImage 捆绑内嵌 Python，PipeWire 直用）
  ];
}
