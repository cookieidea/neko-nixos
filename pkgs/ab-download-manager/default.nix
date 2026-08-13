# AB Download Manager —— 跨平台下载管理器（Kotlin/Compose Desktop）
#
# amir1376/ab-download-manager（nixpkgs 无此包，AUR: abdownloadmanager-bin）
# GitHub Releases 的 jpackage 打包（bin 启动脚本 + 捆绑 JBR 运行时 + 原生库）：
#   - 解压保持目录结构，bin/abdownloadmanager 直接链接到捆绑启动器
#   - autoPatchelfHook 处理 libapplauncher.so / libskiko 原生库
#
# ⚠️ 字体崩溃根因与修复（2026-08，已实测）：
# 捆绑 JBR（JDK 25）的 sun.awt 在启动时 dlopen("libfontconfig.so.1") 加载
# native fontconfig；NixOS 没有 ld.so.cache 且该库不在任何标准搜索路径 →
# dlopen 失败 → 回退 Java 侧解析器 → "Fontconfig head is null" 崩溃。
# LD_DEBUG 证实 JVM 的 dlopen 搜索路径（来自 libnio.so 的 RUNPATH）包含
#   $java.home/lib 与 $java.home/lib/server
# → 在 runtime/lib 放入 libfontconfig.so.1 的符号链接即可命中，无需任何
#   环境变量。此修复覆盖所有入口：桌面启动、应用内"开机自启"（ABDM 自己
#   写 ~/.config/autostart 指向 bin/ABDownloadManager 原始路径）、浏览器集成。
# 之前尝试的 -Dsun.awt.fontconfig 指向自定义 XML 的方案对 JDK 25 无效
# （XML 被按 Java properties 解析 → getInitELC NPE 崩溃），已移除。
{ pkgs }:

let
  version = "1.10.1";
in
pkgs.stdenv.mkDerivation {
  pname = "ab-download-manager";
  inherit version;

  src = pkgs.fetchurl {
    url = "https://github.com/amir1376/ab-download-manager/releases/download/v${version}/ABDownloadManager_${version}_linux_x64.tar.gz";
    sha256 = "daae532dfc07231dae02fce371a66b50e6c1ef4ca94a705bb3b5f2b996825ee7";
  };

  nativeBuildInputs = [ pkgs.autoPatchelfHook ];

  # skiko（Compose）与捆绑 JBR 运行时的原生库依赖
  buildInputs = with pkgs; [
    libX11 libXext libXi libXrender libXtst
    fontconfig freetype
    libxkbcommon
    wayland
    alsa-lib
    libGL                       # skiko（Compose）OpenGL 渲染
    zlib
    stdenv.cc.cc.lib            # libstdc++
  ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/abdm $out/bin $out/share/applications $out/share/pixmaps
    # stdenv 解压后 cwd 已在 ABDownloadManager/ 内（sourceRoot），直接 cp 当前目录
    cp -r . "$out/lib/abdm/"
    # jpackage 产物是只读打包，放开写权限（tar.gz 解压源）
    chmod -R u+w "$out/lib/abdm/"
    chmod +x "$out/lib/abdm/bin/ABDownloadManager"

    # 字体修复：JVM 的 dlopen("libfontconfig.so.1") 搜索路径含 runtime/lib，
    # 放入符号链接即可命中（见文件头注释）
    ln -s "${pkgs.fontconfig.lib}/lib/libfontconfig.so.1" \
      "$out/lib/abdm/lib/runtime/lib/libfontconfig.so.1"

    # 启动器（无环境变量需求；字体修复在 runtime/lib 层完成）
    ln -s "$out/lib/abdm/bin/ABDownloadManager" "$out/bin/abdownloadmanager"

    # 图标 + desktop 文件（noctalia launcher / 应用列表可见）
    cp "$out/lib/abdm/lib/ABDownloadManager.png" "$out/share/pixmaps/abdownloadmanager.png"
    cat > $out/share/applications/abdownloadmanager.desktop <<EOF
    [Desktop Entry]
    Type=Application
    Name=AB Download Manager
    Comment=Multi-connection download manager
    Exec=$out/bin/abdownloadmanager
    Icon=abdownloadmanager
    Terminal=false
    Categories=Network;FileTransfer;
    EOF
    runHook postInstall
  '';

  meta = {
    description = "AB Download Manager - multi-connection download manager (Compose Desktop)";
    homepage = "https://github.com/amir1376/ab-download-manager";
    license = pkgs.lib.licenses.agpl3Only;
    mainProgram = "abdownloadmanager";
  };
}