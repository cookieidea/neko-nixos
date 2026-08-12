# AB Download Manager —— 跨平台下载管理器（Kotlin/Compose Desktop）
#
# amir1376/ab-download-manager（nixpkgs 无此包，AUR: abdownloadmanager-bin）
# GitHub Releases 的 jpackage 打包（bin 启动脚本 + 捆绑 JBR 运行时 + 原生库）：
#   - 解压保持目录结构，用 makeWrapper 包装 bin/ABDownloadManager
#   - autoPatchelfHook 处理 libapplauncher.so / libskiko 原生库
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

    # 启动器
    makeWrapper "$out/lib/abdm/bin/ABDownloadManager" "$out/bin/abdownloadmanager"

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
