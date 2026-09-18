{ lib, stdenv, makeWrapper, vapoursynth, python3, python3Packages
, vapoursynth-lsmash, vapoursynth-akarin, vapoursynth-rife-ncnn, vapoursynth-mvtools
, k7sfunc }:

stdenv.mkDerivation {
  pname = "vapoursynth-with-plugins";
  version = vapoursynth.version;

  dontUnpack = true;
  dontBuild = true;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/lib/vapoursynth"
    for p in ${vapoursynth-lsmash} ${vapoursynth-akarin} ${vapoursynth-rife-ncnn} ${vapoursynth-mvtools}; do
      ln -s "$p/lib/vapoursynth"/* "$out/lib/vapoursynth/" 2>/dev/null || true
    done
    makeWrapper ${vapoursynth}/bin/vspipe "$out/bin/vspipe" \
      --prefix VAPOURSYNTH_EXTRA_PLUGIN_PATH : "$out/lib/vapoursynth" \
      --prefix PYTHONPATH : "${k7sfunc}/${python3.sitePackages}:${python3Packages.vapoursynth}/${python3.sitePackages}"
    runHook postInstall
  '';

  meta = with lib; {
    description = "vspipe wrapper: VapourSynth + k7sfunc + RIFE/lsmash/akarin/mvtools";
    platforms = platforms.linux;
  };
}
