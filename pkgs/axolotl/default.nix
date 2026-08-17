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
    #
    # ⚠️ 不 exec AppRun（AppImage 自带 hook 强制 GDK_BACKEND=x11，见
    #    linuxdeploy-plugin-gtk.sh：tauri#8541 时代的旧 workaround）。
    #    X11→XWayland 下 WebKitGTK EGL DRI2 失败（EGL_BAD_PARAMETER）：
    #    WebKitWebProcess 崩溃/空转 → 微软登录页卡死。
    #    改为直接 exec AppRun.wrapped（保留其 LD_LIBRARY_PATH 注入），
    #    自行提供等效 GTK/GStreamer 环境并强制 Wayland。
    runScript = pkgs.writeShellScript "axolotl-run" ''
      # 不 exec AppRun/AppRun.wrapped（linuxdeploy 会向 LD_LIBRARY_PATH 注入
      # AppImage 捆绑的旧 libwayland/libwebkit(2.48)/libavif 等——与 rootfs 新库
      # 混用导致符号不匹配：WebKit EGL_BAD_PARAMETER 崩溃、联机页 UIProcess
      # SIGSEGV、libavif 缺 SharpYuvOptionsInitInternal）。
      # 直接 exec 启动器二进制：LD_LIBRARY_PATH 全走 rootfs，库栈完全一致。
      #
      # Tauri 自更新：nix store 只读 → 更新器替换可执行文件失败（EROFS）。
      # 首次运行时把解包目录复制到 ~/.local/share/red.ghs.axolotl-app（可写），
      # 之后从副本运行；自更新会就地替换副本文件。nix 包版本变化（marker
      # 路径不同）时重新复制，以 nix 包为准。
      export LD_LIBRARY_PATH=/usr/lib64:/usr/lib:/usr/lib/x86_64-linux-gnu''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
      export WEBKIT_EXEC_PATH=/usr/libexec/webkit2gtk-4.1
      # GIO 模块：FHS 里 glib-networking 的 TLS/代理模块在 /usr/lib64/gio/modules，
      # GIO 默认只扫编译内建路径（nix store）找不到 → HTTPS 全失败 → 远程图片全破。
      export GIO_EXTRA_MODULES=/usr/lib64/gio/modules
      # WebKit 渲染降级：禁用 GPU 合成/DMABUF——RX 6600 + radeonsi 下 WebKit 的
      # DMABUF/合成路径会崩（堆损坏 SIGABRT），图片渲染不出来。强制软件合成。
      export WEBKIT_DISABLE_COMPOSITING_MODE=1
      export WEBKIT_DISABLE_DMABUF_RENDERER=1
      APP_DIR="$HOME/.local/share/red.ghs.axolotl-app"
      MARKER="$APP_DIR/.nix-source"
      if [ "$(cat "$MARKER" 2>/dev/null)" != "${extracted}" ]; then
        # nix store 文件全是只读位，cp -a 后副本仍只读 → 删除/更新/标记都写不进
        chmod -R u+w "$APP_DIR" 2>/dev/null || true
        rm -rf "$APP_DIR"
        mkdir -p "$APP_DIR"
        cp -a "${extracted}"/. "$APP_DIR"/
        chmod -R u+w "$APP_DIR"
        echo "${extracted}" > "$MARKER"
      fi
      # Tauri 自更新会把 usr/bin/axolotl-launcher 替换成完整 AppImage
      # （更新器按 AppImage 包处理：替换当前可执行文件）——FHS 无 FUSE 跑不了。
      # 检测 AppImage 魔数（offset 8 = "AI"）后 --appimage-extract 并合并回副本。
      LAUNCHER="$APP_DIR/usr/bin/axolotl-launcher"
      if [ "$(dd if="$LAUNCHER" bs=1 skip=8 count=2 2>/dev/null)" = "AI" ]; then
        EXTRACT_DIR="$APP_DIR/.extract-$$"
        mkdir -p "$EXTRACT_DIR"
        ( cd "$EXTRACT_DIR" && "$LAUNCHER" --appimage-extract >/dev/null 2>&1 )
        if [ -d "$EXTRACT_DIR/squashfs-root" ]; then
          cp -a "$EXTRACT_DIR/squashfs-root"/. "$APP_DIR"/
        fi
        rm -rf "$EXTRACT_DIR"
        chmod -R u+w "$APP_DIR"
      fi
      exec "$APP_DIR/usr/bin/axolotl-launcher" "$@"
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
      # HTTPS/TLS 后端（WebKit/GIO 加载远程图片必需）：
      # glib-networking 提供 GIO 的 TLS 传输插件（gnutls），缺了所有 https 图片加载失败；
      # cacert 提供 CA 证书（/etc/ssl/certs）。
      pkgs.glib-networking
      pkgs.cacert
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
      pkgs.mesa            # EGL/GLX 渲染驱动（libEGL_mesa/libGLX_mesa）+ radeonsi
      # 音频（MC 的 OpenAL 需要 dlopen 后端库，缺失则无声）
      pkgs.pipewire        # libpipewire-0.3（OpenAL PipeWire 后端）
      pkgs.libpulseaudio   # libpulse（OpenAL PulseAudio 后端兜底）
      pkgs.alsa-lib        # libasound（OpenAL ALSA 后端兜底）
      pkgs.dbus
      pkgs.glib
      pkgs.gsettings-desktop-schemas
      pkgs.xkeyboard-config          # /usr/share/X11/xkb（Wayland xkbcommon 必需，缺失则 gtk_init 崩溃）
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
    license = licenses.gpl3Only;   # Axolotl 桌面包 GPL-3.0-only（开源）
    mainProgram = "axolotl";
    platforms = platforms.linux;
  };
}
