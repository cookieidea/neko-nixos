{ lib, stdenv, fetchFromGitHub, nasm }:

stdenv.mkDerivation rec {
  pname = "l-smash";
  version = "unstable-2026-09-03";

  src = fetchFromGitHub {
    owner = "l-smash";
    repo = "l-smash";
    rev = "18a9ed25c7ff79a7f4f4bf850c345c72179b8998";
    hash = "";
  };

  nativeBuildInputs = [ nasm ];

  meta = with lib; {
    description = "L-SMASH MP4 library (core)";
    homepage = "https://github.com/l-smash/l-smash";
    license = licenses.isc;
    platforms = platforms.linux;
  };
}
