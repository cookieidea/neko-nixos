# 用户身份、会话变量（PATH/PYTHONPATH/GIO/LD_LIBRARY_PATH 等）
{ hmLib, pkgs, username, selfPackages, ... }:

{
  imports = [ ./systemd.nix ];

  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "26.05";

  # kitty terminfo（TERM=xterm-kitty）
  # ~/.local/bin 进 PATH（quicksave/quickload 等私有脚本）
  home.sessionPath = [ "${selfPackages.vapoursynth-with-plugins}/bin" "$HOME/.local/bin" ] ++ hmLib.devBinPath;
  home.sessionVariables = {
    TERMINFO_DIRS = "${pkgs.kitty}/share/terminfo";
    GIO_EXTRA_MODULES = "${pkgs.gvfs}/lib/gio/modules:${pkgs.dconf}/lib/gio/modules";   # gvfs URI（trash:// 等）
    # gsettings schema 路径（gtk3 + gsettings-desktop-schemas）
    GSETTINGS_SCHEMA_DIR = "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}/glib-2.0/schemas:${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}/glib-2.0/schemas";
  }
  # 编程工具链（JAVA_HOME/CARGO_HOME/PYTHONPATH/VapourSynth）+ 共享库路径
  # 定义见 modules/home/lib.nix 的 devEnv / ldLibraryPathShell（单一数据源）
  // hmLib.devEnv
  // { LD_LIBRARY_PATH = hmLib.ldLibraryPathShell; };
}
