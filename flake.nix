# DO-NOT-EDIT. This file was auto-generated using github:denful/flake-file.
# Use `nix run .#write-flake` to regenerate it.
{
  description = "ATRI —— 个人 NixOS + Home Manager 配置（niri 桌面）";

  outputs =
    inputs:
    (inputs.nixpkgs.lib.evalModules {
      specialArgs = {
        inherit inputs;
        inherit (inputs) self;
      };
      modules = [
        inputs.flake-file.flakeModules.flake
        ./flake-file.nix
      ];
    }).config.outputs
      inputs;

  nixConfig = {
    extra-substituters = [
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
      "https://cache.lantian.pub/lantian"
      "https://noctalia.cachix.org"
      "https://nekobox.cachix.org"
      "https://cache.numtide.com"
      "https://cook-nixvim.cachix.org"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
      "lantian:WVGO7vsRMSEN+h7Lp7kv6SAmrkEXgUGbbXm7jMDjBuQ="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "noctalia.cachix.org-1:pCOR47nnMeo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      "nekobox.cachix.org-1:bRpp0vZK2Uq/vnydXC+uuOmFJW3W6fN4PI5PDy4iD+s="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      "cook-nixvim.cachix.org-1:LjCZ3VSYrcwTQxHpd834EIswdkfHoSd/EsKUYLRruF4="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    agenix = {
      url = "git+https://gitcode.com/ryantm/agenix.git?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    bestclient = {
      url = "git+https://github.com/BestProjectTeam/BestClient";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    bilihud = {
      url = "github:locez/bilihud";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    cooknixvim = {
      url = "git+https://github.com/Youthdreamer/CookNixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-file.url = "github:denful/flake-file";
    home-manager = {
      url = "git+https://gitcode.com/nix-community/home-manager.git?ref=master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    linuxqq-wayland-fix = {
      url = "github:SHORiN-KiWATA/linuxqq-wayland-fix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    llm-agents-nix.url = "github:numtide/llm-agents.nix";
    mark-shot = {
      url = "git+https://github.com/jswysnemc/mark-shot";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    neko-pkgs = {
      url = "github:cookieidea/nur-packages";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-cachyos-kernel.url = "git+https://github.com/xddxdd/nix-cachyos-kernel?ref=release";
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixcord = {
      url = "github:4evy/nixcord";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "git+https://mirrors.nju.edu.cn/git/nixpkgs.git?ref=nixos-unstable&shallow=1";
    noctalia.url = "git+https://github.com/noctalia-dev/noctalia.git?ref=cachix";
    noctalia-greeter = {
      url = "git+https://github.com/noctalia-dev/noctalia-greeter?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
