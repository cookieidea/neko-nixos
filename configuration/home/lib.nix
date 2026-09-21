# Home 模块共享的派生工具和配置数据。
{ pkgs, selfPackages, username }:

# 需要 rec：mpvRifeWrapped 引用同级的 mpvRife
rec {
  # Python site-packages 相对路径，由 nixpkgs 推导（如 lib/python3.13/site-packages）。
  # 不要硬编码 python3.13 —— 上游升到 3.14 时路径会失效且求值不报错。
  pySite = pkgs.python3.sitePackages;

  # 开发环境变量的唯一数据源；登录 shell 和 systemd user session 共用。
  devEnv = {
    JAVA_HOME = "${pkgs.zulu25}";          # 默认 JDK（HMCL 等多版本可自选）
    CARGO_HOME = "$HOME/.cargo";
    PYTHONPATH = "${pkgs.python3Packages.pygobject3}/${pySite}:${selfPackages.k7sfunc}/${pySite}:${pkgs.python3Packages.vapoursynth}/${pySite}";
    VAPOURSYNTH_EXTRA_PLUGIN_PATH = "${selfPackages.vapoursynth-with-plugins}/lib/vapoursynth";
  };

  # 用户级开发工具目录。
  devBinPath = [ "$HOME/.cargo/bin" "$HOME/.npm-global/bin" ];

  # Minecraft 运行库只注入相关 wrapper，避免污染整个用户 session。
  mcJavaLibPath =
    "${pkgs.pipewire.jack}/lib:${pkgs.stdenv.cc.cc.lib}/lib";

  # Nautilus C 扩展目录。
  nautilusExtensionDir =
    "${selfPackages.nautilus-with-extensions}/lib/nautilus/extensions-4";

  # 包管理器镜像配置；files.nix 负责部署真实文件。
  # npm prefix 使用绝对路径。
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

  # activation 使用的可写种子文件。
  seedKittyTheme     = builtins.toString ./dotfiles/config/kitty/themes/noctalia.conf;
  # activation 会把配置复制为可写文件，因此这里先按 username 替换家目录。
  seedNoctaliaConfig = pkgs.writeText "noctalia-config.toml"
    (builtins.replaceStrings
      [ "/home/cookie" ]
      [ "/home/${username}" ]
      (builtins.readFile ./dotfiles/config/noctalia/config.toml));
  seedStarship       = builtins.toString ./dotfiles/config/starship.toml;
  seedMangoHud       = builtins.toString ./dotfiles/config/MangoHud/MangoHud.conf;
  seedWallpaperVideo = builtins.toString ./dotfiles/Pictures/Wallpapers/video/hatsune-miku.mp4;

  # Lunar Client 强制使用原生 Wayland。
  lunarclientWayland = pkgs.symlinkJoin {
    name = "lunar-client-wayland";
    paths = [ pkgs.lunar-client ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      rm -f $out/bin/lunarclient
      makeWrapper ${pkgs.lunar-client}/bin/lunarclient $out/bin/lunarclient \
        --set SDL_VIDEO_DRIVER wayland \
        --prefix LD_LIBRARY_PATH : "${mcJavaLibPath}"
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
