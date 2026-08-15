{
  description = "Shorin Arch Setup (shorin-arch-setup) → NixOS + Home Manager conversion";

  # 国内二进制缓存（中科大 USTC 优先 + 清华 TUNA 兜底）。仅加速「包下载」，不影响 flake 源码拉取。
  # nixpkgs 源码走 TUNA nix-channels；home-manager/nixvim/opencode TUNA 未镜像，走 github
  # （慢但可用；若 github 被墙可加代理或换镜像）。
  nixConfig = {
    extra-substituters = [
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
      "https://attic.xuyh0120.win/lantian"
    ];
    extra-trusted-public-keys = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" ];
  };

  inputs = {
    # nixpkgs 源码走清华 TUNA 通道 tarball（nix-channels 镜像，含 flake.nix 可作
    # flake 输入）。⚠️ 不要用 TUNA git 镜像（git/nixpkgs.git 实体机 2026-08-14
    # 实测 not found），但 nix-channels 的 nixos-26.05/nixexprs.tar.xz 可用（200）。
    # 更新 nixpkgs：`nix flake update nixpkgs --accept-flake-config`（tarball 锁定 narHash）。
    nixpkgs.url = "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/nixos-26.05/nixexprs.tar.xz";
    # home-manager TUNA 未镜像，用 git+https 直连 github（绕开 GitHub REST API 限流 403）
    home-manager = {
      url = "git+https://github.com/rycee/home-manager.git?ref=release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ── CookNixvim：模块化 Neovim 配置（基于 nix-community/nixvim）──
    # 用其 flake 构建产物 packages.<sys>.default 作为 nvim（配置内嵌在它仓库的 config/）。
    # 注意：它自带 nixpkgs-unstable 与 nixvim（unstable）输入，首次构建会拉 GitHub 大包。
    cooknixvim = {
      url = "github:Youthdreamer/CookNixvim";
    };

    # ── opencode（AI 编程 Agent）──
    # 官方 flake（github:sst/opencode，dev 分支持续构建最新版）；
    # 之前用 GutMutCode/opencode-nix 第三方包装，其内部 pin 固定版本 → 版本太旧
    opencode = {
      url = "github:sst/opencode";
    };

    # ── bili-danmaku-tui（B 站直播间弹幕 TUI，Go/bubbletea）──
    # 自带 flake.nix（buildGoModule，vendorHash 已锁）；follows nixpkgs 复用本地镜像源
    bili-danmaku-tui = {
      url = "git+https://github.com/Youthdreamer/bili-danmaku-tui.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ── CachyOS 内核（xddxdd/nix-cachyos-kernel）──
    # release 分支带二进制缓存（attic.xuyh0120.win/lantian，国内快）；
    # ⚠️ 官方明确不要 follows nixpkgs（补丁与内核版本需匹配其 pin 的 nixpkgs）
    nix-cachyos-kernel = {
      url = "git+https://github.com/xddxdd/nix-cachyos-kernel?ref=release";
    };
  };

  outputs = { self, nixpkgs, home-manager, cooknixvim, opencode, bili-danmaku-tui, nix-cachyos-kernel, ... }:
    let
      system = "x86_64-linux";
      # ── 改这里 ──────────────────────────────────────────────
      username = "cookie";   # 你的用户名（也用于 home 目录 / autoLogin）
      hostname = "ATRI";
      desktop  = "niri";       # 当前仅 "niri"（niri + Noctalia）
      # ───────────────────────────────────────────────────────

      # 自构建程序（AUR `-git` / 私有仓库）的派生，见 ./pkgs
      # ⚠️ 不能用 legacyPackages（裸实例不带 nixpkgs.config）：unfree 包
      #    （bedrockboot/axolotl 等标 unfreeRedistributable）评估会被拒。
      #    用 import nixpkgs 显式带 config.allowUnfree（仅作用于 selfPackages，
      #    不覆盖系统级配置——系统级仍由 configuration.nix 的 nixpkgs.config 管）。
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      selfPackages = import ./pkgs { inherit pkgs; };

      # 公共 Home Manager 集成模块（nixos 实体机配置用）
      hmModule = {
        # 必须先 import home-manager 的 NixOS 模块，home-manager.* 选项才有定义
        imports = [ home-manager.nixosModules.home-manager ];

        _module.args = { inherit desktop username selfPackages; };

        # Home Manager 集成
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users.${username} = import ./home.nix;
        # 把 cooknixvim / opencode / bili-danmaku-tui 三个 flake 输入，以及自构建包传给 home 配置
        home-manager.extraSpecialArgs = { inherit desktop username cooknixvim opencode bili-danmaku-tui selfPackages; };
      };
    in {
      # 暴露自构建派生为 flake 包：可单独 `nix build .#<name>`
      packages.${system} = selfPackages;

      nixosConfigurations = {
        # ── 实体机（btrfs + GRUB + snapper + 休眠）──
        # hardware-configuration.nix 由 `nixos-generate-config --root /mnt` 在目标机生成，
        # 需 `git add hardware-configuration.nix` 后才会被 flake 包含。
        ${hostname} = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./hardware-configuration.nix
            ./configuration.nix
            hmModule
            # CachyOS 内核 overlay（pinned：固定其 nixpkgs rev 以命中二进制缓存）
            # + 修 neovim 包自带的 nvim.desktop（Name=Neovim wrapper）：
            #   原版 Terminal=true + Exec=nvim，图形启动器拉起时缺终端处理器打不开
            #   → 覆盖为 Terminal=false + Exec=kitty -e nvim %F（直接调 kitty 打开）
            {
              nixpkgs.overlays = [
                nix-cachyos-kernel.overlays.pinned
                (final: prev: {
                  neovim = prev.neovim.overrideAttrs (old: {
                    postInstall = (old.postInstall or "") + ''
                      rm -f "$out/share/applications/nvim.desktop"
                      cat > "$out/share/applications/nvim.desktop" <<'DESKTOP'
[Desktop Entry]
Name=Neovim wrapper
GenericName=Text Editor
Comment=Edit text files
TryExec=nvim
Exec=kitty -e nvim %F
Icon=nvim
Type=Application
Terminal=false
Categories=Utility;TextEditor;Development;
MimeType=text/plain;text/x-makefile;application/x-shellscript;text/x-c;text/x-c++src;
StartupNotify=false
DESKTOP
                    '';
                  });
                })
              ];
            }
          ];
        };
      };
    };
}
