{
  description = "Shorin Arch Setup (shorin-arch-setup) → NixOS + Home Manager conversion";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
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
    noctalia = {
      url = "github:noctalia-dev/noctalia";
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
    in {
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
            # 把 nixvim / noctalia / opencode 三个 flake 输入传给 home 配置
            home-manager.extraSpecialArgs = { inherit desktop username nixvim noctalia opencode; };
          }
        ];
      };
    };
}
