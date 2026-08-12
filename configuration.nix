# Shorin Arch Setup → NixOS system config
# 对应原仓库 scripts/ 中的系统级步骤（base / nm-backend / gpu-driver / musthave 等）
{ config, pkgs, lib, desktop, username, ... }:

{
  # ⚠️ hardware-configuration.nix 的 import 已移到 flake.nix 的实体机配置里——
  #    实体机装好系统后请保持该文件被 git add（flake 只认跟踪文件）。

  # ── 最新内核（AMD RX 6750 GRE 用新内核 amdgpu 支持更好）──
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # ── Flakes 开关 ───────────────────────────────────────────
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  # ── 国内镜像源（Nix 二进制缓存，清华）──
  # 用 extra-substituters 追加，不覆盖默认源；镜像不可达时 Nix 自动回退官方
  # cache.nixos.org（内容镜像，沿用官方公钥，无需额外 trusted key）。
  nix.settings.extra-substituters = [ "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store" ];
  nixpkgs.config = {
    allowUnfree = true;   # steam / wechat-uos / 部分驱动需要
  };
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

  # ── 休眠（hibernation）──
  # ⚠️ btrfs 上的 swapfile **官方不支持休眠恢复**（内核 swsusp 在恢复早期无法可靠地把
  #   btrfs 文件映射到块设备偏移）。因此休眠用**独立的 SWAP 分区**（不进 btrfs 子卷）。
  # SWAP 分区在 docs/install-btrfs.md 第 1/2 步创建（linux-swap，label=SWAP），
  # `nixos-generate-config` 会自动把它加入 swapDevices（partition 类型），无需手配。
  # NixOS 26.05 的 initrd 默认启用 systemd，会自动检测 resume 设备并存 EFI 变量；
  # 这里显式声明 boot.resumeDevice 作为兜底（非 EFI / 异常 EFI 主板也可靠）。
  boot.resumeDevice = "/dev/disk/by-label/SWAP";
  # 若已在装好的系统上**事后**补 SWAP 分区（未重新 generate-config），需在
  # hardware-configuration.nix 手动加：swapDevices = [ { device = "/dev/disk/by-label/SWAP"; } ];

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
      qt6Packages.fcitx5-chinese-addons   # 26.05 起从 pkgs 移到 qt6Packages
      rime-wanxiang     # 26.05 移除 rime-wubi → 用万象（含五笔方案）
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
  hardware.graphics.enable = true;          # 26.05 由 hardware.opengl 改名（旧名仅剩弃用警告）
  hardware.graphics.extraPackages = with pkgs; [
    vulkan-loader   # Vulkan ICD 加载器（RADV 由 mesa 提供，6750 GRE 走 RADV）
    libva           # VA-API 加载器（AMD 硬件解码走 mesa 的 radeonsi VA 驱动）
  ];
  services.xserver.videoDrivers = [ "amdgpu" ];
  # 12400F 无核显 → 不需要 intel 驱动；非笔记本双显卡 → 不需要 NVIDIA Prime/offload。

  # ── SSH ───────────────────────────────────────────────────
  services.openssh.enable = true;

  # ── Flatpak（用于 nixpkgs 没有/源失效的闭源 App，如 qq/wechat）──
  services.flatpak.enable = true;
  # Flathub 源：国内镜像（USTC/TUNA/阿里）flatpakrepo 路径均已失效（404），改用官方 dl.flathub.org。
  # ⚠️ NixOS 26.05 已移除 services.flatpak.remotes 声明式选项，
  #   改用 one-shot systemd 服务在启动时添加 remote 并自动安装 Flatpak 应用
  #   （--if-not-exists / --or-update 保证幂等；构建期不下载，不影响 nixos-install）。
  systemd.services.flatpak-repo = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    path = [ pkgs.flatpak ];
    script = ''
      flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
      # 自动安装 Flatpak 应用（幂等）：微信 / QQ / Flatseal / Bazaar 应用商店
      flatpak install --noninteractive --or-update flathub com.tencent.WeChat com.qq.QQ com.github.tchx84.Flatseal io.github.kolunmi.Bazaar
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };

  # ── XDG 桌面门户 ──────────────────────────────────────────
  xdg.portal.enable = true;

  # dconf（home-manager gtk 模块用 dconf 写 GTK 主题设置，需系统提供 dconf 的 DBus 激活服务）
  programs.dconf.enable = true;
  # hyprland portal 作为兜底：部分 Wayland App（微信/会议）屏幕共享只认它
  xdg.portal.extraPortals = with pkgs; [ xdg-desktop-portal-gtk xdg-desktop-portal-gnome xdg-desktop-portal-hyprland ];
  xdg.portal.config.common.default = "gtk";

  # ── 显示服务器 + 登录管理器 + 桌面（niri + Noctalia）─────
  # niri 是纯 Wayland 滚动平铺 compositor，不需要 X server。
  # 登录管理器用 ly（nixpkgs 官方 displayManager 模块，PAM/systemd/config 全自动）。
  services.displayManager.ly = {
    enable = true;
    # 纯 Wayland（niri），ly 不需要管理 X server → 去掉 libxcb 依赖
    x11Support = false;
    settings = {
      # ly 内部 PATH：加上 home-manager 用户 profile，
      # 否则 niri 里启动的 fuzzel/foot 等找不到（home-manager useGlobalPkgs 下可留 sw/bin）
      path = "/run/current-system/sw/bin:/home/${username}/.nix-profile/bin:/home/${username}/.nix-profile/sbin";
      animation = "none";
    };
  };
  # niri 会话：注册为系统级 desktop 文件（ly 才能列出/启动）
  services.displayManager.session = [{
    name = "niri";
    manage = "desktop";
    start = ''
      export PATH="/home/${username}/.nix-profile/bin:/run/current-system/sw/bin:$PATH"
      exec ${pkgs.niri}/bin/niri
    '';
  }];
  # 自动登录 cookie → 直接进 niri（ly 模块自动配 ly-autologin PAM）
  services.displayManager.defaultSession = "niri";
  services.displayManager.autoLogin = {
    enable = true;
    user = username;
  };
  # ly 的 PAM 服务（ly / ly-autologin）由 displayManager.ly 模块自动配置

  # GNOME（原 04d-gnome.sh，已弃用，保留以便回退）
  # services.desktopManager.gnome.enable = lib.mkIf (desktop == "gnome") true;
  # services.xserver.displayManager.gdm.enable = lib.mkIf (desktop == "gnome") true;

  # KDE Plasma 6（原 04b-kdeplasma-setup.sh，已弃用）
  # services.desktopManager.plasma6.enable = lib.mkIf (desktop == "kde") true;
  # services.displayManager.sddm.enable = lib.mkIf (desktop == "kde") true;

  # ── 系统级包（少量，其余都在 home.nix）──────────────────
  environment.systemPackages = with pkgs; [
    git
    # nm-connection-editor 已在 26.05 移除 → 用自带的 nmtui / nmcli 编辑连接
    # 磁盘/文件系统工具（对应 kde-common-applist）
    gparted dosfstools exfatprogs f2fs-tools udftools xfsprogs
    # 登录管理器 ly 由 displayManager.ly 模块自动装入（见上方登录管理器配置）
    # virt-manager/libvirtd 后端（原 99-apps 的 qemu-full + swtpm；libvirtd 已 enable）
    qemu swtpm
    # X11 兼容层：xwayland-satellite（niri 25.08+ 开箱集成，binary 在 PATH 时
    # niri 自动按需拉起 Xwayland；微信/LinuxQQ 等 X11 应用因此可正常启动）
    xwayland-satellite
  ];

  # ── 字体（对应 ttf-jetbrains-mono-nerd / maple / noto-cjk）─
  fonts.packages = with pkgs; [
    noto-fonts-cjk-sans
    # 26.05 改名：noto-fonts-emoji → noto-fonts-color-emoji
    noto-fonts-color-emoji
    sarasa-gothic
    jetbrains-mono
    nerd-fonts.jetbrains-mono     # 26.05 起 nerdfonts 改名 nerd-fonts 且改为按字体属性取（MapleMono 不在其清单，暂缺）
  ];

  # ── 应用级服务（对应 scripts 中的 enable 步骤）──────────
  services.lact.enable = true;          # lact（GPU 控制）；注意 nixpkgs 26.05 选项是 services.lact（非 programs.lact）
  programs.steam.enable = true;         # steam
  virtualisation.libvirtd.enable = true;  # virt-manager 后端

  # ── btrfs + snapper 快照 / 回滚（已默认启用；无 LUKS）──────
  # / 本身是 @ 子卷，让 snapper 正确处理 .snapshots 目录与快照子卷。
  # 快照默认存到 /.snapshots（即独立挂载的 @snapshots 子卷，回滚根时不带快照、更稳）。
  services.snapper = {
    snapshotRootOnBoot = true;            # / 本身是 @ 子卷：开机时对根子卷打快照（26.05 由 snapshotRootOnSubvol 改名）
    # ⚠️ 26.05 起 configs.<名> 的选项全部改用 snapper 配置文件键名（全大写，见 man snapper-configs）：
    # subvolume→SUBVOLUME、timelineCreate→TIMELINE_CREATE、timelineLimitHourly→TIMELINE_LIMIT_HOURLY、
    # emptyPrePostCleanup→EMPTY_PRE_POST_CLEANUP、numberLimit→NUMBER_LIMIT …
    # 旧 camelCase 键不再声明，会被 freeformType 静默收下但写出无效小写键，snapper 不认 → 快照不生效。
    configs."root" = {
      SUBVOLUME = "/";              # 26.05 由 subvolume 改名（全大写 SUBVOLUME）
      TIMELINE_CREATE = true;       # 按时线自动快照
      TIMELINE_LIMIT_HOURLY = 24;   # 保留最近 24 个每小时
      TIMELINE_LIMIT_DAILY = 7;     # 保留最近 7 个每天
      TIMELINE_LIMIT_WEEKLY = 4;    # 保留最近 4 个每周
      TIMELINE_LIMIT_MONTHLY = 0;
      TIMELINE_LIMIT_YEARLY = 0;
      EMPTY_PRE_POST_CLEANUP = true; # 清掉空的 pre-post 快照对
      NUMBER_LIMIT = 0;             # 0 = 不按数量限制，只按时线保留
    };
  };
  # ⚠️ NixOS 26.05 已移除 services.grub-btrfs 模块（grub-btrfs 在 nixpkgs 中停止维护被删除）。
  # 暂时去掉「GRUB 快照子菜单」：services.snapper 仍会按时线自动创建快照（/.snapshots），
  # 回滚可手动：从 live ISO 挂载子卷或用 `snapper rollback` 生成新快照后重启选对应代际。
  # 若以后要 GRUB 里直接列快照，需自行用 grub-btrfs 包的 grub-btrfsd 接 systemd 服务，
  # 且必须与 NixOS 的 grub 配置生成协同（不能让 grub-btrfsd 覆盖 /boot/grub/grub.cfg 的代际条目）。

  # ── 用户（必须存在，否则 home-manager 报错）──────────────
  users.users.${username} = {
    isNormalUser = true;
    description = username;
    extraGroups = [ "networkmanager" "wheel" "libvirtd" "video" "audio" ];
    # 设置密码（或安装后用 `passwd`）：
    # initialPassword = "changeme";
  };
}
