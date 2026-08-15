# Axolotl —— Minecraft Java 版启动器（替代 Prism Launcher / HMCL）
#
# Mystic-Stars/Axolotl
# 功能：游戏实例管理、CurseForge/Modrinth 整合包、Mod/数据包/资源包管理、
#       联机（红石/陶瓦）、离线/Mojang 认证（镜像/换源）、Discord 状态等。
# 发布：GitHub Releases，Linux 资产为 AppImage（自包含，前后端分离架构）。
#
# 打包：appimageTools.extract + buildFHSEnv（同 bedrockboot/purevox 方案）。
#   AppImage 自包含运行时，原版 AppRun 直接用；buildFHSEnv 提供宿主库兜底。
#
# ⚠️ 更新：发版频繁（如 v1.8.0），升级改 version + 下方 sha256。
{ pkgs }:

let
  version = "1.8.0";

  src = pkgs.fetchurl {
    url = "https://github.com/Mystic-Stars/Axolotl/releases/download/v${version}/Axolotl.Launcher_${version}_amd64.AppImage";
    sha256 = "a77219f2968384d8a25d3d7b03bc6d9f4995a0582dd0a2d46540d4cc79d8bd47";
  };

  extracted = pkgs.appimageTools.extract {
    pname = "axolotl";
    inherit version src;
  };
  fhsEnv = pkgs.buildFHSEnv {
    name = "axolotl";
    # runScript：注入 LD_LIBRARY_PATH 覆盖 rootfs 全部库目录。
    # buildFHSEnv 的 ld.so.cache 未生成（bwrap 指向宿主空 cache）→
    # 动态链接器找不到 rootfs /usr/lib64 的库 → 链式缺库。
    # LD_LIBRARY_PATH 显式列出，绕过 cache（与 purevox 同思路）。
    runScript = pkgs.writeShellScript "axolotl-run" ''
      export GDK_BACKEND=wayland,x11
      export MESA_LOADER_DRIVER_OVERRIDE=llvmpipe
      export GALLIUM_DRIVER=llvmpipe
      export GDK_RENDERING=image
      export WEBKIT_DISABLE_COMPOSITING_MODE=1
      export WEBKIT_DISABLE_DMABUF_RENDERER=1
      export LD_LIBRARY_PATH=/usr/lib64:/usr/lib:/usr/lib/x86_64-linux-gnu''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
      exec ${extracted}/AppRun "$@"
    '';

    multiPkgs = pkgs: [
      # 基础 C 库
      pkgs.glibc
      pkgs.stdenv.cc.cc.lib
      pkgs.zlib
      pkgs.openssl
      pkgs.icu
      pkgs.fribidi
      pkgs.harfbuzz
      pkgs.expat
      pkgs.gpgme                        # libgpg-error（WebKitGTK 依赖链）
      pkgs.libgcrypt
      pkgs.libgpg-error
      pkgs.e2fsprogs        # libcom_err
      pkgs.gmp              # libgmp
      pkgs.libassuan
      pkgs.libpng
      pkgs.libjpeg
      pkgs.libtiff
      pkgs.libwebp
      pkgs.libxml2
      pkgs.sqlite
      pkgs.nss
      pkgs.nspr
      pkgs.libsoup_3
      # GTK3 / WebKitGTK 栈（axolotl-launcher 依赖）
      pkgs.gtk3
      pkgs.webkitgtk_4_1
      pkgs.cairo
      pkgs.gdk-pixbuf
      pkgs.pango
      pkgs.at-spi2-core
      pkgs.gst_all_1.gstreamer
      pkgs.gst_all_1.gst-plugins-base
      pkgs.gst_all_1.gst-plugins-good
      pkgs.gst_all_1.gst-plugins-bad
      # 图形 / 字体 / X11 / Wayland
      pkgs.fontconfig
      pkgs.freetype
      pkgs.libx11
      pkgs.libxext
      pkgs.libxcb
      pkgs.libxkbcommon
      pkgs.wayland
      pkgs.libGL
      pkgs.mesa            # EGL/GLX 渲染驱动(libEGL_mesa/libGLX_mesa),VM llvmpipe
      pkgs.dbus
      pkgs.glib
      pkgs.gsettings-desktop-schemas
      # X11 运行时库
      pkgs.libICE
      pkgs.libSM
      pkgs.libXrender
      pkgs.libXrandr
      pkgs.libXcursor
      pkgs.libXi
      pkgs.libXfixes
      pkgs.libXdamage
      pkgs.libXcomposite
      pkgs.libxshmfence
      pkgs.libXpresent
      pkgs.libXinerama
      pkgs.libgbm
      pkgs.libdrm
    ];
  };
in
pkgs.stdenv.mkDerivation {
  pname = "axolotl";
  inherit version;
  src = extracted;   # 解包内容（找图标用）

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin $out/share/applications $out/share/pixmaps
    ln -s ${fhsEnv}/bin/axolotl $out/bin/axolotl

    # 图标：从解包产物找（AppImage 内 usr/share/icons 或根目录 .png）
    icon=$(find . -path "*icons*" -name "*.png" 2>/dev/null | head -1)
    [ -n "$icon" ] && cp "$icon" "$out/share/pixmaps/axolotl.png" || true

    cat > $out/share/applications/axolotl.desktop <<EOF
[Desktop Entry]
Type=Application
Name=Axolotl
Name[zh_CN]=Axolotl 启动器
Comment=Minecraft Java 版启动器（Modrinth/CurseForge 整合包、联机、多账户）
Exec=axolotl
Icon=axolotl
Terminal=false
Categories=Game;Utility;
EOF
    runHook postInstall
  '';

  meta = with pkgs.lib; {
    description = "Minecraft Java 版启动器（Modrinth/CurseForge 整合包、联机、多账户）";
    homepage = "https://github.com/Mystic-Stars/Axolotl";
    license = licenses.unfreeRedistributable;
    mainProgram = "axolotl";
    platforms = platforms.linux;
  };
}
