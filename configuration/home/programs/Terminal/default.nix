# 终端与 CLI/TUI 工具（shell、提示符、文件浏览、系统监视、终端模拟器）
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    fish
    starship
    eza
    zoxide
    bat
    btop
    yazi
    fd                                        # fd（find 替代）
    fastfetch
    timg
    cava                                       # 音频可视化
    cmatrix lolcat sl                          # 彩蛋趣味命令
  ];
}
