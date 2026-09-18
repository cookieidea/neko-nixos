# 开发工具链（编辑器、语言运行时、Git、AI Agent、容器）
{ pkgs, lib, llm-agents-nix, ... }:

{
  home.packages = with pkgs; [
    vscodium
    (pkgs.lib.setPrio (-20) pkgs.zulu25)
    (pkgs.lib.setPrio (-15) pkgs.zulu21)
    (pkgs.lib.setPrio (-10) pkgs.zulu17)
    (pkgs.lib.setPrio (-5) pkgs.zulu8)
    (python3.withPackages (ps: [ ps.pip ]))   # python3 + pip
    uv                                        # uv（现代 Python 包/虚拟环境管理器）
    rustc                                     # rust 编译器
    cargo                                     # cargo 构建系统（CARGO_HOME=~/.cargo）
    rustfmt                                   # rust 格式化（cargo fmt 调用）
    go                                        # go 工具链（含 gofmt）
    gcc                                       # gcc/g++/ld/as/ar/nm/objdump/strip 等
    gnumake                                   # make
    pkg-config                                # 编译时查找库的 Cflags/Libs
    patchelf                                  # 改 ELF 的 interpreter/rpath（Nix 生态常用）
    gh                                        # GitHub CLI（推送流程靠它取 token）
    lazygit                                   # Git 终端 UI（TUI）
    glib                                      # gio/gsettings/gdbus (CLI 工具)
    nodejs_22                                 # Node.js 22 LTS（含 npm）
    pnpm                                      # pnpm（dsh 插件管理）
    llm-agents-nix.packages.${pkgs.stdenv.hostPlatform.system}.dsh      # DeepSeek Harness（AI agent 框架）
    # opencode 同源（不用 nixpkgs 的 1.15.10，比在用的 1.18.x 旧会降级）
    llm-agents-nix.packages.${pkgs.stdenv.hostPlatform.system}.opencode
    docker-compose                            # docker compose（配合 virtualisation.docker）
    distrobox                                 # distrobox（容器化发行版环境，需 docker/podman 后端）
    jq
    imagemagick
  ];
}
