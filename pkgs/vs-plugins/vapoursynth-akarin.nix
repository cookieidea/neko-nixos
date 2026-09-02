{ lib, stdenv, fetchFromGitHub, meson, ninja, pkg-config, vapoursynth }:

stdenv.mkDerivation rec {
  pname = "vapoursynth-akarin";
  version = "unstable-2026-08-31";

  src = fetchFromGitHub {
    owner = "AkarinVS";
    repo = "vapoursynth-plugin";
    rev = "8b7ff6dcc85bc9935789c799e63f1388dfbd1bd4";
    hash = "sha256-L+DJ+XLU9AQ2NuhDUb+Lcvkcx3Z7NVZF00AIAGo0tT8=";
  };

  nativeBuildInputs = [ meson ninja pkg-config ];
  buildInputs = [ vapoursynth ];

  meta = with lib; {
    description = "AkarinVS VapourSynth plugin (Expr / akarin namespace)";
    homepage = "https://github.com/AkarinVS/vapoursynth-plugin";
    license = licenses.free;
    platforms = platforms.linux;
  };
}
