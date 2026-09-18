# home.nix 拆分后各模块共用的 let 绑定（原 home.nix 顶部的 let 块）
#
# 通过 flake.nix 的 home-manager.extraSpecialArgs 注入为 `hmLib`，各 home 模块
# 在参数里 `hmLib, ...` 取用。这样各段正文保持原样（只改 ./ → ../../ 路径）。
{ pkgs, selfPackages }:

rec {
  # mpv + RIFE 补帧（VapourSynth；k7sfunc 需要 luajit + vapoursynth 支持）
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

  # 可写种子源（store 路径，供 activation 脚本复制出可写真实文件）
  seedKittyTheme     = builtins.toString ./dotfiles/config/kitty/themes/noctalia.conf;
  seedNoctaliaConfig = builtins.toString ./dotfiles/config/noctalia/config.toml;
  seedStarship       = builtins.toString ./dotfiles/config/starship.toml;
  seedMangoHud       = builtins.toString ./dotfiles/config/MangoHud/MangoHud.conf;
  seedWallpaperDir   = builtins.toString ./dotfiles/Pictures/Wallpapers;
  seedWallpaperVideo = builtins.toString ./dotfiles/Pictures/Wallpapers/video/hatsune-miku.mp4;

  # Lunar Client 的 SDL 强制原生 Wayland。niri 26.04 没有实现 wp_fifo_manager_v1，
  # SDL3 检出后为「GPU 性能」自动改走 XWayland，而 XWayland 下取不到 OpenGL 函数
  # → 游戏启动即崩（BackendCreationException: Could not retrieve OpenGL functions）。
  # 与 hmcl 同一个坑、同一个解法；包本体不改，只在外层包一层设环境变量。
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

  # trash:// 等 gvfs URI 交给 gio（原 xdg-open 不认这些 scheme）
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
