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


  # meson 默认装到 vapoursynth 的插件目录（store 只读）→ 改装到自己
  postPatch = ''
    # 用内置 asmjit 后端
    substituteInPlace meson.build --replace-fail "use_asmjit = false" "use_asmjit = true"
    # 装到 $out/lib/vapoursynth
    sed -i "s|install_dir: join_paths.*|install_dir: 'lib/vapoursynth',|" meson.build
  '';

  meta = with lib; {
    description = "AkarinVS VapourSynth plugin (Expr / akarin namespace)";
    homepage = "https://github.com/AkarinVS/vapoursynth-plugin";
    license = licenses.free;
    platforms = platforms.linux;
  };
}
