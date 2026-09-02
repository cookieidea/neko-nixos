{ lib, stdenv, fetchFromGitHub, meson, ninja, pkg-config, vapoursynth, llvmPackages_13 }:

stdenv.mkDerivation rec {
  pname = "vapoursynth-akarin";
  version = "unstable-2026-08-31";

  src = fetchFromGitHub {
    owner = "AkarinVS";
    repo = "vapoursynth-plugin";
    rev = "8b7ff6dcc85bc9935789c799e63f1388dfbd1bd4";
    hash = "sha256-azo5iD1gvGaMkIdRV7ZX2KQxEJ61B1j7mrhVdtrfarE=";
  };

  nativeBuildInputs = [ meson ninja pkg-config llvmPackages_13.llvm.dev ];
  buildInputs = [ vapoursynth ];
  # llvm config-tool 需在 PATH（meson dependency('llvm', method='config-tool')）

  meta = with lib; {
    description = "AkarinVS VapourSynth plugin (Expr / akarin namespace)";
    homepage = "https://github.com/AkarinVS/vapoursynth-plugin";
    license = licenses.free;
    platforms = platforms.linux;
  };
}
