# 桌面会话、登录界面、门户和字体。
{ pkgs, lib, username, noctalia-greeter, selfPackages, ... }:

{
  # Wayland 桌面与 Noctalia 登录界面。
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
