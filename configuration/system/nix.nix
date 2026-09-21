# Nix 守护进程、二进制缓存、垃圾回收、zram
{ pkgs, username, ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  # 二进制缓存。按「基础 / 第三方」两类分组，便于排查
  # 「这个 cache 为什么必须信任」——每一项都对应一个明确的来源。
  nix.settings.substituters = [
    # ── 基础：nixpkgs 分发通道 ──
    # cache.nixos.org 由 nixos/modules/config/nix.nix 以 mkAfter 自动追加到末尾，
    # 无需手写（手写会产生重复项）。以下两个是其国内镜像，靠前以加速。
    "https://mirrors.ustc.edu.cn/nix-channels/store"
    "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"

    # ── 第三方：各自对应一个 flake input ──
    "https://attic.xuyh0120.win/lantian"    # nix-cachyos-kernel（内核）
    "https://noctalia.cachix.org"           # noctalia / noctalia-greeter
    "https://nekobox.cachix.org"            # 本仓库自建包（cachix 推送目标）
    "https://cache.numtide.com"             # llm-agents-nix（dsh / opencode）
    "https://cook-nixvim.cachix.org"        # CookNixvim（nvim 及其插件）
    "https://nix-community.cachix.org"      # nix-community（unfree 可再分发包）
  ];
  # 同理，cache.nixos.org 的 key 由模块默认提供，此处只列额外缓存
  nix.settings.trusted-public-keys = [
    "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
    "noctalia.cachix.org-1:pCOR47nnMeo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    "nekobox.cachix.org-1:bRpp0vZK2Uq/vnydXC+uuOmFJW3W6fN4PI5PDy4iD+s="
    "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    "cook-nixvim.cachix.org-1:LjCZ3VSYrcwTQxHpd834EIswdkfHoSd/EsKUYLRruF4="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
  ];
  # 允许**普通用户**在命令行启用上述缓存（--substituters）。
  #
  # 依据 nix.conf(5)：Nix 使用某个 substituter 需满足二者之一 ——
  #   · 该 substituter 在 trusted-substituters 列表中
  #   · 调用 Nix 的用户在 trusted-users 列表中
  # 两者作用不等价：trusted-users 还能连 daemon 执行特权操作（近似 root），
  # 而我们的目的仅是「用缓存」，故采用前者，不用 trusted-users。
  # root 由 nixos/modules/config/nix.nix 默认提供，无需重复。
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
