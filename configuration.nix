# Shorin Arch Setup → NixOS system config
# 对应原仓库 scripts/ 中的系统级步骤（base / nm-backend / gpu-driver / musthave 等）
{ config, pkgs, lib, desktop, username, ... }:

{
  imports = [
    # 硬件配置（磁盘/filesystems/EFI/swap 等），由 `nixos-generate-config --root /mnt` 生成。
    # 全新安装（minimal ISO）时务必先生成它，否则 nixos-install 会因缺根分区挂载而失败。
    ./hardware-configuration.nix
  ];

  # ── 最新内核（AMD RX 6750 GRE 用新内核 amdgpu 支持更好）──
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # ── Flakes 开关 ───────────────────────────────────────────
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  # ── 国内镜像源（Nix 二进制缓存，清华）──
  # 用 extra-substituters 追加，不覆盖默认源；镜像不可达时 Nix 自动回退官方
  # cache.nixos.org（内容镜像，沿用官方公钥，无需额外 trusted key）。
  nix.settings.extra-substituters = [ "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store" ];
  nixpkgs.config.allowUnfree = true;   # steam / wechat-uos / 部分驱动需要
  security.polkit.enable = true;        # polkit 认证（Noctalia / 系统设置需要）

  # ── 自动垃圾回收 / store 去重（防滚版本撑爆 /）────────────
  nix.gc.automatic = true;
  nix.gc.dates = "weekly";
  nix.optimise.automatic = true;              # 定期硬链接去重，省空间
  nix.settings.auto-optimise-store = true;    # 写入 store 时即时去重

  # ── 系统版本锁定（避免大版本升级触发意外的状态迁移）────────
  system.stateVersion = "26.05";

  # ── 引导 / 磁盘 ───────────────────────────────────────────
  # 用 GRUB（UEFI）。纯 EFI 安装：efiSupport + device="nodev"（不写 MBR）。
  # 如需双系统引导 Windows，可加 boot.loader.grub.useOSProber = true;
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    device = "nodev";
    configurationLimit = 20;
    efiInstallAsRemovable = true;   # 兜底：复制到 fallback EFI 路径，板子 UEFI 抽风也能启动
  };
  # ── 文件系统支持（btrfs 根分区 + initrd 挂载）────────────
  boot.supportedFilesystems = [ "btrfs" ];
  boot.initrd.supportedFilesystems = [ "btrfs" ];

  # LUKS 加密（原脚本建议）：取消下面注释并填设备
  # boot.initrd.luks.devices."luks-root".device = "/dev/disk/by-uuid/XXXX";

  # ── 网络 / 主机 ───────────────────────────────────────────
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;   # 对应 01c-nm-backend.sh

  # ── 时区 /  locale ────────────────────────────────────────
  time.timeZone = "Asia/Shanghai";
  i18n.defaultLocale = "zh_CN.UTF-8";

  # ── 输入法 fcitx5（对应 fcitx5 + rime-wubi + fcitx5-mozc）──
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-rime
      fcitx5-mozc
      fcitx5-chinese-addons
      rime-wubi
    ];
  };

  # ── 音频 PipeWire（对应 easyeffects / pavucontrol 后端）──
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
    jack.enable = true;
  };

  # ── 蓝牙 ──────────────────────────────────────────────────
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # ── GPU 驱动（AMD Radeon RX 6750 GRE 10G，RDNA2 / Navi 22；CPU i5-12400F 无核显）──
  # 单卡 AMD 独显：amdgpu 内核驱动 + mesa（OpenGL / Vulkan(RADV) / VA-API 硬件解码）。
  hardware.opengl.enable = true;
  hardware.opengl.extraPackages = with pkgs; [
    vulkan-loader   # Vulkan ICD 加载器（RADV 由 mesa 提供，6750 GRE 走 RADV）
    libva           # VA-API 加载器（AMD 硬件解码走 mesa 的 radeonsi VA 驱动）
  ];
  services.xserver.videoDrivers = [ "amdgpu" ];
  # 12400F 无核显 → 不需要 intel 驱动；非笔记本双显卡 → 不需要 NVIDIA Prime/offload。

  # ── SSH ───────────────────────────────────────────────────
  services.openssh.enable = true;

  # ── Flatpak（用于 nixpkgs 没有的闭源 App，如 linuxqq）──
  services.flatpak.enable = true;
  # Flathub 走中科大(USTC)国内镜像，避免直连 dl.flathub.org 慢/超时
  services.flatpak.remotes.flathub = {
    location = "https://mirrors.ustc.edu.cn/flathub/repo/flathub.flatpakrepo";
  };

  # ── XDG 桌面门户 ──────────────────────────────────────────
  xdg.portal.enable = true;
  # hyprland portal 作为兜底：部分 Wayland App（微信/会议）屏幕共享只认它
  xdg.portal.extraPortals = with pkgs; [ xdg-desktop-portal-gtk xdg-desktop-portal-gnome xdg-desktop-portal-hyprland ];
  xdg.portal.config.common.default = "gtk";

  # ── 显示服务器 + 登录管理器 + 桌面（niri + Noctalia）─────
  # niri 是纯 Wayland 滚动平铺 compositor，不需要 X server。
  # 用 greetd + tuigreet 作为登录管理器，登录后直接启动 niri。
  services.greetd = lib.mkIf (desktop == "niri") {
    enable = true;
    settings = {
      autoLogin = {
        enable = true;
        user = username;
      };
      default_session = {
        # tuigreet 列出可用 Wayland 会话；--cmd 直接指定 niri
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --cmd ${pkgs.niri}/bin/niri --remember --user-menu";
        user = username;
      };
    };
  };
  # greetd 会自动配置 PAM；如需手动覆盖可加：
  # security.pam.services.greetd.enable = true;

  # GNOME（原 04d-gnome.sh，已弃用，保留以便回退）
  # services.desktopManager.gnome.enable = lib.mkIf (desktop == "gnome") true;
  # services.xserver.displayManager.gdm.enable = lib.mkIf (desktop == "gnome") true;

  # KDE Plasma 6（原 04b-kdeplasma-setup.sh，已弃用）
  # services.desktopManager.plasma6.enable = lib.mkIf (desktop == "kde") true;
  # services.displayManager.sddm.enable = lib.mkIf (desktop == "kde") true;

  # ── 系统级包（少量，其余都在 home.nix）──────────────────
  environment.systemPackages = with pkgs; [
    git
    nm-connection-editor
    # 磁盘/文件系统工具（对应 kde-common-applist）
    gparted dosfstools exfatprogs f2fs-tools udftools xfsprogs
    # 登录管理器 greeter（niri 由 home.nix 的 programs.niri 安装）
    greetd.tuigreet
  ];

  # ── 字体（对应 ttf-jetbrains-mono-nerd / maple / noto-cjk）─
  fonts.packages = with pkgs; [
    noto-fonts-cjk-sans
    sarasa-gothic
    jetbrains-mono
    (nerdfonts.override { fonts = [ "JetBrainsMono" "MapleMono" ]; })
  ];

  # ── 应用级服务（对应 scripts 中的 enable 步骤）──────────
  services.lact.enable = true;          # lact（GPU 控制）；注意 nixpkgs 26.05 选项是 services.lact（非 programs.lact）
  programs.steam.enable = true;         # steam
  virtualisation.libvirtd.enable = true;  # virt-manager 后端

  # ── btrfs + snapper 快照 / 回滚（已默认启用；无 LUKS）──────
  # / 本身是 @ 子卷，让 snapper 正确处理 .snapshots 目录与快照子卷。
  # 快照默认存到 /.snapshots（即独立挂载的 @snapshots 子卷，回滚根时不带快照、更稳）。
  services.snapper = {
    snapshotRootOnSubvol = true;
    configs."root" = {
      subvolume = "/";
      timelineCreate = true;          # 按时线自动快照
      timelineLimitHourly = 24;       # 保留最近 24 个每小时
      timelineLimitDaily = 7;         # 保留最近 7 个每天
      timelineLimitWeekly = 4;        # 保留最近 4 个每周
      timelineLimitMonthly = 0;
      timelineLimitYearly = 0;
      emptyPrePostCleanup = true;     # 清掉空的 pre-post 快照对
      numberLimit = 0;                # 0 = 不按数量限制，只按时线保留
    };
  };
  # GRUB 启动菜单显示快照（grub-btrfs 模块，nixpkgs 自带）：
  # 生成「Snapshots」子菜单，可在此选历史快照启动；启动失败时自动进 GRUB 菜单。
  services.grub-btrfs = {
    enable = true;
    bootsToGrubMenu = true;           # 异常断电/内核崩溃后自动回到 GRUB 菜单，便于选快照
  };

  # ── 用户（必须存在，否则 home-manager 报错）──────────────
  users.users.${username} = {
    isNormalUser = true;
    description = username;
    extraGroups = [ "networkmanager" "wheel" "libvirtd" "video" "audio" ];
    # 设置密码（或安装后用 `passwd`）：
    # initialPassword = "changeme";
  };
}
