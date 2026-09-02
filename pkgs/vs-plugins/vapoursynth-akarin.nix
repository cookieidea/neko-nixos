{ lib, stdenv, fetchFromGitHub, meson, ninja, pkg-config, vapoursynth }:

stdenv.mkDerivation rec {
  pname = "vapoursynth-akarin";
  version = "unstable-2026-08-31";

  src = fetchFromGitHub {
    owner = "AkarinVS";
    repo = "vapoursynth-plugin";
    rev = "8b7ff6dcc85bc9935789c799e63f1388dfbd1bd4";
    hash = "sha256-azo5iD1gvGaMkIdRV7ZX2KQxEJ61B1j7mrhVdtrfarE=";
  };

  nativeBuildInputs = [ meson ninja pkg-config ];
  buildInputs = [ vapoursynth ];


  postPatch = ''
    # 用内置 asmjit 后端（此版本硬编码 false；llvm>=10,<16 的依赖在 nixpkgs 已不可用）
    substituteInPlace meson.build --replace-fail "use_asmjit = false" "use_asmjit = true"
  '';

  meta = with lib; {
    description = "AkarinVS VapourSynth plugin (Expr / akarin namespace)";
    homepage = "https://github.com/AkarinVS/vapoursynth-plugin";
    license = licenses.free;
    platforms = platforms.linux;
  };
}
