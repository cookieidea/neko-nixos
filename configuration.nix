# Shorin Arch Setup → NixOS system config
# 对应原仓库 scripts/ 中的系统级步骤（base / nm-backend / gpu-driver / musthave 等）
{ config, pkgs, lib, desktop, username, selfPackages, noctalia-greeter, ... }:

{
  # ⚠️ hardware-configuration.nix 的 import 已移到 flake.nix 的实体机配置里——
  #    实体机装好系统后请保持该文件被 git add（flake 只认跟踪文件）。

  # ── 内核：CachyOS RT-BORE（实时调度 + BORE 调度器，直播/推流低延迟）──
  # overlay 来自 flake 输入 nix-cachyos-kernel（release 分支，overlays.pinned）。
  # 提供方：pkgs.cachyosKernels.linuxPackages-cachyos-rt-bore（amdgpu 由 6.x 最新内核支持）。
  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-rt-bore;

  # ── Flakes 开关 ───────────────────────────────────────────
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  # ── 国内镜像源（Nix 二进制缓存，中科大 USTC 优先 + 清华 TUNA 兜底）──
  # 用 extra-substituters 追加，不覆盖默认源；镜像不可达时 Nix 自动回退官方
  # cache.nixos.org（内容镜像，沿用官方公钥，无需额外 trusted key）。
  # CachyOS 内核二进制缓存（attic.xuyh0120.win/lantian，xddxdd 维护，国内快）。
  nix.settings.extra-substituters = [
    "https://mirrors.ustc.edu.cn/nix-channels/store"
    "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
    "https://attic.xuyh0120.win/lantian"
  ];
  nix.settings.extra-trusted-public-keys = [ "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=" ];
  nixpkgs.config = {
    allowUnfree = true;   # steam / wechat-uos / 部分驱动需要
  };
  security.polkit.enable = true;        # polkit 认证（Noctalia / 系统设置需要）
  # ── Noctalia Greeter 外观同步免密（wheel 组成员）──
  # Noctalia 的 greeter_sync（auto_sync=true）每次登录用 pkexec 跑
  # noctalia-greeter-apply-appearance，默认弹 root 密码。此规则放行 wheel。
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
        if (action.id == "org.noctalia.greeter.apply-appearance" &&
            subject.isInGroup("wheel")) {
            return polkit.Result.YES;
        }
    });
  '';

  # ── 自动垃圾回收 / store 去重（防滚版本撑爆 /）────────────
  nix.gc.automatic = true;
  nix.gc.dates = "weekly";
  nix.optimise.automatic = true;              # 定期硬链接去重，省空间
  nix.settings.auto-optimise-store = true;    # 写入 store 时即时去重

  # ── 系统版本锁定（避免大版本升级触发意外的状态迁移）────────
  system.stateVersion = "26.05";

  # ── 引导 / 磁盘 ───────────────────────────────────────────
  # 用 GRUB（UEFI）。纯 EFI 安装：efiSupport + device="nodev"（不写 MBR）。
  boot.loader.grub = {
    enable = true;
    useOSProber = true;   # 双系统：自动检测 Windows (需 os-prober 检测 NTFS)
    efiSupport = true;
    device = "nodev";
    configurationLimit = 20;
    efiInstallAsRemovable = true;   # 兜底：复制到 fallback EFI 路径，板子 UEFI 抽风也能启动
    # BlueArchive GRUB 主题（opendesktop p/2329987，游戏开发部全员 5 款配色）：
    #   yuzu(柚子) / tao(桃) / nagisa(渚) / aris(爱丽丝) / midori(绿)
    #   —— 想换配色改这里即可（midori 主题目录无子目录，其余为 <名>/Alice）
    theme = ./grub-theme/aris/Alice;   # aris = 爱丽丝
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
  # LACT / AMD 超频解锁：ppfeaturemask 全开（默认 0xfff7bfff 不含超频控制位）
  boot.kernelParams = [ "amdgpu.ppfeaturemask=0xffffffff" "clearcpuid=514" ];
  # 若已在装好的系统上**事后**补 SWAP 分区（未重新 generate-config），需在
  # hardware-configuration.nix 手动加：swapDevices = [ { device = "/dev/disk/by-label/SWAP"; } ];

  # ── 网络 / 主机 ───────────────────────────────────────────
  networking.hostName = "ATRI";
  networking.firewall.enable = false;   # 关闭防火墙
  networking.networkmanager.enable = true;   # 对应 01c-nm-backend.sh
  # DNS 改用腾讯 DNSPod：IPv4 119.29.29.29 / IPv6 2402:4e00::
  # dns = "none"：NetworkManager 不再覆盖 /etc/resolv.conf，
  # 由 networking.nameservers 静态写入，彻底替换 DHCP 下发的 DNS。
  networking.networkmanager.dns = "none";
  networking.nameservers = [ "119.29.29.29" "2402:4e00::" ];
  # 组播回环修复：IPv4 组播路由经 lo 才能本地投递（Axolotl 联机扫描本地端口依赖）。
  # cachyos 内核下路由经物理网卡时 IP_MULTICAST_LOOP 不生效（TCP 单播正常）。
  systemd.services.multicast-loopback = {
    description = "Add IPv4 multicast route via lo for local loopback delivery";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.iproute2}/bin/ip route replace 224.0.0.0/4 dev lo";
    };
  };

  # ── 时区 /  locale ────────────────────────────────────────
  time.timeZone = "Asia/Shanghai";
  i18n.defaultLocale = "zh_CN.UTF-8";

  # ── 输入法 fcitx5（中文 rime + 雾凇拼音 rime-ice；日文 mozc 不用）──
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      # Wayland 原生输入法前端（niri 下 GTK/Qt 走 text-input-v3，不再导出
      # GTK_IM_MODULE/QT_IM_MODULE；XMODIFIERS 仍保留给 XWayland 的微信/QQ 用）
      waylandFrontend = true;
      addons = with pkgs; [
        # 原配置方案：雾凇拼音（rime-ice 词库，nixpkgs 26.05 自带）。
        # rime-data 提供基础方案（luna_pinyin/wubi86/bopomofo 等），
        # rime-ice 提供 rime_ice（全拼/小鹤双拼等，见 ~/.local/share/fcitx5/rime/default.custom.yaml）
        (fcitx5-rime.override {
          rimeDataPkgs = [ rime-data rime-ice ];
        })
        # fcitx5-chinese-addons 已移除：它硬依赖 qtwebengine（网页词典组件），
        # 而 qtwebengine 6.11.1 在 GCC 15 下编译崩溃（gcc bug c/125349）
      ];
    };
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
  # Noctalia V5 推荐服务（电池/电源档案 widget 依赖）
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;
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
  # Flathub 源：先 add 官方（flatpakrepo 文件），再把仓库 URL 切到中科大镜像
  # （https://mirrors.ustc.edu.cn/flathub，2026-08 实测仓库根 200 可用；
  #  各镜像的 flathub.flatpakrepo 文件本身 404，所以不能直接 remote-add 镜像）。
  # ⚠️ NixOS 26.05 已移除 services.flatpak.remotes 声明式选项，
  #   改用 one-shot systemd 服务在启动时添加 remote 并自动安装 Flatpak 应用
  #   （--if-not-exists / --or-update 保证幂等；构建期不下载，不影响 nixos-install）。
  systemd.services.flatpak-repo = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    path = [ pkgs.flatpak pkgs.util-linux ];
    script = ''
      flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
      # 切国内镜像：中科大（动态缓存 + 302 回源）；USTC 挂了就换官方（注释掉下行）
      flatpak remote-modify flathub --url=https://mirrors.ustc.edu.cn/flathub
      # 自动安装 Flatpak 应用（幂等）：微信 / QQ / Flatseal / Bazaar / OpenOrpheus
      flatpak install --noninteractive --or-update flathub com.tencent.WeChat com.qq.QQ com.github.tchx84.Flatseal io.github.kolunmi.Bazaar io.github.yucling.open-orpheus com.discordapp.Discord io.github.Predidit.Kazumi
      # QQ/微信 flatpak manifest 用 fallback-x11（仅 Wayland 不可用时才给 X11），
      # 会覆盖 x11 权限 → 沙箱内无 /tmp/.X11-unix → QQ 启动脚本走 xvfb-run 分支
      # → Xvfb 起不来 → 打不开。显式禁 fallback-x11 并给真 x11 socket（幂等）。
      runuser -u cookie -- flatpak --user override --nosocket=fallback-x11 --socket=x11 com.qq.QQ
      runuser -u cookie -- flatpak --user override --nosocket=fallback-x11 --socket=x11 com.tencent.WeChat
      # Open Orpheus（Electron）的托盘要拥有 org.freedesktop.StatusNotifierItem-*
      # 总线名，flatpak D-Bus 代理默认只允许 own 自己的命名空间 → SNI 注册失败
      # （ServiceUnknown）→ 托盘消失。放开 session-bus 后正常注册。
      runuser -u cookie -- flatpak --user override --socket=session-bus io.github.yucling.open-orpheus
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
  # 登录管理器改用 Noctalia Greeter（greetd greeter，与 Noctalia V5 视觉一致），
  # 替代原 ly。模块由 flake 输入 noctalia-greeter 提供（见 flake.nix）。
  imports = [
    noctalia-greeter.nixosModules.default
  ];
  programs.noctalia-greeter = {
    enable = true;
    # 默认会话 niri（会话选择器里其它会话也可选）
    greeter-args = "--session niri";
    settings = {
      cursor = {
        theme = "Adwaita";
        size = 24;
      };
      keyboard.layout = "us";
    };
  };
  # niri 系统模块：装 niri 包 + 自动注册 niri.desktop 到 wayland-sessions
  # （services.displayManager.sessionPackages）+ 官方 portal / gnome-keyring 推荐配置。
  # 注意：26.05 已移除 services.displayManager.session，注册会话要用这个模块。
  programs.niri.enable = true;
  programs.nautilus-open-any-terminal = {
    enable = true;
    terminal = "kitty";
  };
  # ── 登录界面头像（AccountsService / Noctalia Greeter）──
  # greeter 从 AccountsService 读用户头像，声明式写入 /var/lib/AccountsService。
  system.activationScripts.noctaliaGreeterAvatar = lib.stringAfter [ "users" ] ''
    mkdir -p /var/lib/AccountsService/icons
    cp -f ${builtins.toString ./dotfiles/avatar.png} /var/lib/AccountsService/icons/cookie
    chmod 0644 /var/lib/AccountsService/icons/cookie
    chown ${username}:${username} /var/lib/AccountsService/icons/cookie 2>/dev/null || true
    cat > /var/lib/AccountsService/users/cookie <<'EOF'
