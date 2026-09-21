# 桌面会话、登录界面、门户和字体。
{ pkgs, lib, username, noctalia-greeter, selfPackages, ... }:

{
  # Wayland 桌面与 greetd 登录界面。
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
  # niri。
  programs.niri.enable = true;
  programs.nautilus-open-any-terminal = {
    enable = true;
    terminal = "kitty";
  };
  # Nautilus C 扩展目录。
  environment.sessionVariables.NAUTILUS_4_EXTENSION_DIR = lib.mkForce
    "${selfPackages.nautilus-with-extensions}/lib/nautilus/extensions-4";
  # AccountsService 登录头像。
  system.activationScripts.noctaliaGreeterAvatar = lib.stringAfter [ "users" ] ''
    mkdir -p /var/lib/AccountsService/icons
    cp -f ${builtins.toString ../home/dotfiles/avatar.png} /var/lib/AccountsService/icons/${username}
    chmod 0644 /var/lib/AccountsService/icons/${username}
    chown ${username}:${username} /var/lib/AccountsService/icons/${username} 2>/dev/null || true
    cat > /var/lib/AccountsService/users/${username} <<'EOF'
[User]
SystemAccount=false
Icon=/var/lib/AccountsService/icons/${username}
EOF
  '';

  # XDG desktop portal。
  xdg.portal.enable = true;
  programs.dconf.enable = true;   # home-manager gtk 模块依赖

  # 注册 AppImage 的 binfmt_misc 支持。
  programs.appimage = {
    enable = true;
    binfmt = true;
  };


  # 系统级桌面包。
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
