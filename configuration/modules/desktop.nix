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

  # AMD 的 DCC 修饰符无法用于 scanout，wlroots 逐个探测时每条刷一行 ERROR，
  # 一次启动能到数百万行。写 services.greetd.settings，greeter 自己的
  # greeter.toml 没有 command 字段。
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
