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

  meta = with lib; {
    description = "VapourSynth video processing functions optimized for media players";
    homepage = "https://github.com/hooke007/K7sfunc";
    license = licenses.mit;
  };
}
