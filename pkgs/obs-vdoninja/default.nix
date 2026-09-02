# VDO.Ninja OBS 插件（OBS 直推/收流低延迟 WebRTC）
# nixpkgs 无此包；官方预编译 .so 为 libobs.so.30（与 OBS 32 兼容）。
# ⚠️ 不能裸拷（home.file）——预编译 .so 的 RPATH 指向
# 构建机路径，NixOS 上依赖全找不到（实测 ldd 全 not found）。
# 正确姿势：autoPatchelfHook 把依赖修到 nix store 路径。
#
# 依赖（.so soname 匹配）：
#   libobs.so.30 / libobs-frontend-api.so.30  ← pkgs.obs-studio（OBS 32 soname=30）
#   libdatachannel.so.0.20                    ← override 到 v0.20.2（nixpkgs 26.05 版本 soname 不匹配）
#   libavcodec.so.60 等（ffmpeg 6）            ← pkgs.ffmpeg_6
#   libQt6Widgets/Gui/Core.so.6               ← pkgs.qt6Packages.qtbase
#   libcrypto.so.3                            ← pkgs.openssl
#   libstdc++.so.6                            ← stdenv.cc.cc.lib
{ pkgs }:

let
  # VDO.Ninja v1.1.65 编译时链接 libdatachannel 0.20.x（soname .so.0.20），
  # nixpkgs 26.05 的 libdatachannel 版本 soname 不匹配（autoPatchelf not found）。
  # override 到 v0.20.2：fetchGit 免 hash（构建时由 Nix 拉取），保留 nixpkgs 定义的
  # buildInputs/cmakeFlags（libsrtp/usrsctp 等），只换版本与源码。
  libdatachannel-020 = pkgs.libdatachannel.overrideAttrs (old: {
    version = "0.20.2";
    src = builtins.fetchGit {
      url = "https://github.com/paullouisageneau/libdatachannel";
      rev = "0b1074a9effeb8d9d3f4eca704d3fe3d2f9bc7e5";  # v0.20.2
    };
  });
in

pkgs.stdenv.mkDerivation {
  pname = "obs-vdoninja";
  # v1.1.63：libobs 32.1 时代编译（导出 obs_module_ver 旧协议，无 libobs_api_ver），
  # 与 26.05 的 obs-studio 32.1.2 兼容。
  # ⚠️ 不要升 v1.1.65+：libobs 32.2 编译（OBS 32.1.2 报 "compiled with newer libobs 32.2"）；
  # 升级 OBS 到 32.2 需 unstable nixpkgs，依赖闭包 3.8GB 超出 VM 磁盘（实测 No space）。
  version = "1.1.63";

  src = pkgs.fetchurl {
    url = "https://github.com/steveseguin/ninja-obs-plugin/releases/download/v1.1.63/obs-vdoninja-linux-x86_64.tar.gz";
    sha256 = "sha256-GPYPmgcaUpXujiryQMKuYLcumx8QPcATSlTov/a1Kbk=";
  };

  nativeBuildInputs = [ pkgs.autoPatchelfHook ];

  # tar 平铺结构（lib/ share/ 直接在最外层，无单一根目录）
  sourceRoot = ".";

  # 插件是 .so 库不是应用：qtbase 仅作链接依赖，不需要 Qt wrap
  dontWrapQtApps = true;

  buildInputs = [
    pkgs.obs-studio          # libobs.so.30 / libobs-frontend-api.so.30
    libdatachannel-020       # libdatachannel.so.0.20（override v0.20.2）
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
