# home 模块共用的 let 绑定（经 flake.nix extraSpecialArgs 注入为 hmLib）
{ pkgs, selfPackages }:

rec {
  # mpv + RIFE 补帧（VapourSynth）
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
        --prefix PYTHONPATH : "${selfPackages.k7sfunc}/lib/python3.13/site-packages:${pkgs.python3Packages.vapoursynth}/lib/python3.13/site-packages" \
        --set VAPOURSYNTH_EXTRA_PLUGIN_PATH "${selfPackages.vapoursynth-with-plugins}/lib/vapoursynth"
    '';
  };

  # 可写种子源（activation 复制用）
  seedKittyTheme     = builtins.toString ./dotfiles/config/kitty/themes/noctalia.conf;
  seedNoctaliaConfig = builtins.toString ./dotfiles/config/noctalia/config.toml;
  seedStarship       = builtins.toString ./dotfiles/config/starship.toml;
  seedMangoHud       = builtins.toString ./dotfiles/config/MangoHud/MangoHud.conf;
  seedWallpaperDir   = builtins.toString ./dotfiles/Pictures/Wallpapers;
  seedWallpaperVideo = builtins.toString ./dotfiles/Pictures/Wallpapers/video/hatsune-miku.mp4;

  # Lunar Client 强制 SDL 原生 Wayland（niri 下走 XWayland 会崩）
  lunarclientWayland = pkgs.symlinkJoin {
    name = "lunar-client-wayland";
    paths = [ pkgs.lunar-client ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      rm -f $out/bin/lunarclient
      makeWrapper ${pkgs.lunar-client}/bin/lunarclient $out/bin/lunarclient \
        --set SDL_VIDEO_DRIVER wayland
    '';
  };

  # trash:// 等 gvfs URI 交给 gio
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
