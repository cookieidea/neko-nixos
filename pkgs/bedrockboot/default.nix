# BedrockBoot —— 我的世界基岩版（Minecraft Bedrock）启动器
#
# Round-Studio/BedrockBoot（Avalonia UI / .NET 跨平台）
# 功能：游戏实例管理、微软/Xbox 账户登录、联机（Gravitycone/PaperConnect）、
#       CurseForge 资源、配置同步、主题自定义。
# 发布：GitHub Releases 自动构建，Linux 资产为 AppImage。
#
# 打包：appimageTools.extract 解包 + buildFHSEnv（同 purevox 方案）+ mkDerivation
#   - AppImage 捆绑应用运行时（.NET/ICU 等）自包含。
#   - buildFHSEnv 提供 FHS 结构（/lib64/ld-linux 等）+ 宿主依赖库兜底，
#     ld.so.cache 自动生成，dlopen 直接命中。
#   - buildFHSEnv 产物只有 bin/，无 desktop/图标 → mkDerivation 补
#     $out/share/applications + pixmaps（freedesktop 标准路径，应用列表可见）。
#
# ⚠️ AppRun 修复（2026-08）：extract 后直接跑 AppRun 时 $APPDIR 未设置
#   （原版 AppImage runtime 才设）→ exec "$APPDIR/usr/bin/BedrockBoot"
#   变成 /usr/bin/BedrockBoot → "没有那个文件或目录"。自定义入口脚本
#   补设 APPDIR 再 exec 原 AppRun。
#
# ⚠️ 更新：CI 自动发版（tag 形如 v2.1.10.96），升级改 version + 下方 sha256。
{ pkgs }:

let
  version = "2.1.10.96";

  src = pkgs.fetchurl {
    url = "https://github.com/Round-Studio/BedrockBoot/releases/download/v${version}/BedrockBoot-x86_64-linux.AppImage";
    sha256 = "3729d04efc5531d73e06d2bb23ff053f35e498be999c825ba042474f8a55c525";
  };

  extracted = pkgs.appimageTools.extract {
    pname = "bedrockboot";
    inherit version src;
  };

  appRun = pkgs.writeShellScript "bedrockboot-apprun" ''
    export APPDIR=${extracted}
    exec ${extracted}/AppRun "$@"
  '';

  # Xbox 登录需要打开系统浏览器(xdg-open/gio open)。buildFHSEnv rootfs
  # 无 xdg-open 且无 mime handler → "不支持该操作" → 无法登录。
  # extraBuildCommands 注入:宿主 xdg-open + mimeapps(https→chrome) + chrome desktop。
  # Xbox 登录需要打开系统浏览器。沙箱内 chrome/portal-gio 均不可靠
  # （chrome 沙箱内 ProcessSingleton socket 失败；gio portal 探测失败），
  # 但沙箱可直连宿主 session bus → 注入自定义 xdg-open：直接调
  # org.freedesktop.portal.OpenURI（宿主 xdg-desktop-portal 打开浏览器，
  # 已验证宿主 chrome 正常启动）。
  xdgOpenSupport = pkgs.stdenv.mkDerivation {
    pname = "bedrockboot-xdg-support";
    version = "1";
    buildCommand = ''
      mkdir -p $out/usr/bin
      cat > $out/usr/bin/xdg-open <<'EOF'
      #!/bin/sh
      # 沙箱内 xdg-open:经宿主 xdg-desktop-portal 打开 URL(宿主浏览器)
      echo "xdg-open called: $@" >> /home/cookie/.cache/bedrockboot-xdg-open.log
      export DBUS_SESSION_BUS_ADDRESS="${"unix:path=/run/user/1000/bus"}"
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
      # 保留真实 xdg-open 为 xdg-open-real(用于非 URL 场景)
      cp ${pkgs.xdg-utils}/bin/xdg-open $out/usr/bin/xdg-open-real
    '';
  };

  fhsEnv = pkgs.buildFHSEnv {
    name = "bedrockboot";
    extraBuildCommands = ''
      mkdir -p $out/usr/bin
      cp -a ${xdgOpenSupport}/usr/bin/* $out/usr/bin/
      # Wine/Proton:BedrockBoot 用 wineboot 初始化 Wine prefix 启动基岩版
      # (NeoProton 链路)。宿主 wine-wow64 提供,链接进沙箱 /usr/bin。
      for b in ${pkgs.wineWow64Packages.stable}/bin/*; do
        ln -sf "$b" $out/usr/bin/$(basename "$b")
      done
      # GDK-Proton 是 python3 脚本(shebang env python3),沙箱需 python3
      ln -sf ${pkgs.python3}/bin/python3 $out/usr/bin/python3
    '';
    runScript = pkgs.writeShellScript "bedrockboot-run" ''
      export LIBGL_ALWAYS_SOFTWARE=1
      export GDK_BACKEND=x11
      # GDK-Proton 的 wine 是非 wow64 构建,但库是分离布局(x86_64-unix)。
      # WINEDLLPATH 指向 x86_64-unix 让 wine 找到 ntdll.so(proton 脚本会保留
      # 已有 WINEDLLPATH 并追加)。
      export WINEDLLPATH="$HOME/.config/RoundStudio/BedrockBoot2/BedrockBoot.Linux/xuserProject/proton/GDK-Proton-xuser/files/lib/wine/x86_64-unix${WINEDLLPATH:+:$WINEDLLPATH}"
      export LD_LIBRARY_PATH=/usr/lib64:/usr/lib:/usr/lib/x86_64-linux-gnu''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
      exec ${appRun} "$@"
    '';

    multiPkgs = pkgs: [
      # 基础 C 库
      pkgs.glibc
      pkgs.libunwind      # ntdll.so 依赖
      pkgs.mesa           # lavapipe 驱动(软件 Vulkan)
      pkgs.vulkan-loader  # libvulkan.so.1 loader(wine dlopen 它)
      pkgs.gnutls         # libgnutls(加密支持,Xbox 登录必需)
      pkgs.stdenv.cc.cc.lib            # libstdc++
      pkgs.zlib
      pkgs.openssl
      pkgs.icu                          # .NET ICU
      # 图形 / 字体 / X11 / Wayland（Avalonia 渲染）
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
      # Avalonia/X11 运行时库（实测逐个缺过：libICE/libSM/libXt/libXrender
      # /libXrandr/libXcursor/libXi/libXinerama 等）
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

    # 图标：从解包产物找（AppImage 内 usr/share/icons 或根目录 .png）
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
