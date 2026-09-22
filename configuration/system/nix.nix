# Nix daemon、缓存、垃圾回收和 zram。
{ pkgs, username, ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # extra-* 保留 Nix 默认的 cache.nixos.org，同时追加国内 mirror 和项目专用缓存。
  nix.settings.extra-substituters = [
    "https://mirrors.ustc.edu.cn/nix-channels/store"
    "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
    "https://attic.xuyh0120.win/lantian"
    "https://noctalia.cachix.org"
    "https://nekobox.cachix.org"
    "https://cache.numtide.com"
    "https://cook-nixvim.cachix.org"
    "https://nix-community.cachix.org"
  ];

  nix.settings.extra-trusted-public-keys = [
    "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
    "noctalia.cachix.org-1:pCOR47nnMeo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    "nekobox.cachix.org-1:bRpp0vZK2Uq/vnydXC+uuOmFJW3W6fN4PI5PDy4iD+s="
    "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    "cook-nixvim.cachix.org-1:LjCZ3VSYrcwTQxHpd834EIswdkfHoSd/EsKUYLRruF4="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
  ];

  nixpkgs.config = {
    allowUnfree = true;
    rocmSupport = true;
  };

  nix.settings.auto-optimise-store = true;

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  # 保留 10 个 system / Home Manager generations，给复杂桌面栈留出回滚空间。
  systemd.services.nix-generation-cleanup = {
    description = "Prune old NixOS/Home-Manager generations";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.writeShellScript "nix-generation-cleanup" ''
        set -euo pipefail
        ${pkgs.nix}/bin/nix-env --delete-generations +10 -p /nix/var/nix/profiles/system
        ${pkgs.nix}/bin/nix-env --delete-generations +10 -p /nix/var/nix/profiles/per-user/${username}/home-manager 2>/dev/null || true
        ${pkgs.nix}/bin/nix-store --gc
      ''}";
    };
  };

  systemd.timers.nix-generation-cleanup = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "weekly";
      Persistent = true;
    };
  };

  system.stateVersion = "26.05";
}
