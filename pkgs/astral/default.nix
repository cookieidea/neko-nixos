# Astral —— 组网（mesh networking）客户端
#
# 上游: https://github.com/AstralNext/Astral（Flutter GUI + Rust/EasyTier 核心）
#
# 打包方式：上游在 Nix 沙箱内无法联网构建（cargokit 构建 Rust 核心 + dart pub get
# 都需网络），且上游无 release 产物，因此采用「手动联网构建一次 + 本地 bundle 打包」：
#   - bundle 由 scripts/build-astral.sh 生成到 /home/cookie/.cache/astral/bundle
#   - 这里用 builtins.path 把 bundle 拷进 store（内容哈希，改动即失效重建）
#   - 产物不入 git（bundle 75MB），换机器需重新手动构建
#
# 升级：重新跑 scripts/build-astral.sh，nixos-rebuild 会因内容哈希变化自动重建。
{ pkgs, lib, src }:

pkgs.stdenv.mkDerivation {
  pname = "astral";
  version = "1.0.9";

  inherit src;

  nativeBuildInputs = [
    pkgs.autoPatchelfHook
    pkgs.makeWrapper
    pkgs.wrapGAppsHook3
  ];

  # 运行时库：ldd 分析所得（gtk3 + 输入法/托盘 + EasyTier 所需 + X/Wayland）
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
    # ⚠️ TUN 虚拟网卡需要 CAP_NET_ADMIN：Nix 沙箱内无法 setcap（缺 CAP_SETFCAP），
    # 且 GUI 会复制 astral-core 到 ~/.local/share/astral-core/app/ 再运行。
    # 已在安装副本上执行过：
    #   sudo setcap cap_net_admin=ep ~/.local/share/astral-core/app/*/astral-core
    # 升级内核版本后需重跑该命令。
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
