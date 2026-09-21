{
  description = "Shorin Arch Setup (shorin-arch-setup) → NixOS + Home Manager conversion";

  # 国内二进制缓存（USTC 优先 + TUNA 兜底）；nixpkgs 源码走 USTC tarball，其余输入走 github。
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
    # nixpkgs 走国内镜像的 git 浅克隆（NJU 主选，TUNA 备选）：
    # 仍是真正的 git 输入 → flake.lock 锁 rev + narHash，不漂移；
    # 下载源在国内，不依赖 GitHub 可达性。更新：nix flake update nixpkgs
    nixpkgs.url = "git+https://mirrors.nju.edu.cn/git/nixpkgs.git?ref=nixos-26.05&shallow=1";
    # 备选：nixpkgs.url = "git+https://mirrors.tuna.tsinghua.edu.cn/git/nixpkgs.git?ref=nixos-26.05&shallow=1";
    # home-manager：GitCode 镜像（国内，分支与 GitHub 同步，rev 不变则 narHash 沿用）；
    # 注意上游官方地址已从 rycee/ 迁到 nix-community/，此处一并校正。
    home-manager = {
      url = "git+https://gitcode.com/nix-community/home-manager.git?ref=release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    cooknixvim = {
      url = "git+https://github.com/Youthdreamer/CookNixvim";
    };

    # B 站直播弹幕阅读器（PyQt6 + layer-shell，游戏全屏时浮窗显示）
    # 上游 flake 基于 nixos-unstable；follows 后其打包定义用我们的 nixpkgs 求值
    bilihud = {
      url = "github:locez/bilihud";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ⚠️ CachyOS 内核：不要 follows nixpkgs（补丁需匹配其 pin 的 nixpkgs 才能命中缓存）
    nix-cachyos-kernel = {
      url = "git+https://github.com/xddxdd/nix-cachyos-kernel?ref=release";
    };

    # ⚠️ Noctalia：cachix 分支（命中官方缓存）；不要 follows nixpkgs
    noctalia = {
      url = "git+https://github.com/noctalia-dev/noctalia.git?ref=cachix";
    };

    noctalia-greeter = {
      url = "git+https://github.com/noctalia-dev/noctalia-greeter?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ⚠️ Astral 构建需联网（沙箱内无法完成），走 build.sh 产物；path 输入不入 git，换机需先跑 build.sh
    astral-bundle = {
      url = "path:/home/cookie/.cache/astral/bundle";
      flake = false;
    };

    # agenix：age 加密的声明式 secrets（GitCode 镜像）
    agenix = {
      url = "git+https://gitcode.com/ryantm/agenix.git?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # BestClient（DDNet fork）：官方 flake 打包预编译版
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

    # Denial：Flutter 原生 Wayland 合成器（可选登录会话，与 niri 并存）
    # 不 follows nixpkgs：其 Flutter 引擎须匹配上游 pin 的 nixpkgs 才命中官方缓存
    # （否则需源码构建，上游称需 64G+ 空间）
    denial = {
      url = "github:denialwm/denial";
    };
  };

  outputs = { self, nixpkgs, home-manager, cooknixvim, bilihud, nix-cachyos-kernel, noctalia, noctalia-greeter, agenix, bestclient, astral-bundle, mark-shot, llm-agents-nix, denial, ... }:
    let
      system = "x86_64-linux";
      username = "cookie";   # 你的用户名（用于 home 目录 / autoLogin）
      hostname = "ATRI";
      desktop  = "niri";

      # 自构建程序派生（见 ./configuration/pkgs）。显式 import nixpkgs 带 allowUnfree（unfree 包评估
      # 需要 nixpkgs.config，legacyPackages 裸实例会拒）；仅作用于 selfPackages。
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      selfPackages = import ./configuration/pkgs { inherit pkgs astral-bundle; };

      # home 模块共用绑定（原 home.nix 顶部 let 块）→ 注入为 hmLib
      hmLib = import ./configuration/home/lib.nix { inherit pkgs selfPackages username; };

      hmModule = {
        imports = [ home-manager.nixosModules.home-manager ];

        _module.args = { inherit desktop username selfPackages bestclient; };

        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users.${username} = import ./configuration/ATRI/home.nix;
        home-manager.extraSpecialArgs = { inherit desktop username cooknixvim bilihud selfPackages noctalia bestclient mark-shot llm-agents-nix hmLib; };
      };
    in {
      # 暴露自构建派生为 flake 包：可单独 `nix build .#<name>`
      packages.${system} = selfPackages;

      nixosConfigurations = {
        # 实体机；硬件配置见 configuration/device/hardware/hardware-config.nix（需 git add）
        ${hostname} = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit noctalia-greeter denial; };
          modules = [
            ./configuration/ATRI/system.nix
            hmModule
            agenix.nixosModules.default
            # CachyOS 内核 overlay（pinned 命中缓存）+ 修 nvim.desktop：
            # 原版 Terminal=true 图形启动器打不开 → 覆盖为 kitty 打开
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
