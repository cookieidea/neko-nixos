{ lib, stdenv, fetchFromGitHub, pkg-config, which, ffmpeg_4, vapoursynth, l-smash }:

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
  buildInputs = [ vapoursynth ffmpeg_4 l-smash ];

  hardeningDisable = [ "all" ];

  postPatch = ''
    patchShebangs VapourSynth/configure
    export NIX_CFLAGS_COMPILE="$NIX_CFLAGS_COMPILE -Wno-error=implicit-function-declaration"
  '';

  configurePhase = ''
    runHook preConfigure
    cd VapourSynth
    ./configure --prefix=$out
    runHook postConfigure
  '';

  meta = with lib; {
    description = "L-SMASH Works VapourSynth plugin (lsmas)";
    homepage = "https://github.com/VFR-maniac/L-SMASH-Works";
    license = licenses.isc;
    platforms = platforms.linux;
  };
}
