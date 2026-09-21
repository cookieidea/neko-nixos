# 运行时 wrapper 与共享库路径。
#
# 这些派生原本散落在各处或依赖全局 LD_LIBRARY_PATH，
# 现集中在此并只注入对应程序的 wrapper（故障域限定）。
{ pkgs, selfPackages }:

# 需要 rec：mpvRifeWrapped 引用同级的 mpvRife
rec {
  # Python site-packages 相对路径（供 mpvRifeWrapped 注入 PYTHONPATH）
  pySite = pkgs.python3.sitePackages;

  # Minecraft 运行库只注入相关 wrapper，避免污染整个用户 session。
  # libopenal 的 JACK 后端为运行时 dlopen（NEEDED 查不到）。
  mcJavaLibPath =
    "${pkgs.pipewire.jack}/lib:${pkgs.stdenv.cc.cc.lib}/lib";

  # Nautilus C 扩展目录。
  nautilusExtensionDir =
    "${selfPackages.nautilus-with-extensions}/lib/nautilus/extensions-4";

  # mpv + VapourSynth/RIFE。
  mpvRife = pkgs.mpv.override {
    mpv-unwrapped = pkgs.mpv-unwrapped.override {
      lua = pkgs.luajit;
      vapoursynthSupport = true;
    };
  };
  mpvRifeWrapped = pkgs.symlinkJoin {
    name = "mpv-rife";
    paths = [ mpvRife ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      rm -f "$out/bin/mpv"
      makeWrapper "${mpvRife}/bin/mpv" "$out/bin/mpv" \
        --prefix PYTHONPATH : "${selfPackages.k7sfunc}/${pySite}:${pkgs.python3Packages.vapoursynth}/${pySite}" \
        --set VAPOURSYNTH_EXTRA_PLUGIN_PATH "${selfPackages.vapoursynth-with-plugins}/lib/vapoursynth"
    '';
  };

  # Lunar Client 强制使用原生 Wayland，并补 MC 所需运行库。
  lunarclientWayland = pkgs.symlinkJoin {
    name = "lunar-client-wayland";
    paths = [ pkgs.lunar-client ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      rm -f $out/bin/lunarclient
      makeWrapper ${pkgs.lunar-client}/bin/lunarclient $out/bin/lunarclient \
        --set SDL_VIDEO_DRIVER wayland \
        --prefix LD_LIBRARY_PATH : "${pkgs.pipewire.jack}/lib:${pkgs.stdenv.cc.cc.lib}/lib"
    '';
  };

  # 将 GVFS URI 交给 gio，其余路径继续使用 xdg-open。
  xdgOpenWithGio = pkgs.writeShellScriptBin "xdg-open" ''
    for arg in "$@"; do
      case "$arg" in
        trash://*|computer://*|network://*|smb://*|sftp://*|ftp://*|mtp://*|gphoto2://*)
          exec ${pkgs.glib}/bin/gio open "$arg"
          ;;
      esac
    done
    exec ${pkgs.xdg-utils}/bin/xdg-open "$@"
  '';
}
