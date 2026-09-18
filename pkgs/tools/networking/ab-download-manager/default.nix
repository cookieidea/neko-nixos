# AB Download Manager（Kotlin/Compose，jpackage 打包）
# 踩坑：1) "Fontconfig head is null" → runtime/lib 里放 libfontconfig 符号链接
#       2) 托盘 libLinuxTray.so 需 libsystemd.so.0 → LD_LIBRARY_PATH 注入
#       3) wrapper 须放原始路径 bin/ABDownloadManager，否则应用重写的 autostart 绕过 wrapper
{ pkgs }:

let
  version = "1.10.2";
in
pkgs.stdenv.mkDerivation {
  pname = "ab-download-manager";
  inherit version;

  src = pkgs.fetchurl {
    url = "https://github.com/amir1376/ab-download-manager/releases/download/v${version}/ABDownloadManager_${version}_linux_x64.tar.gz";
    sha256 = "sha256-xhwDnsQm3wC188/P0Htk7GKgw1x4vsvFYtRgDVpeqcQ=";
  };

  nativeBuildInputs = [ pkgs.autoPatchelfHook pkgs.makeWrapper ];

  buildInputs = with pkgs; [
    libX11 libXext libXi libXrender libXtst
    fontconfig freetype
    libxkbcommon
    wayland
    alsa-lib
    libGL
    zlib
    stdenv.cc.cc.lib
  ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/abdm $out/bin $out/share/applications $out/share/pixmaps
    # stdenv 解压后 cwd 已在 ABDownloadManager/ 内（sourceRoot）
    cp -r . "$out/lib/abdm/"
    chmod -R u+w "$out/lib/abdm/"
    chmod +x "$out/lib/abdm/bin/ABDownloadManager"

    # 字体修复（见文件头 1）
    ln -s "${pkgs.fontconfig.lib}/lib/libfontconfig.so.1" \
      "$out/lib/abdm/lib/runtime/lib/libfontconfig.so.1"

    # 托盘修复（见文件头 2/3）：真二进制移 .bin，wrapper 占原始路径覆盖所有入口
    mv "$out/lib/abdm/bin/ABDownloadManager" "$out/lib/abdm/bin/ABDownloadManager.bin"
    # jpackage 启动器按 <launcher 名>.cfg 找配置，改名后需配套 cfg
    cp "$out/lib/abdm/lib/app/ABDownloadManager.cfg" \
      "$out/lib/abdm/lib/app/ABDownloadManager.bin.cfg"
    makeWrapper "$out/lib/abdm/bin/ABDownloadManager.bin" "$out/lib/abdm/bin/ABDownloadManager" \
      --prefix LD_LIBRARY_PATH : "${pkgs.systemdLibs}/lib"
    ln -s "$out/lib/abdm/bin/ABDownloadManager" "$out/bin/abdownloadmanager"

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