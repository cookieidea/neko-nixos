# BedrockBoot（Avalonia/.NET）。
{ pkgs }:

let
  version = "2.1.10.100";

  src = pkgs.fetchurl {
    url = "https://github.com/Round-Studio/BedrockBoot/releases/download/v${version}/BedrockBoot-x86_64-linux.AppImage";
    sha256 = "0pc40j7bjk2yf7js354pjvqjlbm941ikngc6lv45rkjf3z2pw924";
  };

  extracted = pkgs.appimageTools.extract {
    pname = "bedrockboot";
    inherit version src;
  };

  appRun = pkgs.writeShellScript "bedrockboot-apprun" ''
    export APPDIR=${extracted}
    exec ${extracted}/AppRun "$@"
  '';

  # xdg-open 通过 portal 打开宿主浏览器。
  xdgOpenSupport = pkgs.stdenv.mkDerivation {
    pname = "bedrockboot-xdg-support";
    version = "1";
    buildCommand = ''
      mkdir -p $out/usr/bin
      cat > $out/usr/bin/xdg-open <<'EOF'
      #!/bin/sh
      # 调试日志路径由运行时环境展开。
      echo "xdg-open called: $@" >> "''${XDG_CACHE_HOME:-$HOME/.cache}/bedrockboot-xdg-open.log" 2>/dev/null || true
      # 优先使用现有 session bus 地址，否则根据 XDG_RUNTIME_DIR 推导。
      if [ -z "''${DBUS_SESSION_BUS_ADDRESS:-}" ] && [ -n "''${XDG_RUNTIME_DIR:-}" ]; then
        export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"
      fi
      for arg in "$@"; do
        case "$arg" in
          http://*|https://*) 
            ${pkgs.glib.bin}/bin/gdbus call --session --dest org.freedesktop.portal.Desktop \
              --object-path /org/freedesktop/portal/desktop \
              --method org.freedesktop.portal.OpenURI.OpenURI \
              "bedrockboot" "$arg" "{}" >/dev/null 2>&1
            exit 0
            ;;
        esac
      done
      exec /usr/bin/xdg-open-real "$@" 2>/dev/null || exit 0
      EOF
      chmod +x $out/usr/bin/xdg-open
      cp ${pkgs.xdg-utils}/bin/xdg-open $out/usr/bin/xdg-open-real
    '';
  };

  fhsEnv = pkgs.buildFHSEnv {
    name = "bedrockboot";
    extraBuildCommands = ''
      mkdir -p $out/usr/bin
      cp -a ${xdgOpenSupport}/usr/bin/* $out/usr/bin/
      # 初始化 Wine prefix。
      for b in ${pkgs.wineWow64Packages.stable}/bin/*; do
        ln -sf "$b" $out/usr/bin/$(basename "$b")
      done
      ln -sf ${pkgs.python3}/bin/python3 $out/usr/bin/python3
    '';
    runScript = pkgs.writeShellScript "bedrockboot-run" ''
      export GDK_BACKEND=x11
      # 使用 GDK-Proton 提供的 Wine。
      export GDK_PROTON_DIR="$HOME/.config/RoundStudio/BedrockBoot2/BedrockBoot.Linux/xuserProject/proton/GDK-Proton-xuser"
      export PATH="$GDK_PROTON_DIR/files/bin-wow64:$PATH"
      export WINEDLLPATH="$GDK_PROTON_DIR/files/lib/wine/x86_64-unix''${WINEDLLPATH:+:$WINEDLLPATH}"
      export LD_LIBRARY_PATH="$GDK_PROTON_DIR/files/lib/x86_64-linux-gnu:/usr/lib64:/usr/lib:/usr/lib/x86_64-linux-gnu''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
      # 使用宿主 RADV 和 Wine D3D 栈。
      export WINEDLLOVERRIDES="d3d12=b;d3d12core=b;dxgi=b"
      exec ${appRun} "$@"
    '';

    multiPkgs = pkgs: [
      pkgs.glibc
      pkgs.libunwind      # ntdll.so 依赖
      pkgs.mesa
      pkgs.vulkan-loader
      pkgs.gnutls         # Xbox 登录加密
      pkgs.stdenv.cc.cc.lib
      pkgs.zlib
      pkgs.openssl
      pkgs.icu            # .NET ICU
      # 图形、字体和显示协议依赖。
      pkgs.fontconfig
      pkgs.freetype
      pkgs.libx11
      pkgs.libxext
      pkgs.libxcb
      pkgs.libxkbcommon
      pkgs.wayland
      pkgs.libGL
      pkgs.dbus
      pkgs.glib
      pkgs.gsettings-desktop-schemas
      # Avalonia / X11 依赖。
      pkgs.libICE
      pkgs.libSM
      pkgs.libXt
      pkgs.libXrender
      pkgs.libXrandr
      pkgs.libXcursor
      pkgs.libXi
      pkgs.libXinerama
      pkgs.libXfixes
      pkgs.libXdamage
      pkgs.libXcomposite
      pkgs.libxshmfence
      pkgs.libXpresent
      # 压缩库 + 音频
      pkgs.xz
      pkgs.libpulseaudio
      pkgs.alsa-lib
    ];
  };
in
pkgs.stdenv.mkDerivation {
  pname = "bedrockboot";
  inherit version;
  src = extracted;   # 解包内容（找图标用）

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin $out/share/applications $out/share/pixmaps
    ln -s ${fhsEnv}/bin/bedrockboot $out/bin/bedrockboot

    # 应用图标。
    icon=$(find . -path "*icons*" -name "*.png" 2>/dev/null | head -1)
    [ -n "$icon" ] && cp "$icon" "$out/share/pixmaps/bedrockboot.png" || true

    cat > $out/share/applications/bedrockboot.desktop <<EOF
[Desktop Entry]
Type=Application
Name=BedrockBoot
Name[zh_CN]=BedrockBoot 基岩启动器
Comment=Minecraft Bedrock 版启动器（Avalonia UI；实例/账户/联机/CurseForge）
Exec=bedrockboot
Icon=bedrockboot
Terminal=false
Categories=Game;Utility;
EOF
    runHook postInstall
  '';

  meta = with pkgs.lib; {
    description = "Minecraft Bedrock 版启动器（Avalonia UI；实例/账户/联机/CurseForge）";
    homepage = "https://github.com/Round-Studio/BedrockBoot";
    license = licenses.unfreeRedistributable;
    mainProgram = "bedrockboot";
    platforms = platforms.linux;
  };
}
