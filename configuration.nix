# NixOS 系统配置
{ config, pkgs, lib, username, noctalia-greeter, ... }:

{
  # 内核：CachyOS RT-BORE（实时调度 + BORE，直播/推流低延迟）
  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-rt-bore;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  # 二进制缓存：国内优先（USTC + TUNA），attic 供 CachyOS 内核，
  # noctalia.cachix.org 供 Noctalia 系包，cache.nixos.org 最后兜底。
  # 用 substituters（显式覆盖）而不是 extra-：extra- 会追加到默认的
  # cache.nixos.org 之后，等于官方源永远先命中（而它国内最慢），
  # 国内镜像只沦为兜底。
  nix.settings.substituters = [
    "https://mirrors.ustc.edu.cn/nix-channels/store"
    "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
    "https://attic.xuyh0120.win/lantian"
    "https://noctalia.cachix.org"
    "https://cache.nixos.org"
  ];
  nix.settings.trusted-public-keys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
    "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
  ];
  nixpkgs.config = {
    allowUnfree = true;   # steam / wechat-uos / 部分驱动需要
  };
  security.polkit.enable = true;
  # Noctalia greeter 外观同步（pkexec）免密放行 wheel
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
        if (action.id == "org.noctalia.greeter.apply-appearance" &&
            subject.isInGroup("wheel")) {
            return polkit.Result.YES;
        }
    });
  '';

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
  boot.loader.timeout = 10; # GRUB 选择系统等待 10s

  # 引导：GRUB(UEFI) + os-prober（双系统检测 Windows）；efiInstallAsRemovable 兜底
  boot.loader.grub = {
    enable = true;
    useOSProber = true;
    efiSupport = true;
    device = "nodev";
    configurationLimit = 20;
    efiInstallAsRemovable = true;
    # BlueArchive 主题：yuzu(柚子)/tao(桃)/nagisa(渚)/aris(爱丽丝)/midori(绿)
    theme = ./grub-theme/aris/Alice;
  };
  boot.supportedFilesystems = [ "btrfs" ];
  boot.initrd.supportedFilesystems = [ "btrfs" ];

  # 休眠：btrfs swapfile 官方不支持恢复 → 独立 SWAP 分区（docs/install-btrfs.md 创建）。
  # 显式声明 resumeDevice 兜底（26.05 initrd 会自动检测，异常 EFI 主板也可靠）。
  boot.resumeDevice = "/dev/disk/by-label/SWAP";
  # LACT / AMD 超频解锁（ppfeaturemask 全开）
  boot.kernelParams = [ "amdgpu.ppfeaturemask=0xffffffff" "clearcpuid=514" ];

  networking.hostName = "ATRI";
  networking.firewall.enable = false;
  networking.networkmanager.enable = true;
  # DNS：腾讯 DNSPod；dns="none" 让 nameservers 静态写入（不被 DHCP 覆盖）
  networking.networkmanager.dns = "none";
  networking.nameservers = [ "119.29.29.29" "2402:4e00::" ];
  systemd.services.NetworkManager-wait-online.enable = false; # 去掉 4.9s 阻塞（flatpak-repo 等待 network-online）
  # 组播回环：IPv4 组播经 lo 投递（Axolotl 联机扫描依赖；cachyos 内核需显式加路由）
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

  time.timeZone = "Asia/Shanghai";
  i18n.defaultLocale = "zh_CN.UTF-8";

  # 输入法 fcitx5：rime + 雾凇拼音（rime-ice）。waylandFrontend（niri 走 text-input-v3）
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      waylandFrontend = true;
      addons = with pkgs; [
        (fcitx5-rime.override {
          rimeDataPkgs = [ rime-data rime-ice ];
        })
        # fcitx5-chinese-addons 不用：硬依赖 qtwebengine，其在 GCC 15 下编译崩溃
      ];
    };
  };

  # 音频：PipeWire（pulse/alsa/jack）
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
    jack.enable = true;
  };

  hardware.bluetooth.enable = true;
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;
  services.blueman.enable = true;

  # GPU：AMD 6750 GRE（amdgpu + mesa RADV + VA-API 硬解）
  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;   # Steam/Proton 32 位游戏必需
  hardware.graphics.extraPackages = with pkgs; [
    vulkan-loader
    libva
  ];
  services.xserver.videoDrivers = [ "amdgpu" ];
  # 12400F 无核显 → 不需要 intel 驱动；非笔记本双显卡 → 不需要 NVIDIA Prime/offload。

  services.openssh.enable = true;

  # Flatpak：26.05 移除声明式 remotes → 启动时 one-shot 添加 + 自动装应用（幂等）
  services.flatpak.enable = true;
  systemd.services.flatpak-repo = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    path = [ pkgs.flatpak pkgs.util-linux ];
    script = ''
      flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
      flatpak remote-modify flathub --url=https://mirrors.ustc.edu.cn/flathub
      flatpak install --noninteractive --or-update flathub com.tencent.WeChat com.qq.QQ com.github.tchx84.Flatseal io.github.kolunmi.Bazaar io.github.yucling.open-orpheus com.discordapp.Discord io.github.Predidit.Kazumi
      # QQ/微信：禁 fallback-x11 并给真 x11 socket（否则 Xvfb 起不来打不开）
      runuser -u ${username} -- flatpak --user override --nosocket=fallback-x11 --socket=x11 com.qq.QQ
      runuser -u ${username} -- flatpak --user override --nosocket=fallback-x11 --socket=x11 com.tencent.WeChat
      # Open Orpheus 托盘：放开 session-bus（SNI 总线名注册需要）
      runuser -u ${username} -- flatpak --user override --socket=session-bus io.github.yucling.open-orpheus
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };

  # XDG 桌面门户
  xdg.portal.enable = true;
  programs.dconf.enable = true;   # home-manager gtk 模块写主题设置需要
  # hyprland portal 兜底：部分 Wayland App 屏幕共享只认它
  xdg.portal.extraPortals = with pkgs; [ xdg-desktop-portal-gtk xdg-desktop-portal-gnome xdg-desktop-portal-hyprland ];
  xdg.portal.config.common.default = "gtk";

  # 显示服务器 + 登录：niri（Wayland 平铺）+ Noctalia Greeter（greetd）
  imports = [
    noctalia-greeter.nixosModules.default
  ];
  programs.noctalia-greeter = {
    enable = true;
    greeter-args = "--session niri";
    settings = {
      cursor = {
        theme = "Adwaita";
        size = 24;
      };
      keyboard.layout = "us";
    };
  };
  # niri 系统模块（26.05 起用 programs.niri 注册会话，displayManager.session 已移除）
  programs.niri.enable = true;
  programs.nautilus-open-any-terminal = {
    enable = true;
    terminal = "kitty";
  };
  # 登录界面头像（AccountsService，greeter 读取）
  system.activationScripts.noctaliaGreeterAvatar = lib.stringAfter [ "users" ] ''
    mkdir -p /var/lib/AccountsService/icons
    cp -f ${builtins.toString ./dotfiles/avatar.png} /var/lib/AccountsService/icons/${username}
    chmod 0644 /var/lib/AccountsService/icons/${username}
    chown ${username}:${username} /var/lib/AccountsService/icons/${username} 2>/dev/null || true
    cat > /var/lib/AccountsService/users/${username} <<'EOF'
