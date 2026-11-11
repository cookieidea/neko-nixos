{ pkgs, username, ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nix.settings.extra-substituters = [
    "https://mirrors.ustc.edu.cn/nix-channels/store"
    "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
    "https://cache.lantian.pub/lantian"
    "https://noctalia.cachix.org"
    "https://nekobox.cachix.org"
    "https://cache.numtide.com"
    "https://cook-nixvim.cachix.org"
    "https://nix-community.cachix.org"
  ];

  nix.settings.extra-trusted-public-keys = [
    "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
    "lantian:WVGO7vsRMSEN+h7Lp7kv6SAmrkEXgUGbbXm7jMDjBuQ="
    "noctalia.cachix.org-1:pCOR47nnMeo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    "nekobox.cachix.org-1:bRpp0vZK2Uq/vnydXC+uuOmFJW3W6fN4PI5PDy4iD+s="
    "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    "cook-nixvim.cachix.org-1:LjCZ3VSYrcwTQxHpd834EIswdkfHoSd/EsKUYLRruF4="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
  ];

  nixpkgs.config = {
    allowUnfree = true;
    rocmSupport = true;
    # 新版 nixpkgs 把 gtk+（gtk2）标记为 broken；只作为传递依赖出现，
    # 降级为警告，避免整个系统求值失败。
    problems.handlers."gtk+".broken = "warn";
  };

  nix.settings.auto-optimise-store = true;

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

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
