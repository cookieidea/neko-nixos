# Astral 组网客户端（Flutter GUI + Rust/EasyTier 核心）
# 直接使用上游 Linux x64 Release，避免在 Nix sandbox 内重新构建 Flutter/Rust。
# 升级时修改 version 并重新生成 hash。
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

  # Release tarball 解包后就是 bundle 根目录。
  sourceRoot = ".";

  nativeBuildInputs = [
    pkgs.autoPatchelfHook
    pkgs.makeWrapper
    pkgs.wrapGAppsHook3
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
    # 当前目录就是 bundle 根，直接复制其内容。
    mkdir -p $out/app
    cp -r . $out/app
    chmod -R u+w $out/app
    chmod +x $out/app/astral

    # libdartjni.so 需要 libjvm.so；JDK 布局因发行版而异，所以通过 find 定位。
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
    # TUN 使用 cap_net_admin；安装后需要额外设置权限。
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
