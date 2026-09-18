# 用户身份、会话变量（PATH/PYTHONPATH/GIO/LD_LIBRARY_PATH 等）
{ hmLib, pkgs, username, selfPackages, ... }:

{
  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "26.05";

  # kitty terminfo（TERM=xterm-kitty）
  # ~/.local/bin 进 PATH（quicksave/quickload 等私有脚本）
  home.sessionPath = [ "${selfPackages.vapoursynth-with-plugins}/bin" "$HOME/.local/bin" "$HOME/.cargo/bin" "$HOME/.npm-global/bin" ];
  home.sessionVariables = {
    TERMINFO_DIRS = "${pkgs.kitty}/share/terminfo";
    GIO_EXTRA_MODULES = "${pkgs.gvfs}/lib/gio/modules:${pkgs.dconf}/lib/gio/modules";   # gvfs URI（trash:// 等）
    # nautilus 扩展 + mpv RIFE 共用 Python 模块路径
    PYTHONPATH = "${pkgs.python3Packages.pygobject3}/lib/python3.13/site-packages:${selfPackages.k7sfunc}/lib/python3.13/site-packages:${pkgs.python3Packages.vapoursynth}/lib/python3.13/site-packages";
    # VapourSynth 插件（lsmas / akarin / RIFE-ncnn / mvtools）
    VAPOURSYNTH_EXTRA_PLUGIN_PATH = "${selfPackages.vapoursynth-with-plugins}/lib/vapoursynth";
    # 覆盖语义，须拼接（ABDM 托盘 + MC natives）
    LD_LIBRARY_PATH = "${pkgs.systemdLibs}/lib:/nix/store/zcqp398mxlw62jl02sx0rsc7gvcl1qhc-pipewire-1.6.6-jack/lib:${pkgs.stdenv.cc.cc.lib}/lib";
    JAVA_HOME = "${pkgs.zulu25}";
    # gsettings schema 路径（gtk3 + gsettings-desktop-schemas）
    GSETTINGS_SCHEMA_DIR = "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}/glib-2.0/schemas:${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}/glib-2.0/schemas";
    CARGO_HOME = "$HOME/.cargo";
  };
}
