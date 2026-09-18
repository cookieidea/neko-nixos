# Astral 组网客户端（Flutter GUI + Rust/EasyTier 核心）
# bundle 由 build.sh 联网构建到 ~/.cache/astral/bundle（flake 输入 astral-bundle）
{ pkgs, lib, src }:

pkgs.stdenv.mkDerivation {
  pname = "astral";
  version = "1.0.12";

  inherit src;

  nativeBuildInputs = [
    pkgs.autoPatchelfHook
    pkgs.makeWrapper
    pkgs.wrapGAppsHook3
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
    cp -r $src $out/app
    chmod -R u+w $out/app
    chmod +x $out/app/astral

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
