{
  description = "ATRI —— 个人 NixOS + Home Manager 配置（niri 桌面）";

  nixConfig = {
    extra-substituters = [
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
      "https://attic.xuyh0120.win/lantian"
      "https://noctalia.cachix.org"
      "https://nekobox.cachix.org"
    ];
    extra-trusted-public-keys = [
      "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      "nekobox.cachix.org-1:bRpp0vZK2Uq/vnydXC+uuOmFJW3W6fN4PI5PDy4iD+s="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };

  inputs = {
    # nixpkgs 使用国内 Git 镜像，锁定的 rev 仍由 flake.lock 保证。
    nixpkgs.url = "git+https://mirrors.nju.edu.cn/git/nixpkgs.git?ref=nixos-26.05&shallow=1";
    # Home Manager 使用镜像地址；上游仓库已迁移到 nix-community。
    home-manager = {
      url = "git+https://gitcode.com/nix-community/home-manager.git?ref=release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    cooknixvim = {
      url = "git+https://github.com/Youthdreamer/CookNixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # bilihud：B 站直播弹幕浮窗。
    bilihud = {
      url = "github:locez/bilihud";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # CachyOS 内核使用项目自身固定的 nixpkgs。
    nix-cachyos-kernel = {
      url = "git+https://github.com/xddxdd/nix-cachyos-kernel?ref=release";
    };

    # Noctalia 使用官方 Cachix 分支。
    noctalia = {
      url = "git+https://github.com/noctalia-dev/noctalia.git?ref=cachix";
    };

    noctalia-greeter = {
      url = "git+https://github.com/noctalia-dev/noctalia-greeter?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # agenix：声明式 age secrets。
    agenix = {
      url = "git+https://gitcode.com/ryantm/agenix.git?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # BestClient：预编译 DDNet fork。
    bestclient = {
      url = "git+https://github.com/BestProjectTeam/BestClient";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mark-shot = {
      url = "git+https://github.com/jswysnemc/mark-shot";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    llm-agents-nix = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, cooknixvim, bilihud, nix-cachyos-kernel, noctalia, noctalia-greeter, agenix, bestclient, mark-shot, llm-agents-nix, ... }:
    let
      system = "x86_64-linux";
      forAllSystems = nixpkgs.lib.genAttrs [ system ];
      username = "cookie";   # 你的用户名（用于 home 目录 / autoLogin）
      hostname = "ATRI";
      desktop  = "niri";

      # 自构建包显式启用 allowUnfree，只影响 selfPackages。
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      selfPackages = import ./configuration/pkgs { inherit pkgs; };

      # Home 模块共享库。
      hmLib = import ./configuration/home/lib.nix { inherit pkgs selfPackages username; };

      hmModule = {
        imports = [ home-manager.nixosModules.home-manager ];

        _module.args = { inherit desktop username selfPackages bestclient; };

        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users.${username} = import ./configuration/home.nix;
        home-manager.extraSpecialArgs = { inherit desktop username cooknixvim bilihud selfPackages noctalia bestclient mark-shot llm-agents-nix hmLib; };
      };
    in {
      # 导出自构建包，支持单独 nix build。
      packages.${system} = selfPackages;

      nixosConfigurations = {
        # 实体机配置。硬件文件由安装目标机生成。
        ${hostname} = nixpkgs.lib.nixosSystem {
          inherit system;
          # hostname 由上方 let 绑定提供（单一数据源），供 system/ 下模块引用
          specialArgs = { inherit hostname noctalia-greeter; };
          modules = [
            ./configuration/system.nix
            hmModule
            agenix.nixosModules.default
            # 平台 overlays。
            (import ./configuration/overlays { inherit nix-cachyos-kernel; })
          ];
        };
      };

      # Nix 格式化器。
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt);

      # 静态检查只覆盖仓库自维护的 Nix 配置。
      # deadnix 检查未使用绑定；statix 保持非阻塞使用。
      checks = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          # 只检查本仓库维护的配置。
          targets = "configuration/system configuration/modules configuration/home configuration/overlays flake.nix";
        in {
          deadnix = pkgs.runCommand "deadnix-check"
            { nativeBuildInputs = [ pkgs.deadnix ]; } ''
            cd ${./.}
            deadnix --fail --no-underscore ${targets}
            touch $out
          '';
        });
    };
}