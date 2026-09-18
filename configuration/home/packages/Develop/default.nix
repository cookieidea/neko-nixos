# 开发工具链（编辑器、语言运行时、Git、AI Agent、容器）
{ pkgs, lib, llm-agents-nix, ... }:

{
  home.packages = with pkgs; [
    vscodium
    (pkgs.lib.setPrio (-20) pkgs.zulu25)
    (pkgs.lib.setPrio (-15) pkgs.zulu21)
    (pkgs.lib.setPrio (-10) pkgs.zulu17)
    (pkgs.lib.setPrio (-5) pkgs.zulu8)
    (python3.withPackages (ps: [ ps.pip ]))
    uv                                        # uv（Python 包/虚拟环境管理器）
    rustc
    cargo                                     # cargo 构建系统
    rustfmt                                   # rustfmt 格式化
    go                                        # go 工具链
    gcc                                       # gcc/g++/ld 等
    gnumake
    pkg-config                                # pkg-config：编译时查库
    patchelf                                  # 改 ELF 的 interpreter/rpath
    gh                                        # GitHub CLI
    lazygit                                   # Git TUI
    glib                                      # gio/gsettings/gdbus CLI
    nodejs_22                                 # Node.js 22 LTS（含 npm）
    pnpm
    llm-agents-nix.packages.${pkgs.stdenv.hostPlatform.system}.dsh      # DeepSeek Harness（AI agent 框架）
    # opencode（与在用版本同源）
    llm-agents-nix.packages.${pkgs.stdenv.hostPlatform.system}.opencode
    docker-compose                            # docker compose
    distrobox                                 # distrobox（容器化发行版环境）
    jq
    imagemagick
  ];
}
