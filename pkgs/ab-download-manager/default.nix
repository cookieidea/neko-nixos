# AB Download Manager（Kotlin/Compose，jpackage 打包）
# 解压保持目录结构，bin/abdownloadmanager 直接链接到捆绑启动器
# 踩坑（已实测）：
# 1) 字体崩溃 "Fontconfig head is null"：JVM dlopen libfontconfig.so.1 搜索路径含
#    runtime/lib → 放符号链接命中（-Dsun.awt.fontconfig XML 方案对 JDK25 无效）
# 2) 托盘消失：ComposeNativeTray 的 libLinuxTray.so NEEDED libsystemd.so.0，
#    NixOS 无 ld.so.cache → makeWrapper 注入 LD_LIBRARY_PATH=systemdLibs
# 3) wrapper 须放原始路径 bin/ABDownloadManager（真二进制改 .bin + 配 .bin.cfg）：
#    否则应用自启重写的 autostart 会绕过 wrapper → 托盘仍消失
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

  nativeBuildInputs = [ pkgs.autoPatchelfHook pkgs.makeWrapper ];

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

    # 启动器：注入 systemd lib 路径，保证 ComposeNativeTray 的 libLinuxTray.so
    # 能解析 libsystemd.so.0（见文件头"系统托盘修复"注释）。
    # ⚠️ 直接在原始路径 bin/ABDownloadManager 上包装（真二进制移到 .bin）：
    # ABDM 应用会自己重写 ~/.config/autostart 指向 /proc/self/exe（原始二进制
    # 路径），若只在 $out/bin/abdownloadmanager 包装，autostart 会绕过它 →
    # 无 LD_LIBRARY_PATH → 托盘消失。原始路径包装则覆盖所有入口。
    mv "$out/lib/abdm/bin/ABDownloadManager" "$out/lib/abdm/bin/ABDownloadManager.bin"
    # jpackage 启动器按 <launcher 名>.cfg 找配置：改名 .bin 后需配套 cfg
    # （原始 cfg 在 ../lib/app/ 下，主启动器经 ../lib/app/ABDownloadManager.cfg 找到）
    cp "$out/lib/abdm/lib/app/ABDownloadManager.cfg" \
      "$out/lib/abdm/lib/app/ABDownloadManager.bin.cfg"
    makeWrapper "$out/lib/abdm/bin/ABDownloadManager.bin" "$out/lib/abdm/bin/ABDownloadManager" \
      --prefix LD_LIBRARY_PATH : "${pkgs.systemdLibs}/lib"
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