[User]
SystemAccount=false
Icon=/var/lib/AccountsService/icons/${username}
EOF
  '';

  # 系统级包（其余在 home.nix）
  environment.systemPackages = with pkgs; [
    git
    tmux             # scratchpad
    wlsunset         # 护眼
    inotify-tools    # 壁纸同步
    ddcutil          # 显示器亮度
    gparted dosfstools exfatprogs f2fs-tools udftools xfsprogs   # 磁盘工具
    qemu swtpm       # virt-manager 后端
    dnsmasq          # libvirt NAT 网络依赖
    xwayland-satellite   # X11 兼容（微信/QQ 等）
    gamescope        # 基岩版鼠标修复（--force-grab-cursor）
    wl-clipboard     # Waydroid 剪贴板共享
    android-tools    # adb（Waydroid GPS 转发）
    waydroid-helper  # Waydroid 配置 GUI
    rclone bindfs    # waydroid-helper 依赖
    libva-utils      # vainfo 硬解诊断
    radeontop        # AMD 占用监控
    gamemode         # gamemoderun（Proton 性能优化）
    ripgrep tree wget unzip zip yq b3sum
    cachix
  ];

  fonts.packages = with pkgs; [
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    sarasa-gothic
    jetbrains-mono
    nerd-fonts.jetbrains-mono
  ];

  # 应用级服务
  services.lact.enable = true;
  services.smartd.enable = true;   # 磁盘健康监控（SMART）
  programs.gamemode.enable = true; # gamemoderun 系统服务（游戏性能优化）
  programs.nix-ld.enable = true;   # 跑预编译二进制（游戏/工具的 patchelf 兜底）
  programs.steam.enable = true;
  # Steam 中文字体：FHS fontconfig 渲染不了 VF（noto-cjk）→ 用静态 sarasa
  programs.steam.fontPackages = with pkgs; [ sarasa-gothic ];
  # GE-Proton（声明式；Steam 里直接选 compattool）
  programs.steam.extraCompatPackages = with pkgs; [ proton-ge-bin ];
  virtualisation.libvirtd.enable = true;
  # Waydroid（Android 容器；CachyOS 内核已移除 iptables → 用 nftables 版）
  virtualisation.waydroid.enable = true;
  virtualisation.waydroid.package = pkgs.waydroid-nftables;
  services.geoclue2.enable = true;   # Waydroid GPS 转发
  systemd.packages = [ pkgs.waydroid-helper ];
  systemd.services.waydroid-mount.wantedBy = [ "multi-user.target" ];
  virtualisation.docker.enable = true;
  # Docker Hub 国内镜像
  virtualisation.docker.daemon.settings.registry-mirrors = [
    "https://docker.1ms.run"
    "https://docker.xuanyuan.me"
    "https://docker.m.daocloud.io"
  ];
  # distrobox：容器内挂载 /nix/store 与 per-user profiles（shell 初始化引用
  # hm-session-vars.sh 等路径，默认只挂 $HOME 会报 no such file）
  environment.etc."distrobox/distrobox.conf".text = ''
    container_additional_volumes="/nix/store:/nix/store:ro /etc/profiles/per-user:/etc/profiles/per-user:ro /etc/static/profiles/per-user:/etc/static/profiles/per-user:ro"
  '';

  services.udisks2.enable = true;   # USB 自动挂载

  # btrfs + snapper 快照（@snapshots 独立子卷，回滚根时不带快照）
  # 26.05：键名全大写（SUBVOLUME/TIMELINE_*）；旧 camelCase 被静默吞掉 → 快照不生效
  services.snapper = {
    snapshotRootOnBoot = true;
    configs."root" = {
      SUBVOLUME = "/";
      TIMELINE_CREATE = true;
      TIMELINE_LIMIT_HOURLY = 24;
      TIMELINE_LIMIT_DAILY = 7;
      TIMELINE_LIMIT_WEEKLY = 4;
      TIMELINE_LIMIT_MONTHLY = 0;
      TIMELINE_LIMIT_YEARLY = 0;
      EMPTY_PRE_POST_CLEANUP = true;
      NUMBER_LIMIT = 0;
    };
  };
  # 26.05 移除 grub-btrfs → 无 GRUB 快照子菜单；回滚走 generation + snapper

  # Sunshine（Moonlight 串流）：capSysAdmin 供 KMS 抓屏，uinput 模拟键鼠/手柄
  services.sunshine = {
    enable = true;
    autoStart = false;
    capSysAdmin = true;
    openFirewall = true;
  };
  hardware.uinput.enable = true;

  users.users.${username} = {
    isNormalUser = true;
    description = username;
    extraGroups = [ "networkmanager" "wheel" "libvirtd" "video" "audio" "docker" "uinput" "adbusers" "gamemode" ];
  };
}
