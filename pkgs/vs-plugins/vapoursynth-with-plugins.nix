{ lib, stdenv, makeWrapper, symlinkJoin, vapoursynth, python3
, vapoursynth-lsmash, vapoursynth-akarin, vapoursynth-rife-ncnn, vapoursynth-mvtools
, k7sfunc }:

let
  pyEnv = python3.withPackages (ps: [ ps.vapoursynth k7sfunc ]);
in
stdenv.mkDerivation {
  pname = "vapoursynth-with-plugins";
  version = vapoursynth.version;

  dontUnpack = true;
  dontBuild = true;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/vapoursynth
    for p in ${vapoursynth-lsmash} ${vapoursynth-akarin} ${vapoursynth-rife-ncnn} ${vapoursynth-mvtools}; do
      ln -s $p/lib/vapoursynth/* $out/lib/vapoursynth/ 2>/dev/null || true
    done
    makeWrapper ${vapoursynth}/bin/vspipe $out/bin/vspipe \
      --set-default VAPOURSYNTH_PLUGIN_PATH $out/lib/vapoursynth \
      --set-default PYTHONPATH ${pyEnv}/${python3.sitePackages}
    runHook postInstall
  '';

  meta = with lib; {
    description = "vspipe wrapper: VapourSynth + k7sfunc + RIFE/lsmash/akarin/mvtools";
    platforms = platforms.linux;
  };
}
