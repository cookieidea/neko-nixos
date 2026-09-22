{ pkgs, selfPackages, hmLib, ... }:

{
  home.packages = with pkgs; [
    (pkgs.symlinkJoin {
      name = "nautilus-wrapper";
      paths = [ pkgs.nautilus ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram "$out/bin/nautilus" \
          --set NAUTILUS_4_EXTENSION_DIR "${selfPackages.nautilus-with-extensions}/lib/nautilus/extensions-4" \
          --prefix PATH : "${pkgs.lib.makeBinPath ["
            pkgs.imagemagick
            pkgs.jpegoptim
            pkgs.pngquant
            pkgs.ffmpeg
            pkgs.coreutils
          ]}"
      '';
    })
    nautilus-python
    localsearch
    gvfs
    ffmpegthumbnailer
    file-roller
    webp-pixbuf-loader
    poppler
    jpegoptim
    pngquant
    hmLib.xdgOpenWithGio
  ];
}
