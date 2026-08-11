{
  description = "Shorin Arch Setup (shorin-arch-setup) → NixOS + Home Manager conversion";

  inputs = {
    # 国内镜像（清华 TUNA git 镜像，加速 nixpkgs / home-manager 源码拉取）
    nixpkgs.url = "git+https://mirrors.tuna.tsinghua.edu.cn/git/nixpkgs.git?ref=nixos-26.05";
    home-manager = {
      url = "git+https://mirrors.tuna.tsinghua.edu.cn/git/home-manager.git?ref=release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ── nixvim：Neovim 的配置框架（替代 neovim + lazyvim）──
    # 用 nixos-26.05 分支以匹配下面的 nixpkgs 26.05。
    # 官方建议不要 follows nixpkgs，让它用自己 pin 的 revision。
    nixvim = {
      url = "github:nix-community/nixvim/nixos-26.05";
    };

    # ── Noctalia：Wayland 桌面 shell（状态栏/启动器/通知/锁屏…）──
    # 支持 niri / Hyprland / Sway / Labwc 等 compositor。
    # ⚠️ 固定到 v4：v4 配置是 JSON（~/.config/noctalia/settings.json +
    #    plugins.json + colors.json + user-templates.toml），由 Home Manager
    #    通过 xdg.configFile 部署（见 home.nix）。
    #    v5 改成单一 TOML（config.toml），与 v4 JSON 不兼容；这里换回 v4。
    #    v4.7.7 是 v4 最后一个稳定版；如需跟踪 frozen 分支可用 legacy-v4。
    noctalia = {
      url = "github:noctalia-dev/noctalia/v4.7.7";
    };

    # ── opencode（AI 编程 Agent，用 flake 装，拿最新版）──
    opencode = {
      url = "github:GutMutCode/opencode-nix";
    };
  };

  outputs = { self, nixpkgs, home-manager, nixvim, noctalia, opencode, ... }:
    let
      system = "x86_64-linux";
      # ── 改这里 ──────────────────────────────────────────────
      username = "cookie";   # 你的用户名（也用于 home 目录 / autoLogin）
      hostname = "nixos";
      desktop  = "niri";       # 当前仅 "niri"（niri + Noctalia）
      # ───────────────────────────────────────────────────────

      # 自构建程序（AUR `-git` / 私有仓库）的派生，见 ./pkgs
      pkgs = nixpkgs.legacyPackages.${system};
      selfPackages = import ./pkgs { inherit pkgs; };
    in {
      # 暴露自构建派生为 flake 包：可单独 `nix build .#<name>`
      packages.${system} = selfPackages;

      nixosConfigurations.${hostname} = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./configuration.nix
          home-manager.nixosModules.home-manager
          {
            _module.args = { inherit desktop username; };

            # Home Manager 集成
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.${username} = import ./home.nix;
            # 把 nixvim / noctalia / opencode 三个 flake 输入，以及自构建包传给 home 配置
            home-manager.extraSpecialArgs = { inherit desktop username nixvim noctalia opencode selfPackages; };
          }
        ];
      };
    };
}
