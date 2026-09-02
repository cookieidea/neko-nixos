# BedrockBoot（MC 基岩版启动器，Avalonia/.NET，AppImage）
# 打包：appimageTools.extract + buildFHSEnv（补 FHS）+ mkDerivation 补 desktop/图标
# ⚠️ AppRun 需补设 APPDIR（extract 后原版 runtime 才设）；更新改 version + sha256
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
      export GDK_BACKEND=x11
      # ── GDK-Proton 自带 wine（wine 11.1，Wayland 驱动）替代宿主 wine 11.0 ──
      # 宿主 wine 二进制与 GDK 库版本不匹配（11.0 vs 11.1）→ 游戏初始化崩溃、无窗口。
      # GDK-Proton 的 wine 用 Wayland 后端（无 x11drv），需 WAYLAND_DISPLAY
      # （niri 会话继承）；bin-wow64 无 wineboot/msiexec，宿主 /usr/bin 兜底。
      export GDK_PROTON_DIR="$HOME/.config/RoundStudio/BedrockBoot2/BedrockBoot.Linux/xuserProject/proton/GDK-Proton-xuser"
      export PATH="$GDK_PROTON_DIR/files/bin-wow64:$PATH"
      # unix 库在 files/lib/wine/x86_64-unix（proton 脚本会保留已有 WINEDLLPATH 并追加）
      export WINEDLLPATH="$GDK_PROTON_DIR/files/lib/wine/x86_64-unix''${WINEDLLPATH:+:$WINEDLLPATH}"
      # GDK wine 依赖：files/lib/x86_64-linux-gnu（libunwind.so.8 等）+ 沙箱标准路径
      export LD_LIBRARY_PATH="$GDK_PROTON_DIR/files/lib/x86_64-linux-gnu:/usr/lib64:/usr/lib:/usr/lib/x86_64-linux-gnu''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
      # ⚠️ 不能强制 VK_DRIVER_FILES=lavapipe：该路径只在 FHS 沙箱内存在，
      #    游戏经 umu 在沙箱外运行 → Vulkan 找不到任何 ICD → 白屏。
      #    去掉后走宿主 RADV（/run/opengl-driver/share/vulkan/icd.d/radeon_icd）。
      # 强制 wine 内置 D3D 栈：prefix 里 DXVK(dxgi) 与 wine 内置 vkd3d(d3d12) 混用
      # 会导致 "Could not find Vulkan physical device for DXGI adapter" 白屏
      export WINEDLLOVERRIDES="d3d12=b;d3d12core=b;dxgi=b"
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
      # GDK-Proton wine（11.1）的 ntdll.so 依赖 liblzma.so.5（wine 沙箱缺则
      # "could not load ntdll.so: liblzma.so.5"）；音频走 pulse/alsa（mmdevapi）
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
