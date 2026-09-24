# 桌面会话、登录界面、门户和字体。
{ pkgs, lib, username, noctalia-greeter, selfPackages, ... }:

let
  packages = noctalia-greeter.packages.${pkgs.stdenv.hostPlatform.system};
in

{
  # Wayland 桌面与 Noctalia 登录界面。
  imports = [
    noctalia-greeter.nixosModules.default
  ];
  services.displayManager.noctalia-greeter = {
    enable = true;
    greeter-args = "--session niri";
    # 允许本用户免密执行「仅外观」的同步（greeter 与桌面之间同步主题等）。
    # 用上游选项而非自定义 polkit 规则：上游会额外限定 action、
    # 目标须为 root，且调用者须为本地活跃会话中的允许用户。
    passwordless-sync-users = [ username ];
    settings = {
      cursor = {
        theme = "Adwaita";
        size = 24;
      };
      keyboard.layout = "us";
    };
  };

  # greeter 的 wlroots 合成器逐个探测 DRM 格式/修饰符组合，对不支持的组合各打
  # 一条 ERROR。AMD 上 DCC 修饰符无法用于 scanout，实测一次启动刷出约 429 万行
  # （占该次启动日志总量的 99.2%）：
  #   [backend/drm/fb.c] Buffer format 0x34325241 with modifier ... cannot be scanned out
  #   [backend/drm/drm.c] connector HDMI-A-1: Failed to import buffer for scan-out
  # 不影响功能（greeter 正常启动、登录成功），只是噪音。
  # WLR_DRM_NO_MODIFIERS 让 wlroots 直接用线性格式，跳过这些探测。
  # 注意要用 services.greetd.settings（greetd 的会话配置），而不是上面
  # noctalia-greeter 自己的 greeter.toml —— 后者没有 environment/command 之类
  # 的会话字段。greetd 只认 command/user，故这里用 env 前缀注入；
  # noctalia-greeter-session 对未列出的环境变量是继承的。
  services.greetd.settings.default_session.command = lib.mkForce (
    "env WLR_DRM_NO_MODIFIERS=1 ${packages.default}/bin/noctalia-greeter-session"
    + " -- --session niri"
  );
  # niri。
  programs.niri.enable = true;
  programs.nautilus-open-any-terminal = {
    enable = true;
    terminal = "kitty";
  };
  # AccountsService 登录头像。
  system.activationScripts.noctaliaGreeterAvatar = lib.stringAfter [ "users" ] ''
    mkdir -p /var/lib/AccountsService/icons
    cp -f ${../home/dotfiles/avatar.png} /var/lib/AccountsService/icons/${username}
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
  xdg.portal.extraPortals = with pkgs; [
    xdg-desktop-portal-gnome
    xdg-desktop-portal-gtk
  ];
  programs.dconf.enable = true;   # home-manager gtk 模块依赖

  # 注册 AppImage 的 binfmt_misc 支持。
  programs.appimage = {
    enable = true;
    binfmt = true;
  };


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
