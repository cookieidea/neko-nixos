# 带扩展的 nautilus（symlinkJoin 把 C 扩展 .so 合进 nautilus 的 extensions-4 目录）
{ pkgs }:
let
  imgconv = import ./image-converter.nix { inherit pkgs; };
in
pkgs.symlinkJoin {
  name = "nautilus-with-extensions";
  paths = [ pkgs.nautilus ];
  postBuild = ''
    mkdir -p "$out/lib/nautilus/extensions-4"
    # image-converter（C 扩展）
    ln -s "${imgconv}/lib/nautilus/extensions-4/libnautilus-image-converter.so" \
      "$out/lib/nautilus/extensions-4/"
    # nautilus-python（Python 扩展加载器，扫描 ~/.local/share/nautilus-python/extensions）
    ln -s "${pkgs.nautilus-python}/lib/nautilus/extensions-4/libnautilus-python.so" \
      "$out/lib/nautilus/extensions-4/"
  '';
}
