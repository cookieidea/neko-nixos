# OBS、KDE Connect 和 GTK。
{ pkgs, selfPackages, ... }:

{
  programs.obs-studio = {
    enable = true;
    plugins = [
      selfPackages.obs-vdoninja
      # OBS 自带没有按应用抓音频，Linux 侧用 PipeWire 节点实现。
      pkgs.obs-studio-plugins.obs-pipewire-audio-capture
      pkgs.obs-studio-plugins.obs-composite-blur
      pkgs.obs-studio-plugins.obs-source-record
      pkgs.obs-studio-plugins.obs-vkcapture
      pkgs.obs-studio-plugins.input-overlay
      pkgs.obs-studio-plugins.obs-wayland-hotkeys
    ];
  };

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
