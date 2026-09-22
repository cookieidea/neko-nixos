{
  description = "ATRI —— 个人 NixOS + Home Manager 配置（niri 桌面）";

  nixConfig = {
    # 与 configuration/system/nix.nix 的 substituters 保持一致。
    # 这份 nixConfig 在**安装阶段就生效**（那时 system/nix.nix 尚未部署），
    # 自定义包的预构建依赖它命中缓存，缺项会导致源码编译。
    # 注意：本 flake 作为 input 被引用时 nixConfig 不生效（需 --accept-flake-config）。
    extra-substituters = [
      # nixpkgs 国内镜像。
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
      # 第三方输入对应的缓存。
      "https://attic.xuyh0120.win/lantian"    # nix-cachyos-kernel
      "https://noctalia.cachix.org"           # noctalia / noctalia-greeter
      "https://nekobox.cachix.org"            # 本仓库自建包
      "https://cache.numtide.com"             # llm-agents-nix
      "https://cook-nixvim.cachix.org"        # CookNixvim
      "https://nix-community.cachix.org"      # nix-community
    ];
    extra-trusted-public-keys = [
      "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      "nekobox.cachix.org-1:bRpp0vZK2Uq/vnydXC+uuOmFJW3W6fN4PI5PDy4iD+s="
      # numtide 的缓存（cache.numtide.com）即由该 key 签名 ——
      # key 名与 URL 不同属正常，已实测能验证其内容。
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      "cook-nixvim.cachix.org-1:LjCZ3VSYrcwTQxHpd834EIswdkfHoSd/EsKUYLRruF4="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
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

      # 这里的 pkgs 供 selfPackages 与 hmLib 使用。
      #
      # 配置必须与 NixOS 侧的 nixpkgs.config / nixpkgs.overlays 一致，
      # 否则会形成两个配置不同的 pkgs 实例：selfPackages 走一套，
      # 系统与 Home Manager（useGlobalPkgs）走另一套，排查版本差异时很难定位。
      #   · allowUnfree / rocmSupport 对应 system/nix.nix 的 nixpkgs.config
      #   · overlays 与 configuration/overlays/ 共用同一份 list.nix
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          rocmSupport = true;
        };
        overlays = import ./configuration/overlays/list.nix { inherit nix-cachyos-kernel; };
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
      # 只导出成品包（selfPackages.public），支持单独 nix build。
      # 内部部件（selfPackages.internal）仍可被引用，但不作为 flake 顶层包 ——
      # 安装脚本的预构建据此只构建真正的成品。
      packages.${system} = selfPackages.public;

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