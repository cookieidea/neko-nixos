{ lib, stdenv, fetchFromGitHub, pkg-config, which, ffmpeg_6, vapoursynth }:

stdenv.mkDerivation rec {
  pname = "vapoursynth-lsmash";
  version = "unstable-2026-08-31";

  src = fetchFromGitHub {
    owner = "VFR-maniac";
    repo = "L-SMASH-Works";
    rev = "198cc7814c93209e23f1c6a20daffd651945ba2b";
    hash = "sha256-eQ2FnUceFPk84QewkNhGfoEoQK3WcapY8f0SFGDOaN0=";
  };

  nativeBuildInputs = [ pkg-config which ];
  buildInputs = [ vapoursynth ffmpeg_6 ];

  hardeningDisable = [ "all" ];

  # 两阶段：根目录编 liblsmash → VapourSynth 插件
  buildPhase = ''
    runHook preBuild
    # 1) lsmash core
    ./configure --prefix=$TMPDIR/lsmash
    make -j$NIX_BUILD_CORES -C lsmash
    make -C lsmash install
    # 2) VapourSynth 插件
    cd VapourSynth
    ./configure --prefix=$out --extra-cflags="-I$TMPDIR/lsmash/include" --extra-ldflags="-L$TMPDIR/lsmash/lib"
    make -j$NIX_BUILD_CORES
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    make install
    runHook postInstall
  '';

  meta = with lib; {
    description = "L-SMASH Works VapourSynth plugin (lsmas)";
    homepage = "https://github.com/VFR-maniac/L-SMASH-Works";
    license = licenses.isc;
    platforms = platforms.linux;
  };
}
