# Shorin Arch Setup → NixOS system config
# 对应原仓库 scripts/ 中的系统级步骤（base / nm-backend / gpu-driver / musthave 等）
{ config, pkgs, lib, desktop, username, ... }:

{
  # ── Flakes 开关 ───────────────────────────────────────────
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;   # steam / wechat-uos / 部分驱动需要
  security.polkit.enable = true;        # polkit 认证（Noctalia / 系统设置需要）

  # ── 引导 / 磁盘 ───────────────────────────────────────────
  # 用 systemd-boot（UEFI）。GRUB 方案见末尾备注。
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # LUKS 加密（原脚本建议）：取消下面注释并填设备
  # boot.initrd.luks.devices."luks-root".device = "/dev/disk/by-uuid/XXXX";

  # 限制保留的 generation 数，避免 /boot 爆满（原仓库有类似处理）
  boot.loader.systemd-boot.configurationLimit = 20;

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

  # ── XDG 桌面门户 ──────────────────────────────────────────
  xdg.portal.enable = true;
  xdg.portal.extraPortals = with pkgs; [ xdg-desktop-portal-gtk xdg-desktop-portal-gnome ];
  xdg.portal.config.common.default = "gtk";

  # ── 显示服务器 + 登录管理器 + 桌面（niri + Noctalia）─────
  # niri 是纯 Wayland 滚动平铺 compositor，不需要 X server。
  # 用 greetd + tuigreet 作为登录管理器，登录后直接启动 niri。
  services.greetd = lib.mkIf (desktop == "niri") {
    enable = true;
    settings = {
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
  programs.lact.enable = true;          # lact（GPU 控制）
  programs.steam.enable = true;         # steam
  virtualisation.libvirtd.enable = true;  # virt-manager 后端

  # ── 可选：btrfs + snapper 快照（对应 00-btrfs-init / 03c）──
  # services.snapper.snapshotRootOnSubvol = true;
  # 配合 boot 用 btrfs 子卷时启用

  # ── 用户（必须存在，否则 home-manager 报错）──────────────
  users.users.${username} = {
    isNormalUser = true;
    description = username;
    extraGroups = [ "networkmanager" "wheel" "libvirtd" "video" "audio" ];
    # 设置密码（或安装后用 `passwd`）：
    # initialPassword = "changeme";
  };
}
