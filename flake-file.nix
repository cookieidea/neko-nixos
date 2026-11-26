# flake 定义：description / nixConfig / inputs 都在这里声明，
# flake.nix 由 `nix run .#write-flake` 从本文件生成，不要手改 flake.nix。
{
  imports = [ ./flake-module.nix ];

  flake-file = {
    description = "ATRI —— 个人 NixOS + Home Manager 配置（niri 桌面）";
    outputs = "flake-module";

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
      nixpkgs.url = "git+https://mirrors.nju.edu.cn/git/nixpkgs.git?ref=nixos-unstable&shallow=1";

      flake-file.url = "github:denful/flake-file";

      home-manager = {
        url = "git+https://gitcode.com/nix-community/home-manager.git?ref=master";
        inputs.nixpkgs.follows = "nixpkgs";
      };

      nix-cachyos-kernel = {
        url = "git+https://github.com/xddxdd/nix-cachyos-kernel?ref=release";
      };
      noctalia = {
        url = "git+https://github.com/noctalia-dev/noctalia.git?ref=cachix";
      };
      noctalia-greeter = {
        url = "git+https://github.com/noctalia-dev/noctalia-greeter?ref=main";
        inputs.nixpkgs.follows = "nixpkgs";
      };
      nix-flatpak = {
        url = "github:gmodena/nix-flatpak";
      };

      cooknixvim = {
        url = "git+https://github.com/Youthdreamer/CookNixvim";
        inputs.nixpkgs.follows = "nixpkgs";
      };
      fenix = {
        url = "github:nix-community/fenix";
        inputs.nixpkgs.follows = "nixpkgs";
      };
      nix-vscode-extensions = {
        url = "github:nix-community/nix-vscode-extensions";
        inputs.nixpkgs.follows = "nixpkgs";
      };

      bilihud = {
        url = "github:locez/bilihud";
        inputs.nixpkgs.follows = "nixpkgs";
      };
      bestclient = {
        url = "git+https://github.com/BestProjectTeam/BestClient";
        inputs.nixpkgs.follows = "nixpkgs";
      };
      mark-shot = {
        url = "git+https://github.com/jswysnemc/mark-shot";
        inputs.nixpkgs.follows = "nixpkgs";
      };
      nixcord = {
        url = "github:4evy/nixcord";
        inputs.nixpkgs.follows = "nixpkgs";
      };
      # 用该 input 自带的 nixpkgs：它跟踪 unstable，部分包需要 26.05 还没有的依赖。
      llm-agents-nix = {
        url = "github:numtide/llm-agents.nix";
      };

      agenix = {
        url = "git+https://gitcode.com/ryantm/agenix.git?ref=main";
        inputs.nixpkgs.follows = "nixpkgs";
      };

      # 修 Linux QQ 在 Wayland 下的屏幕共享、剪贴板、截图，以及语音通话
      # 录音分片过大导致的延迟（v0.2.15 起）。
      linuxqq-wayland-fix = {
        url = "github:SHORiN-KiWATA/linuxqq-wayland-fix";
        inputs.nixpkgs.follows = "nixpkgs";
      };

      # 自构建包独立仓库；带 source.ts 的包由其中 CI 用 nix-repin 更新。
      neko-pkgs = {
        url = "github:cookieidea/nur-packages";
        inputs.nixpkgs.follows = "nixpkgs";
      };
    };
  };
}
