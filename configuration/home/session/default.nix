# 用户身份与会话环境变量。
{ hmLib, pkgs, username, selfPackages, ... }:

{
  imports = [ ./systemd.nix ];

  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "26.05";

  # Kitty terminfo。
  # 用户脚本目录。
  home.sessionPath = [ "${selfPackages.vapoursynth-with-plugins}/bin" "$HOME/.local/bin" ] ++ hmLib.devBinPath;
  home.sessionVariables = {
    TERMINFO_DIRS = "${pkgs.kitty}/share/terminfo";
    GIO_EXTRA_MODULES = "${pkgs.gvfs}/lib/gio/modules:${pkgs.dconf}/lib/gio/modules";   # gvfs URI（trash:// 等）
    # GSettings schema 路径。
    GSETTINGS_SCHEMA_DIR = "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}/glib-2.0/schemas:${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}/glib-2.0/schemas";
  }
  # 开发环境变量来自 home/lib.nix 的 devEnv。
  // hmLib.devEnv;
  # 按需注入运行库，避免全局 LD_LIBRARY_PATH 污染。
}
