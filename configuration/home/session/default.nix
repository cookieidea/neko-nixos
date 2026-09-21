# 用户身份、会话变量（PATH/PYTHONPATH/GIO 等）
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
  # 定义见 configuration/home/lib.nix 的 devEnv（单一数据源）
  // hmLib.devEnv;
  # 注：曾在此挂 LD_LIBRARY_PATH（systemdLibs/pipewire-jack/gcc），
  # 会污染整个用户 session 的所有动态链接程序。现已按需下沉：
  #   ABDM  → 其自身 wrapper + autostart drop-in
  #   MC    → hmcl / lunarclient wrapper（见 lib.nix 的 mcJavaLibPath）
}
