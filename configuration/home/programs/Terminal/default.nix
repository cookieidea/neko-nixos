# 终端与 CLI/TUI 工具（shell、提示符、文件浏览、系统监视、终端模拟器）
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    fish
    starship
    eza
    zoxide
    bat
    btop                                      # btop（DE 无关，常驻）
    yazi
    fd                                        # fd（find 替代，neovim/telescope 生态常用）
    fastfetch
    timg
    cava                                       # 音频可视化（终端彩蛋，原 04k TERM_PKGS）
    cmatrix lolcat sl                          # 彩蛋趣味命令（原 02b 安装）
  ];
}
