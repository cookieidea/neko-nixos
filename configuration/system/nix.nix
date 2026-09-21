# Nix 守护进程、二进制缓存、垃圾回收、zram
{ pkgs, username, ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  # 二进制缓存：国内镜像优先。cache.nixos.org 由 nixos/modules/config/nix.nix
  # 用 mkAfter 自动追加到末尾兜底，无需手写（手写会重复）
  nix.settings.substituters = [
    "https://mirrors.ustc.edu.cn/nix-channels/store"
    "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
    "https://attic.xuyh0120.win/lantian"
    "https://noctalia.cachix.org"
    "https://nekobox.cachix.org"
    # llm-agents.nix 官方缓存（dsh / opencode；实测可省 4 个 derivation 的编译）
    "https://cache.numtide.com"
    # CookNixvim 官方缓存（nvim 及其插件）
    "https://cook-nixvim.cachix.org"
    # nix-community 通用缓存（unfree 可再分发包 + 社区包，官方源不构建这类）
    "https://nix-community.cachix.org"
    # Denial 官方缓存（命中即免编译 Flutter 引擎）
    "https://denial.cachix.org"
  ];
  # 同理，cache.nixos.org 的 key 由模块默认提供，此处只列额外缓存
  nix.settings.trusted-public-keys = [
    "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
    "noctalia.cachix.org-1:pCOR47nnMeo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    "nekobox.cachix.org-1:bRpp0vZK2Uq/vnydXC+uuOmFJW3W6fN4PI5PDy4iD+s="
    "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    "cook-nixvim.cachix.org-1:LjCZ3VSYrcwTQxHpd834EIswdkfHoSd/EsKUYLRruF4="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    "denial.cachix.org-1:wd8YTnvPmugFrtdMJWtR1XdVknR3/g2nmBJkT+vAruo="
  ];
  # 允许本用户使用 --substituters 等客户端缓存设置（否则被忽略：not a trusted user）
  # root 由 nixos/modules/config/nix.nix 默认提供，无需重复
  nix.settings.trusted-users = [ username ];

  nixpkgs.config = {
    allowUnfree = true;   # 允许非自由软件（steam/wechat-uos 等）
    rocmSupport = true;   # ROCm/HIP GPU 计算
  };

  # 自动垃圾回收 + store 去重
  nix.gc.automatic = true;
  nix.gc.dates = "weekly";
  nix.optimise.automatic = true;
  nix.settings.auto-optimise-store = true;

  # zram 压缩内存交换
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  # 每周清理旧代际（各保留 5 个）+ 垃圾回收
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
