# PureVox（实时 AI 音频降噪，Python + PySide6 + ONNX，Linux 走 PipeWire）
#
# ⚠️ 打包方式（2026-08 重写）：
# 之前用 appimageTools.wrapType2，但它的 init 脚本硬编码 extracted 路径，
# extraInstallCommands 修改的 AppRun 根本不会被用到（沙箱执行的是
# extracted 里的原版 AppRun）→ LD_LIBRARY_PATH 修复不生效，python 加载
# libpython3.8.so.1.0 失败。
#
# 本方案分三步：
#  1. appimageTools.extract 解包 AppImage
#  2. mkDerivation 处理解包产物：
#     - 覆盖 AppRun：LD_LIBRARY_PATH 用 find 收集所有 lib 目录（python38/lib
#       等内嵌库；宿主缺失库由 buildFHSEnv 的 /usr/lib 提供），
#       QT_QPA_PLATFORM=xcb（内嵌 Qt 缺 libQt6WaylandClient 且宿主 Qt 版本
#       不匹配不能混用 → wayland 平台不可用，xcb 走 XWayland）
#  3. buildFHSEnv 提供 FHS 结构（/lib64/ld-linux 等）+ 全部宿主依赖库
#     （清单 = wrapType2 原自动收集的依赖 + AppImage 实测缺失的 libffi/
#     libopus），ld.so.cache 自动生成，dlopen 直接命中
{ pkgs }:

let
  version = "2026.08.14.1643";
  # 资产文件名里的日期是连字符格式（2026-08-14-1643），tag 是点格式
  # （v2026.08.14.1643）——URL 里两处不能混用，否则 404。
  assetDate = "2026-08-14-1643";

  src = pkgs.fetchurl {
    url = "https://github.com/a2heng/PureVox/releases/download/v${version}/PureVox-Linux-x64-${assetDate}-release.AppImage";
    sha256 = "cbae6a1ec0e5d29db8bd2cf87b0f5ff4cba76c79f08843132ccde83ad96b8892";
  };

  # 源码（补 AppImage 缺失文件用）。上游 pack_appimage.sh 的打包文件列表
  # 漏了 dialog_virtual_mic_linux.py → AppImage 里没有 → 点"虚拟声卡"菜单
  # import 失败（ModuleNotFoundError 被 Qt 吞掉，界面打不开）。从源码补进
  # 解包产物。用 GitHub codeload tarball（稳定 hash，无子模块）。
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
    # srcGit 经 `inherit` 进 derivation 输入（fetchgit 产物是已解包目录）
    inherit srcGit;
    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -a . $out/
      chmod -R u+w $out

      # ── 补 AppImage 缺失的虚拟声卡对话框模块（上游打包脚本漏打包）──
      cp "$srcGit/dialog_virtual_mic_linux.py" "$out/usr/lib/purevox/"

      # ── 覆盖 AppRun ──
      cat > $out/AppRun <<'EOF'
      #!/bin/sh
      HERE="$(dirname "$(readlink -f "$0")")"
      export PYTHONHOME="$HERE/usr/python38"
      LIBS=$(find "$HERE" -type d \( -name lib -o -name lib64 \) 2>/dev/null | tr '\n' ':')
      export LD_LIBRARY_PATH="$LIBS''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
      # 内嵌 Qt 无 libQt6WaylandClient 且宿主 Qt 版本不匹配 → 用 xcb(XWayland)
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
    # 基础
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
    # 图形 / 字体 / GTK 栈（PySide6 及其插件需要）
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
    # X11 / xcb（Qt libqxcb 平台插件）
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
    # Wayland / GL / 输入
    pkgs.wayland
    pkgs.libxkbcommon
    pkgs.libglvnd
    pkgs.pixman
    pkgs.libpciaccess
    pkgs.xkeyboard_config
    # 音频（PipeWire 直用）
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
    # AppImage 未内嵌、NixOS 无全局库路径
    pkgs.libffi                        # python ctypes
    pkgs.libopus                       # opuslib
    pkgs.cups                          # Qt 打印
  ];
  runScript = "${app}/AppRun";
  # 快捷方式：应用列表入口 + 图标（home.packages 安装后自动出现在应用列表）
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
