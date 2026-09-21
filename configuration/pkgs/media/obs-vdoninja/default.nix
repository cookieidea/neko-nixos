# VDO.Ninja OBS 插件（预编译 .so，构建时用 autoPatchelf 修复依赖）。
# 插件按 .so.0.20 链接，需要固定 libdatachannel 0.20.2。
{ pkgs }:

let
  libdatachannel-020 = pkgs.libdatachannel.overrideAttrs (_old: {
    version = "0.20.2";
    src = builtins.fetchGit {
      url = "https://github.com/paullouisageneau/libdatachannel";
      rev = "0b1074a9effeb8d9d3f4eca704d3fe3d2f9bc7e5";  # v0.20.2
    };
  });
in

pkgs.stdenv.mkDerivation {
  pname = "obs-vdoninja";
  # 保持当前 libdatachannel 版本，直到 OBS ABI 一起升级。
  version = "1.1.63";

  src = pkgs.fetchurl {
    url = "https://github.com/steveseguin/ninja-obs-plugin/releases/download/v1.1.63/obs-vdoninja-linux-x86_64.tar.gz";
    sha256 = "sha256-GPYPmgcaUpXujiryQMKuYLcumx8QPcATSlTov/a1Kbk=";
  };

  nativeBuildInputs = [ pkgs.autoPatchelfHook ];

  # 上游 tarball 为扁平目录。
  sourceRoot = ".";
  dontWrapQtApps = true;

  buildInputs = [
    pkgs.obs-studio
    libdatachannel-020
    pkgs.ffmpeg_6
    pkgs.qt6Packages.qtbase
    pkgs.openssl
    pkgs.stdenv.cc.cc.lib
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
