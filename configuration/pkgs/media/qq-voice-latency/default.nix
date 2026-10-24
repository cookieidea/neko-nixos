# QQ 语音延迟修复的 LD_PRELOAD 库。
{ pkgs }:

pkgs.stdenv.mkDerivation {
  pname = "qq-voice-latency-fix";
  version = "1.0";

  src = ./qq-voice-latency.c;

  buildInputs = [ pkgs.libpulseaudio ];

  unpackPhase = ''
    cp $src qq-voice-latency.c
  '';

  buildPhase = ''
    gcc -shared -fPIC -O2 -o libqq-voice-latency.so qq-voice-latency.c \
      -ldl -I${pkgs.libpulseaudio.dev}/include
  '';

  installPhase = ''
    mkdir -p $out/lib
    cp libqq-voice-latency.so $out/lib/
  '';
}
