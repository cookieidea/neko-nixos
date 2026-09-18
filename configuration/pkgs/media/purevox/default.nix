# PureVox（实时 AI 音频降噪，Python + PySide6 + ONNX）
{ pkgs }:

let
  version = "2026.08.14.1643";
  assetDate = "2026-08-14-1643";

  src = pkgs.fetchurl {
    url = "https://github.com/a2heng/PureVox/releases/download/v${version}/PureVox-Linux-x64-${assetDate}-release.AppImage";
    sha256 = "cbae6a1ec0e5d29db8bd2cf87b0f5ff4cba76c79f08843132ccde83ad96b8892";
  };

  # 补充上游缺失的模块源码
  srcGit = pkgs.fetchzip {
    url = "https://github.com/cookieidea/purevox/archive/d020117dbe6b1ccc83181df3260af7fcbc8745dd.tar.gz";
    sha256 = "sha256-rUXR7Rm5SQSHBeU9wSYnEbJ2PQhm4LV4l15gHbIwmk8=";
  };

  extracted = pkgs.appimageTools.extract {
    pname = "purevox";
    inherit version src;
  };

  app = pkgs.stdenv.mkDerivation {
    pname = "purevox-app";
    inherit version;
    src = extracted;
    inherit srcGit;
    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -a . $out/
      chmod -R u+w $out

      # 补上游缺失的虚拟声卡模块
      cp "$srcGit/dialog_virtual_mic_linux.py" "$out/usr/lib/purevox/"

      cat > $out/AppRun <<'EOF'
      #!/bin/sh
      HERE="$(dirname "$(readlink -f "$0")")"
      export PYTHONHOME="$HERE/usr/python38"
      LIBS=$(find "$HERE" -type d \( -name lib -o -name lib64 \) 2>/dev/null | tr '\n' ':')
      export LD_LIBRARY_PATH="$LIBS''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
      # Qt 平台插件用 xcb
      export QT_QPA_PLATFORM=xcb
      export PATH="$HERE/usr/python38/bin:$PATH"
      cd "$HERE/usr/lib/purevox" || exit 1
      exec "$HERE/usr/python38/bin/python3" run_pyside6.py "$@"
      EOF
      chmod +x $out/AppRun
      runHook postInstall
    '';
  };
in
pkgs.buildFHSEnv {
  name = "purevox";
  targetPkgs = pkgs: [
    pkgs.glibc
    pkgs.stdenv.cc.cc.lib              # libstdc++
    pkgs.zlib
    pkgs.bzip2
    pkgs.brotli
    pkgs.freetype
    pkgs.openssl
    pkgs.expat
    pkgs.curl
    pkgs.xz
    pkgs.gmp
    pkgs.krb5
    # 图形 / 字体 / GTK
    pkgs.fontconfig
    pkgs.cairo
    pkgs.pango
    pkgs.glib
    pkgs.gdk-pixbuf
    pkgs.at-spi2-core
    pkgs.dbus
    pkgs.dbus-glib
    pkgs.libGLU
    pkgs.freeglut
    pkgs.glew
    pkgs.gsettings-desktop-schemas
    # X11 / xcb
    pkgs.libx11
    pkgs.libxext
    pkgs.libxfixes
    pkgs.libxdamage
    pkgs.libxrender
    pkgs.libxi
    pkgs.libxt
    pkgs.libxmu
    pkgs.libice
    pkgs.libsm
    pkgs.libxxf86vm
    pkgs.libxcb
    pkgs.libxcb-image
    pkgs.libxcb-wm
    pkgs.libxcb-keysyms
    pkgs.libxcb-render-util
    pkgs.libxcb-util
    pkgs.wayland
    pkgs.libxkbcommon
    pkgs.libglvnd
    pkgs.pixman
    pkgs.libpciaccess
    pkgs.xkeyboard_config
    # 音频
    pkgs.alsa-lib
    pkgs.pipewire                     # pw-cli（创建虚拟麦克风 null-sink）
    pkgs.pulseaudio                   # pactl（虚拟麦克风 remap-source/set-default-sink）
    pkgs.flac
    pkgs.speex
    pkgs.SDL2
    pkgs.SDL2_image
    pkgs.SDL2_mixer
    pkgs.SDL2_ttf
    pkgs.vulkan-loader
    pkgs.systemdMinimal
    pkgs.libffi                        # python ctypes
    pkgs.libopus                       # opuslib
    pkgs.cups                          # Qt 打印
  ];
  runScript = "${app}/AppRun";
  extraInstallCommands = ''
    mkdir -p $out/share/applications $out/share/pixmaps
    cp ${app}/purevox.png $out/share/pixmaps/purevox.png
    cat > $out/share/applications/purevox.desktop <<EOF
    [Desktop Entry]
    Type=Application
    Name=PureVox
    Name[zh_CN]=PureVox 降噪
    Comment=实时 AI 音频降噪（降噪/TSE/AEC/EQ）
    Exec=$out/bin/purevox
    Icon=purevox
    Terminal=false
    Categories=AudioVideo;Audio;Utility;
    EOF
  '';
  meta = with pkgs.lib; {
    description = "实时 AI 音频降噪（降噪/TSE/AEC/EQ，本地麦克风或手机远程推流，PipeWire）";
    homepage = "https://github.com/a2heng/PureVox";
    license = licenses.gpl3Only;
    mainProgram = "purevox";
    platforms = platforms.linux;
  };
}
