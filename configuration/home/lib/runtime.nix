# 运行时 wrapper 与共享库路径。
#
# 这些派生原本散落在各处或依赖全局 LD_LIBRARY_PATH，
# 现集中在此并只注入对应程序的 wrapper（故障域限定）。
{ pkgs, selfPackages }:

# 需要 rec：mpvRifeWrapped 的 extraMakeWrapperArgs 引用同级的 pySite。
rec {
  # Python site-packages 相对路径（供 mpvRifeWrapped 注入 PYTHONPATH）
  pySite = pkgs.python3.sitePackages;

  # Minecraft 运行库只注入相关 wrapper，避免污染整个用户 session。
  # libopenal 的 JACK 后端为运行时 dlopen（NEEDED 查不到）。
  mcJavaLibPath =
    "${pkgs.pipewire.jack}/lib:${pkgs.stdenv.cc.cc.lib}/lib";


  # mpv + VapourSynth/RIFE。
  #
  # 注意：nixpkgs 没有 `wrapMpv` 这个属性 —— pkgs.mpv 本身就是 callPackage
  # 出的函数，接受 mpv-unwrapped、extraMakeWrapperArgs 等参数。故用两级
  # override：先换 mpv-unwrapped，再补 wrapper 参数，一次得到最终包装
  # （不再对其结果二次 symlinkJoin 包装）。
  mpvRifeWrapped = (pkgs.mpv.override {
    mpv-unwrapped = pkgs.mpv-unwrapped.override {
      lua = pkgs.luajit;
      vapoursynthSupport = true;
    };
  }).override {
    extraMakeWrapperArgs = [
      "--prefix" "PYTHONPATH" ":" "${selfPackages.k7sfunc}/${pySite}:${pkgs.python3Packages.vapoursynth}/${pySite}"
      "--set" "VAPOURSYNTH_EXTRA_PLUGIN_PATH" "${selfPackages.vapoursynth-with-plugins}/lib/vapoursynth"
    ];
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
