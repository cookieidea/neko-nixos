{
  description = "Shorin Arch Setup (shorin-arch-setup) → NixOS + Home Manager conversion";

  # 国内二进制缓存（中科大 USTC 优先 + 清华 TUNA 兜底）。仅加速「包下载」，不影响 flake 源码拉取。
  # nixpkgs 源码走 TUNA git 镜像；home-manager/opencode TUNA 未镜像，走 github
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
    # nixpkgs 走官方 GitHub（浅克隆）。⚠️ 原用 TUNA git 镜像
    # （mirrors.tuna.tsinghua.edu.cn/git/nixpkgs.git），实体机实测
    # 2026-08-14 起该镜像 not found 不可达 → 回退官方，GitHub 可直连。
    nixpkgs.url = "git+https://github.com/NixOS/nixpkgs.git?ref=nixos-26.05&shallow=1";
    # home-manager TUNA 未镜像，用 git+https 直连 github（绕开 GitHub REST API 限流 403）
    home-manager = {
      url = "git+https://github.com/rycee/home-manager.git?ref=release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ── opencode（AI 编程 Agent，用 flake 装，拿最新版）──
    opencode = {
      url = "git+https://github.com/GutMutCode/opencode-nix.git";
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

  outputs = { self, nixpkgs, home-manager, opencode, bili-danmaku-tui, nix-cachyos-kernel, ... }:
    let
      system = "x86_64-linux";
      # ── 改这里 ──────────────────────────────────────────────
      username = "cookie";   # 你的用户名（也用于 home 目录 / autoLogin）
      hostname = "ATRI";
      desktop  = "niri";       # 当前仅 "niri"（niri + Noctalia）
      # ───────────────────────────────────────────────────────

      # 自构建程序（AUR `-git` / 私有仓库）的派生，见 ./pkgs
      pkgs = nixpkgs.legacyPackages.${system};
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
        # 把 opencode / bili-danmaku-tui 两个 flake 输入，以及自构建包传给 home 配置
        home-manager.extraSpecialArgs = { inherit desktop username opencode bili-danmaku-tui selfPackages; };
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
            {
              nixpkgs.overlays = [ nix-cachyos-kernel.overlays.pinned ];
            }
          ];
        };
      };
    };
}
