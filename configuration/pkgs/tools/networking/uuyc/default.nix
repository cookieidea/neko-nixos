# 网易 UU 远程（官方 deb，Qt5 + 自带大部分运行库）。
# 上游只提供“最新版”签名下载接口，没有按版本固定的 URL，hash 随发版变化；
# 升级时改 version 并让 hash 报错后抄回即可。
{ pkgs }:

let
  version = "4.48.4.59255-1";

  src =
    pkgs.runCommandLocal "nrd-uuyc_${version}_amd64.deb"
      {
        outputHash = "sha256-70k/8v4ZSuA8BF0mdIacUnfCuEbv2ynpOgInDNZTrwY=";
        outputHashMode = "flat";
        nativeBuildInputs = [
          pkgs.curl
          pkgs.cacert
        ];
      }
      ''
        curl -fsSL --retry 3 --connect-timeout 15 --max-time 600 \
          -o "$out" 'https://api.nrd.nie.163.com/api/v1/release/dl/8?channel=gwqd'
      '';

  runtimeLibs = with pkgs; [
    # 系统库（deb 里没有自带）。
    stdenv.cc.cc.lib
    glib
    dbus
    libGL
    libdrm
    libgbm
    vulkan-loader
    libpulseaudio
    pipewire
    cairo
    freetype
    fontconfig
    libxkbcommon
    xorg.libX11
    xorg.libXext
    xorg.libXrandr
    xorg.libXfixes
    xorg.libXi
    xorg.libXrender
    xorg.libXres
    libxcb
    xcbutil
    xcbutilimage
    xcbutilkeysyms
    xcbutilrenderutil
    xcbutilwm
    systemdLibs
    zstd
    # webview 运行时 dlopen（不在 NEEDED 里）。
    webkitgtk_4_1
  ];

  # 程序会 readlink /proc/self/exe 反推安装目录并在其下建 config/、写日志，
  # 所以必须从可写的 /opt/uuyc 启动（由模块的 uuyc-prefix 服务铺好）。
  launcher = pkgs.writeShellScript "uuyc" ''
    export LD_LIBRARY_PATH="/opt/uuyc/lib:${
      pkgs.lib.makeLibraryPath [ pkgs.webkitgtk_4_1 ]
    }''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    export QT_PLUGIN_PATH=/opt/uuyc/plugins
    # 包里只有 xcb 平台插件，niri 下走 xwayland-satellite。
    export QT_QPA_PLATFORM=xcb
    export QT_QPA_PLATFORMTHEME="''${QT_QPA_PLATFORMTHEME:-xdgdesktopportal}"
    export PIPEWIRE_MODULE_DIR=/opt/uuyc/lib/pipewire-0.3
    export PIPEWIRE_CONFIG_PREFIX=/opt/uuyc/share/pipewire
    export SPA_PLUGIN_DIR=/opt/uuyc/lib/spa-0.2
    export NRD_LOG_ROOT=/opt/uuyc/log
    export SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt
    export SSL_CERT_DIR=/etc/ssl/certs
    export CURL_CA_BUNDLE=/etc/ssl/certs/ca-bundle.crt
    if { [ -z "''${QT_IM_MODULE:-}" ] || [ "''${QT_IM_MODULE}" = xim ]; } \
       && command -v pgrep >/dev/null 2>&1 \
       && pgrep -u "$(id -u)" -x ibus-daemon >/dev/null 2>&1; then
      export QT_IM_MODULE=ibus
    fi
    cd /opt/uuyc/bin || exit 1
    exec ./uuyc "$@"
  '';

  cliLauncher = pkgs.writeShellScript "uuyc-cli" ''
    export LD_LIBRARY_PATH="/opt/uuyc/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    cd /opt/uuyc/bin || exit 1
    exec ./uuyc-cli "$@"
  '';
in
pkgs.stdenv.mkDerivation {
  pname = "uuyc";
  inherit version src;

  nativeBuildInputs = [
    pkgs.autoPatchelfHook
    pkgs.dpkg
  ];

  buildInputs = runtimeLibs;

  # 二进制在 opt/uuyc/bin、opt/uuyc/lib、opt/uuyc/lib/pipewire-0.3 等，
  # 统一补上相对 RPATH；bundle 内的库不再从系统找。
  appendRunpaths = [
    "$ORIGIN"
    "$ORIGIN/.."
    "$ORIGIN/../lib"
    "$ORIGIN/../../lib"
  ];

  unpackPhase = ''
    runHook preUnpack
    # fusermount3 带 setuid，store 里既不能保留也用不上。
    dpkg-deb --fsys-tarfile $src | tar -xf - --no-same-owner --no-same-permissions
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp -a opt usr $out/

    # 桌面项和图标放到 profile 标准路径，否则启动器看不到。
    mkdir -p $out/share/applications
    cp -a $out/usr/share/icons $out/share/
    cp -a $out/usr/share/applications/uuyc.desktop $out/share/applications/
    substituteInPlace $out/share/applications/uuyc.desktop \
      --replace-fail 'Exec=/usr/lib/uuyc/uuyc-gui-session-start %u' 'Exec=uuyc %u' \
      --replace-fail 'TryExec=/usr/lib/uuyc/uuyc-gui-session-start' 'TryExec=uuyc' \
      --replace-fail 'Icon=/usr/share/icons/hicolor/256x256/apps/uuyc.ico' \
        "Icon=$out/share/icons/hicolor/256x256/apps/uuyc.ico"

    # 用户级 GUI unit 放进 profile，user manager 会在
    # /run/current-system/sw/share/systemd/user 下找到它（供程序内部重启）。
    mkdir -p $out/share/systemd/user
    cp $out/usr/lib/systemd/user/uuyc-gui.service $out/share/systemd/user/
    mkdir -p $out/share/systemd/user/uuyc-gui.service.d
    cat > $out/share/systemd/user/uuyc-gui.service.d/10-nixos.conf <<EOF
    [Service]
    Environment=QT_QPA_PLATFORM=xcb
    Environment=NRD_LOG_ROOT=/opt/uuyc/log
    Environment=SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt
    Environment=SSL_CERT_DIR=/etc/ssl/certs
    Environment=CURL_CA_BUNDLE=/etc/ssl/certs/ca-bundle.crt
    EOF

    install -m755 ${launcher} $out/bin/uuyc
    install -m755 ${cliLauncher} $out/bin/uuyc-cli

    runHook postInstall
  '';

  meta = {
    description = "NetEase UU Remote client (uuyc)";
    homepage = "https://uuyc.163.com/";
    license = pkgs.lib.licenses.unfree;
    sourceProvenance = with pkgs.lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "uuyc";
  };
}
