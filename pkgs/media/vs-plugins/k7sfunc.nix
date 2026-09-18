{ lib, buildPythonPackage, fetchPypi, vapoursynth, setuptools }:

buildPythonPackage rec {
  pname = "k7sfunc";
  version = "1.8.1";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-yvLPniEQqcrq3F6BMf/gWlo3qEfVEsxeg7qwccl+6Hc=";
  };

  build-system = [ setuptools ];

  propagatedBuildInputs = [ vapoursynth ];

  doCheck = false;

  postPatch = ''
    # k7sfunc 1.8.1：RIFE_STD 在设置 skip 前读取它，导致 UnboundLocalError。
    substituteInPlace k7sfunc/mod_memc.py \
      --replace-fail $'\t_check_plugin(func_name, "rife")\n\tif skip :' $'\t_check_plugin(func_name, "rife")\n\tskip = turbo == 2\n\tif skip :'
  '';

  meta = with lib; {
    description = "VapourSynth video processing functions optimized for media players";
    homepage = "https://github.com/hooke007/K7sfunc";
    license = licenses.mit;
  };
}
