# VDO.Ninja OBS 插件（steveseguin/ninja-obs-plugin）
# OBS 直推/收流 VDO.Ninja（低延迟 WebRTC），替代浏览器源。
#
# nixpkgs 无此包。官方 release 提供 Linux 预编译 .so（为 libobs.so.30 编译，
# 与 OBS 32 兼容）。⚠️ 不能裸拷（home.file 部署）——预编译 .so 的 RPATH 指向
# 构建机路径，NixOS 上依赖全找不到（实测 ldd 全 not found）。
# 正确姿势：autoPatchelfHook 把依赖修到 nix store 路径。
#
# 依赖（.so soname 匹配）：
#   libobs.so.30 / libobs-frontend-api.so.30  ← pkgs.obs-studio（OBS 32 soname=30）
#   libdatachannel.so.0.20                    ← pkgs.libdatachannel（obs 32 同款）
#   libavcodec.so.60 等（ffmpeg 6）            ← pkgs.ffmpeg_6
#   libQt6Widgets/Gui/Core.so.6               ← pkgs.qt6Packages.qtbase
#   libcrypto.so.3                            ← pkgs.openssl
#   libstdc++.so.6                            ← stdenv.cc.cc.lib
{ pkgs }:

pkgs.stdenv.mkDerivation {
  pname = "obs-vdoninja";
  version = "1.1.65";

  src = pkgs.fetchurl {
    url = "https://github.com/steveseguin/ninja-obs-plugin/releases/download/v1.1.65/obs-vdoninja-linux-x86_64.tar.gz";
    sha256 = "sha256-ohguQy3Djqv234AC/CR2Us1aetIggZfyhac/z4T/wFk=";
  };

  nativeBuildInputs = [ pkgs.autoPatchelfHook ];

  buildInputs = [
    pkgs.obs-studio          # libobs.so.30 / libobs-frontend-api.so.30
    pkgs.libdatachannel      # libdatachannel.so.0.20
    pkgs.ffmpeg_6            # libavcodec.so.60 / libavutil.so.58 / libswscale.so.7 / libswresample.so.4
    pkgs.qt6Packages.qtbase  # libQt6Widgets/Gui/Core.so.6
    pkgs.openssl             # libcrypto.so.3
    pkgs.stdenv.cc.cc.lib    # libstdc++.so.6
  ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/obs-plugins
    cp lib/x86_64-linux-gnu/obs-plugins/obs-vdoninja.so $out/lib/obs-plugins/
    mkdir -p $out/share/obs/obs-plugins/obs-vdoninja/locale
    cp share/obs/obs-plugins/obs-vdoninja/locale/*.ini $out/share/obs/obs-plugins/obs-vdoninja/locale/
    runHook postInstall
  '';

  meta = {
    description = "VDO.Ninja OBS plugin (low-latency WebRTC streaming via OBS, AGPL-3.0)";
    homepage = "https://github.com/steveseguin/ninja-obs-plugin";
    license = pkgs.lib.licenses.agpl3Only;
    platforms = [ "x86_64-linux" ];
  };
}
