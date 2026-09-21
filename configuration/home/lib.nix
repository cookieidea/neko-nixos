# home 模块共用的 let 绑定（经 flake.nix extraSpecialArgs 注入为 hmLib）
{ pkgs, selfPackages, username }:

rec {
  # ── 编程工具链环境（单一数据源）──
  # 这些值需同时出现在两处，缺一不可：
  #   ① home.sessionVariables      → 登录 shell（写进 ~/.profile）
  #   ② systemd.user.sessionVariables → systemd 启动的服务（niri 不读 profile）
  # 集中在 lib.nix 定义，避免两处各写一份导致漂移。
  devEnv = {
    JAVA_HOME = "${pkgs.zulu25}";          # 默认 JDK（HMCL 等多版本可自选）
    CARGO_HOME = "$HOME/.cargo";
    PYTHONPATH = "${pkgs.python3Packages.pygobject3}/lib/python3.13/site-packages:${selfPackages.k7sfunc}/lib/python3.13/site-packages:${pkgs.python3Packages.vapoursynth}/lib/python3.13/site-packages";
    VAPOURSYNTH_EXTRA_PLUGIN_PATH = "${selfPackages.vapoursynth-with-plugins}/lib/vapoursynth";
  };

  # 编程工具的用户级 bin（进 PATH）
  devBinPath = [ "$HOME/.cargo/bin" "$HOME/.npm-global/bin" ];

  # 共享库路径：systemdLibs（ABDM 托盘）+ pipewire-jack（ABDM/MC）
  # shell 侧额外拼 gcc lib —— MC natives 的 shaderc/spirv-cross 等 dlopen 它
  ldLibraryPath = "${pkgs.systemdLibs}/lib:${pkgs.pipewire.jack}/lib";
  ldLibraryPathShell = "${ldLibraryPath}:${pkgs.stdenv.cc.cc.lib}/lib";

  # Nautilus C 扩展目录（systemd 侧与系统会话侧同源）
  nautilusExtensionDir =
    "${selfPackages.nautilus-with-extensions}/lib/nautilus/extensions-4";

  # ── 包管理器国内镜像（files.nix 部署为真实文件）──
  # npm：prefix 用绝对路径——npm 不对 prefix 做 $HOME 展开
  npmrc = ''
    registry=https://registry.npmmirror.com
    prefix=/home/${username}/.npm-global
  '';
  cargoConfig = ''
    [source.crates-io]
    replace-with = 'ustc'
    [source.ustc]
    registry = "sparse+https://mirrors.ustc.edu.cn/crates.io-index/"
    [net]
    git-fetch-with-cli = true
  '';
  pipConf = ''
    [global]
    index-url = https://mirrors.ustc.edu.cn/pypi/simple
    trusted-host = mirrors.ustc.edu.cn
  '';
  uvToml = ''
    [[index]]
    url = "https://mirrors.ustc.edu.cn/pypi/simple"
    default = true
  '';

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
