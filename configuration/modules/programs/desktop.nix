# 桌面会话：niri、Noctalia Greeter、XDG 门户、Flatpak、字体、系统包
{ pkgs, lib, username, noctalia-greeter, selfPackages, ... }:

{
  # 显示服务器 + 登录：niri（Wayland 平铺）+ Noctalia Greeter（greetd）
  imports = [
    noctalia-greeter.nixosModules.default
  ];
  services.displayManager.noctalia-greeter = {
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
  # niri 系统模块
  programs.niri.enable = true;
  programs.nautilus-open-any-terminal = {
    enable = true;
    terminal = "kitty";
  };
  # nautilus C 扩展统一目录
  environment.sessionVariables.NAUTILUS_4_EXTENSION_DIR = lib.mkForce
    "${selfPackages.nautilus-extensions.nautilus-with-extensions}/lib/nautilus/extensions-4";
  # 登录界面头像（AccountsService，greeter 读取）
  system.activationScripts.noctaliaGreeterAvatar = lib.stringAfter [ "users" ] ''
    mkdir -p /var/lib/AccountsService/icons
    cp -f ${builtins.toString ../../home/dotfiles/avatar.png} /var/lib/AccountsService/icons/${username}
    chmod 0644 /var/lib/AccountsService/icons/${username}
    chown ${username}:${username} /var/lib/AccountsService/icons/${username} 2>/dev/null || true
    cat > /var/lib/AccountsService/users/${username} <<'EOF'
[User]
SystemAccount=false
Icon=/var/lib/AccountsService/icons/${username}
EOF
  '';

  # XDG 桌面门户（niri 模块已提供 gnome+gtk 与 gnome-keyring 配置，见 nixos/modules/programs/wayland/niri.nix）
  xdg.portal.enable = true;
  programs.dconf.enable = true;   # home-manager gtk 模块依赖

  # AppImage：注册 binfmt_misc，使 .AppImage 文件可直接执行（无需手动 appimage-run）
  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  # Flatpak：启动时 one-shot 添加 remote + 自动装应用
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

  # 系统级包
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
    grim             # Wayland 截图（mark-shot/niri 依赖）
    kdePackages.layer-shell-qt  # Qt6 Wayland layer-shell（mark-shot overlay）
    gtk-layer-shell  # GTK Wayland layer-shell
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
  ] ++ [ selfPackages.harmonyos-sans-sc ];

  fonts.fontconfig = {
    defaultFonts = {
      sansSerif = [ "HarmonyOS Sans SC" ];
      serif = [ "HarmonyOS Sans SC" ];
    };
    localConf = ''
      <match target="pattern">
        <edit name="weight" mode="append"><const>medium</const></edit>
      </match>
    '';
  };
}