[User]
SystemAccount=false
Icon=/var/lib/AccountsService/icons/cookie
EOF
  '';

  # GNOME（原 04d-gnome.sh，已弃用，保留以便回退）
  # services.desktopManager.gnome.enable = lib.mkIf (desktop == "gnome") true;
  # services.xserver.displayManager.gdm.enable = lib.mkIf (desktop == "gnome") true;

  # KDE Plasma 6（原 04b-kdeplasma-setup.sh，已弃用）
  # services.desktopManager.plasma6.enable = lib.mkIf (desktop == "kde") true;
  # services.displayManager.sddm.enable = lib.mkIf (desktop == "kde") true;

  # ── 系统级包（少量，其余都在 home.nix）──────────────────
  environment.systemPackages = with pkgs; [
    git
    # NyxNiri 迁移新增依赖（系统级；tmux 供 scratchpad、wlsunset 护眼、inotifywait 壁纸同步、ddcutil 显示器亮度）
    tmux
    wlsunset
    inotify-tools
    ddcutil
    # nm-connection-editor 已在 26.05 移除 → 用自带的 nmtui / nmcli 编辑连接
    # 磁盘/文件系统工具（对应 kde-common-applist）
    gparted dosfstools exfatprogs f2fs-tools udftools xfsprogs
    # 登录管理器 greetd + Noctalia Greeter 由 programs.noctalia-greeter 模块自动装入（见上方）
    # virt-manager/libvirtd 后端（原 99-apps 的 qemu-full + swtpm；libvirtd 已 enable）
    qemu swtpm
    # libvirt 默认 NAT 网络（default）依赖 dnsmasq，缺了 virt-manager 建网失败
    dnsmasq
    # X11 兼容层：xwayland-satellite（niri 25.08+ 开箱集成，binary 在 PATH 时
    # niri 自动按需拉起 Xwayland；微信/LinuxQQ 等 X11 应用因此可正常启动）
    xwayland-satellite
    gamescope       # 基岩版鼠标修复：启动器 wrapperCommand 包装（--force-grab-cursor）
    wl-clipboard    # Waydroid 剪贴板共享
    android-tools   # adb（Waydroid GPS 转发）
    waydroid-helper # Waydroid 配置/扩展 GUI（机型伪装、Magisk、ARM 转译层）
    # waydroid-helper 依赖：rclone（云盘挂载）+ bindfs（目录共享绑定）
    rclone
    bindfs
    # 常用 CLI 工具补全
    libva-utils     # vainfo（VA-API 硬解诊断）
    radeontop       # AMD 显卡占用监控
    gamemode        # Feral GameMode（提供 gamemoderun 命令，Proton/游戏性能优化）
    ripgrep
    tree
    wget
    unzip
    zip
    yq
    b3sum
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
  # Steam UI 中文字体：FHS 环境的 fontconfig 默认只有 DejaVu，中文会变方块
  # ⚠️ 不能用 noto-fonts-cjk-sans（VF 可变字体，Steam 自带 fontconfig 无法渲染 → 中文方块）；
  #    用静态的 sarasa-gothic。见 nixpkgs#178121。
  programs.steam.fontPackages = with pkgs; [ sarasa-gothic ];
  virtualisation.libvirtd.enable = true;  # virt-manager 后端
  # ── Waydroid（Android LXC 容器，niri/Wayland 下运行）──
  # wiki: https://wiki.nixos.org/wiki/Waydroid
  # CachyOS 新内核已移除 iptables → 用 nftables 版
  virtualisation.waydroid.enable = true;
  virtualisation.waydroid.package = pkgs.waydroid-nftables;
  # Waydroid GPS 转发（wiki: GPS/Location forwarding）
  services.geoclue2.enable = true;
  # 26.05 已移除 programs.adb（systemd 258 自动处理 uaccess）→ android-tools 已在上面 systemPackages 里
  # waydroid-helper 的共享目录挂载服务（wiki: Mount host directories）
  systemd.packages = [ pkgs.waydroid-helper ];
  systemd.services.waydroid-mount.wantedBy = [ "multi-user.target" ];
  virtualisation.docker.enable = true;    # docker（wiki: https://wiki.nixos.org/wiki/Docker）
  # Docker Hub 国内镜像源（2026-08 实测可用：1ms.run / 轩辕 / DaoCloud，自动挑最快可用）
  virtualisation.docker.daemon.settings.registry-mirrors = [
    "https://docker.1ms.run"
    "https://docker.xuanyuan.me"
    "https://docker.m.daocloud.io"
  ];
  # udisks2：USB/U盘自动挂载（gvfs-udisks2 监视器需要该系统服务才能识别/挂载）
  services.udisks2.enable = true;

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

  # ── Sunshine（Moonlight 游戏串流）──────────────────────
  # Wayland（niri）需要 capSysAdmin 才能用 KMS 抓屏；
  # uinput 组让 Sunshine 能模拟虚拟键鼠/手柄输入设备。
  services.sunshine = {
    enable = true;
    autoStart = false;
    capSysAdmin = true;
    openFirewall = true;
  };
  hardware.uinput.enable = true;

  # ── 用户（必须存在，否则 home-manager 报错）──────────────
  users.users.${username} = {
    isNormalUser = true;
    description = username;
    extraGroups = [ "networkmanager" "wheel" "libvirtd" "video" "audio" "docker" "uinput" ];
    # 设置密码（或安装后用 `passwd`）：
    # initialPassword = "changeme";
  };
}
