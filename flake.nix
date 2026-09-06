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

    opencode = {
      url = "git+https://github.com/sst/opencode?rev=04284921ac8f657555b5a182f5ff055f471543e4";
    };

    bili-danmaku-tui = {
      url = "git+https://github.com/Youthdreamer/bili-danmaku-tui.git";
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

    # rust-overlay：GitCode 镜像（国内；Axolotl 需 Rust 1.95，仅作用于 selfPackages 实例）
    rust-overlay = {
      url = "git+https://gitcode.com/oxalica/rust-overlay.git?ref=master";
      inputs.nixpkgs.follows = "nixpkgs";
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
  };

  outputs = { self, nixpkgs, home-manager, cooknixvim, opencode, bili-danmaku-tui, nix-cachyos-kernel, noctalia, noctalia-greeter, rust-overlay, astral-bundle, ... }:
    let
      system = "x86_64-linux";
      username = "cookie";   # 你的用户名（用于 home 目录 / autoLogin）
      hostname = "ATRI";
      desktop  = "niri";

      # 自构建程序派生（见 ./pkgs）。显式 import nixpkgs 带 allowUnfree（unfree 包评估
      # 需要 nixpkgs.config，legacyPackages 裸实例会拒）；仅作用于 selfPackages。
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [ rust-overlay.overlays.default ];   # Axolotl 需 Rust 1.95
      };
      rustToolchain = pkgs.rust-bin.fromRustupToolchainFile ./pkgs/axolotl/rust-toolchain.toml;

      selfPackages = import ./pkgs { inherit pkgs rustToolchain astral-bundle; };

      hmModule = {
        imports = [ home-manager.nixosModules.home-manager ];

        _module.args = { inherit desktop username selfPackages; };

        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users.${username} = import ./home.nix;
        home-manager.extraSpecialArgs = { inherit desktop username cooknixvim opencode bili-danmaku-tui selfPackages noctalia; };
      };
    in {
      # 暴露自构建派生为 flake 包：可单独 `nix build .#<name>`
      packages.${system} = selfPackages;

      nixosConfigurations = {
        # 实体机；hardware-configuration.nix 需 git add 后才会被 flake 包含
        ${hostname} = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit noctalia-greeter; };
          modules = [
            ./hardware-configuration.nix
            ./configuration.nix
            hmModule
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
