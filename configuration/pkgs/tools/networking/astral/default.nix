# Astral 组网客户端（Flutter GUI + Rust/EasyTier 核心）
#
# 直接取上游发布的 Linux x64 产物（GitHub Release），而非本机构建：
# 上游是 Flutter + Rust，构建需联网（dart pub get / cargokit 调 cargo），
# 无法在 Nix 沙箱内完成。此前用 path 输入指向 ~/.cache/astral/bundle，
# 导致 flake 依赖本机 home 目录状态（换机 / 清理 cache / 换用户名即失效）。
#
# 升级：改 version + 重新生成 hash（nix store prefetch-file <url>）
{ pkgs, lib, fetchurl }:

let
  version = "1.0.12";
in
pkgs.stdenv.mkDerivation {
  pname = "astral";
  inherit version;

  src = fetchurl {
    url = "https://github.com/AstralNext/Astral/releases/download/v${version}/astral-${version}-linux-x64.tar.gz";
    hash = "sha256-nsPAZovdBcvUQ/uI/7ez6F4xbqZA4OS+tdsLJGsfCNw=";
  };

  # 上游 tarball 是扁平结构（astral / astral-core / data/ / lib/），
  # 解包后即为 bundle 根目录，无需 stripComponents。
  sourceRoot = ".";

  nativeBuildInputs = [
    pkgs.autoPatchelfHook
    pkgs.makeWrapper
    pkgs.wrapGAppsHook3
    # 仅用于让 autoPatchelf 找到 libjvm.so（见下方 postPatch），
    # 不进入运行时闭包（jdk 由 rpath 指向，wrapGAppsHook 不会拉入）
    pkgs.jdk
  ];




  buildInputs = with pkgs; [
    gtk3
    glib
    gdk-pixbuf
    pango
    cairo
    at-spi2-core
    libayatana-appindicator
    libdbusmenu-gtk3
    libxkbcommon
    wayland
    libepoxy
    fontconfig
    freetype
    harfbuzz
    graphite2
    sqlite
    libpng
    libjpeg
    zlib
    bzip2
    xz
    brotli
    expat
    libffi
    pcre2
    libxml2
    libselinux
    systemd
    util-linux
    dbus
    mesa
    libx11
    libxcb
    libxcursor
    libxext
    libxi
    libxrandr
    libxinerama
    libxdamage
    libxcomposite
    libxfixes
    libxrender
    libxau
    libxdmcp
  ];

  dontWrapGApps = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share/applications $out/share/pixmaps
    # sourceRoot="." 表示当前目录即 bundle 根（astral/astral-core/data/lib），
    # 故直接复制 . 而非 $src（$src 在解包后是只读的 store 目录）
    mkdir -p $out/app
    cp -r . $out/app
    chmod -R u+w $out/app
    chmod +x $out/app/astral

    # 上游 tarball 的 libdartjni.so 依赖 libjvm.so（JNI 桥；上游 CI 构建引入，
    # 本机自建产物没有此依赖）。libjvm.so 在 JDK 的 lib/server/ 下，
    # 而 autoPatchelfHook 只搜索 <pkg>/lib —— 复制进来使其可被解析，
    # 同时让运行时 rpath（$ORIGIN/lib）自然命中。
    # 注意：不同 JDK 发行版布局不同（zulu 在 lib/server/，openjdk 在
    # lib/openjdk/lib/server/），故用 find 定位而非写死路径。
    find ${pkgs.jdk} -name libjvm.so -print -quit | \
      xargs -r -I{} cp {} $out/app/lib/

    cp ${./logo.png} $out/share/pixmaps/astral.png
    cat > $out/share/applications/astral.desktop <<EOF
[Desktop Entry]
Type=Application
Name=Astral
Comment=Astral mesh networking client
Exec=astral
Icon=astral
Terminal=false
Categories=Network;Utility;
EOF

    runHook postInstall
  '';

  postFixup = ''
    # TUN 需 cap_net_admin，装后手动 setcap（见 README）
    makeWrapper $out/app/astral $out/bin/astral \
      --prefix LD_LIBRARY_PATH : "$out/app/lib:${
        lib.makeLibraryPath (with pkgs; [
          jdk
          gtk3 glib gdk-pixbuf pango cairo at-spi2-core
          libayatana-appindicator libdbusmenu-gtk3
          libxkbcommon wayland libepoxy fontconfig freetype
          harfbuzz sqlite libpng libjpeg zlib brotli expat
          mesa libx11 libxcb wayland
        ])
      }" \
      ''${gappsWrapperArgs[@]}
  '';
}
