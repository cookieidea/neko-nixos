# 合并扩展并统一运行时环境的 Nautilus。
{ pkgs }:
let
  imgconv = import ./image-converter.nix { inherit pkgs; };
in
pkgs.symlinkJoin {
  name = "nautilus-with-extensions";
  paths = [ pkgs.nautilus ];
  nativeBuildInputs = [ pkgs.makeWrapper ];
  postBuild = ''
    mkdir -p "$out/lib/nautilus/extensions-4"
    # image-converter C 扩展。
    ln -s "${imgconv}/lib/nautilus/extensions-4/libnautilus-image-converter.so" \
      "$out/lib/nautilus/extensions-4/"
    # nautilus-python 扩展加载器。
    ln -s "${pkgs.nautilus-python}/lib/nautilus/extensions-4/libnautilus-python.so" \
      "$out/lib/nautilus/extensions-4/"

    # 成品只保留这一层自定义 wrapper；不再由 Home Manager 再包一层。
    wrapProgram "$out/bin/nautilus" \
      --set NAUTILUS_4_EXTENSION_DIR "$out/lib/nautilus/extensions-4" \
      --prefix GI_TYPELIB_PATH : "${pkgs.nautilus}/lib/girepository-1.0" \
      --prefix PATH : "${pkgs.lib.makeBinPath [
        pkgs.imagemagick
        pkgs.jpegoptim
        pkgs.pngquant
        pkgs.ffmpeg
        pkgs.coreutils
      ]}"
  '';
}
