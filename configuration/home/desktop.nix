# 桌面权限、OBS、KDE Connect 和 GTK。
{ pkgs, selfPackages, ... }:

{
  services.polkit-gnome.enable = true;

  # OBS Studio 及其插件。
  programs.obs-studio = {
    enable = true;
    plugins = [ selfPackages.obs-vdoninja ];
  };

  # KDE Connect。
  services.kdeconnect = {
    enable = true;
    indicator = true;
  };

  # GTK 主题和图标。
  gtk = {
    enable = true;
    iconTheme = {
      name = "Papirus";
      package = pkgs.papirus-icon-theme;
    };
    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };
    cursorTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };
    font = {
      name = "HarmonyOS Sans SC";
      size = 10;
    };
    gtk2.extraConfig = ''
      gtk-im-module="fcitx"
    '';
    gtk3.extraConfig = {
      gtk-toolbar-style = "GTK_TOOLBAR_ICONS";
      gtk-toolbar-icon-size = "GTK_ICON_SIZE_LARGE_TOOLBAR";
      gtk-button-images = "0";
      gtk-menu-images = "0";
      gtk-enable-event-sounds = "1";
      gtk-enable-input-feedback-sounds = "0";
      gtk-xft-antialias = "1";
      gtk-xft-hinting = "1";
      gtk-xft-hintstyle = "hintslight";
      gtk-xft-rgba = "rgb";
      gtk-application-prefer-dark-theme = "1";
    };
  };
}
