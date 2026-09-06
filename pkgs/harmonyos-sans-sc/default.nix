{ pkgs }:

# 鸿蒙字体（仅简体中文 SC；华为官方包，其余语种不装）
pkgs.stdenv.mkDerivation {
  pname = "harmonyos-sans-sc";
  version = "1.0";

  src = pkgs.fetchurl {
    url = "https://developer.huawei.com/Enexport/sites/default/images/download/next/HarmonyOS-Sans.rar";
    hash = "sha256-UQJ0+8EugKvmQdew2b1NK7T+wRG3txASI2Sncj/hK9c=";
  };

  nativeBuildInputs = [ pkgs.unar ];

  unpackPhase = ''
    unar $src
  '';

  installPhase = ''
    mkdir -p $out/share/fonts/truetype
    find . -iname '*sanssc*.ttf' -exec cp {} $out/share/fonts/truetype/ \;
    [ -n "$(ls $out/share/fonts/truetype)" ] || (echo "no SC fonts found in archive"; exit 1)
  '';

  meta = with pkgs.lib; {
    description = "HarmonyOS Sans SC (Simplified Chinese)";
    homepage = "https://developer.harmonyos.com/cn/docs/design/des-guides/font-0000001157868583";
    license = licenses.unfree;
    platforms = platforms.all;
  };
}
