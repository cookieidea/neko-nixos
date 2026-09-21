# 合并扩展后的 Nautilus。
{ pkgs }:
let
  imgconv = import ./image-converter.nix { inherit pkgs; };
in
pkgs.symlinkJoin {
  name = "nautilus-with-extensions";
  paths = [ pkgs.nautilus ];
  postBuild = ''
    mkdir -p "$out/lib/nautilus/extensions-4"
    # image-converter C 扩展。
    ln -s "${imgconv}/lib/nautilus/extensions-4/libnautilus-image-converter.so" \
      "$out/lib/nautilus/extensions-4/"
    # nautilus-python 扩展加载器。
    ln -s "${pkgs.nautilus-python}/lib/nautilus/extensions-4/libnautilus-python.so" \
      "$out/lib/nautilus/extensions-4/"
  '';
}
