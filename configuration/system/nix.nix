# Nix daemon、缓存、垃圾回收和 zram。
{ pkgs, username, ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  # 二进制缓存按基础源和第三方源分组，便于维护信任关系。
  nix.settings.substituters = [
    # nixpkgs 分发缓存。
    # cache.nixos.org 由 NixOS 模块自动追加；这里仅配置国内镜像。
    "https://mirrors.ustc.edu.cn/nix-channels/store"
    "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"

    # 第三方输入对应的缓存。
    "https://attic.xuyh0120.win/lantian"    # nix-cachyos-kernel（内核）
    "https://noctalia.cachix.org"           # noctalia / noctalia-greeter
    "https://nekobox.cachix.org"            # 本仓库自建包（cachix 推送目标）
    "https://cache.numtide.com"             # llm-agents-nix（dsh / opencode）
    "https://cook-nixvim.cachix.org"        # CookNixvim（nvim 及其插件）
    "https://nix-community.cachix.org"      # nix-community（unfree 可再分发包）
  ];
  # cache.nixos.org 的公钥由 NixOS 默认提供，这里只声明额外缓存。
  nix.settings.trusted-public-keys = [
    "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
    "noctalia.cachix.org-1:pCOR47nnMeo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    "nekobox.cachix.org-1:bRpp0vZK2Uq/vnydXC+uuOmFJW3W6fN4PI5PDy4iD+s="
    "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    "cook-nixvim.cachix.org-1:LjCZ3VSYrcwTQxHpd834EIswdkfHoSd/EsKUYLRruF4="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
  ];
  # 允许普通用户使用这些额外 substituter；不授予 trusted-users 权限。
  nix.settings.trusted-substituters = [
    "https://mirrors.ustc.edu.cn/nix-channels/store"
    "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
    "https://attic.xuyh0120.win/lantian"
    "https://noctalia.cachix.org"
    "https://nekobox.cachix.org"
    "https://cache.numtide.com"
    "https://cook-nixvim.cachix.org"
    "https://nix-community.cachix.org"
  ];

  nixpkgs.config = {
    allowUnfree = true;   # 允许非自由软件（steam/wechat-uos 等）
    rocmSupport = true;   # ROCm/HIP GPU 计算
  };

  # 自动垃圾回收和 store 去重。
  nix.gc.automatic = true;
  nix.gc.dates = "weekly";
  nix.optimise.automatic = true;
  nix.settings.auto-optimise-store = true;

  # zram 压缩交换。
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  # 每周清理旧代际并执行垃圾回收。
  systemd.services.nix-generation-cleanup = {
    description = "Prune old NixOS/Home-Manager generations";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.writeShellScript "nix-generation-cleanup" ''
        set -euo pipefail
        ${pkgs.nix}/bin/nix-env --delete-generations +5 -p /nix/var/nix/profiles/system
        ${pkgs.nix}/bin/nix-env --delete-generations +5 -p /nix/var/nix/profiles/per-user/${username}/home-manager 2>/dev/null || true
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
