{ pkgs, bestclient, selfPackages, hmLib, ... }:

{
  home.packages = with pkgs; [
    hmLib.lunarclientWayland
    bestclient.packages.${pkgs.stdenv.hostPlatform.system}.default

    (pkgs.writeShellScriptBin "hmcl" ''
      export SDL_VIDEO_DRIVER=wayland
      export LD_PRELOAD="${pkgs.stdenv.cc.cc.lib}/lib/libstdc++.so.6''${LD_PRELOAD:+:$LD_PRELOAD}"
      export LD_LIBRARY_PATH="${hmLib.mcJavaLibPath}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
      exec ${pkgs.hmcl}/bin/hmcl "$@"
    '')

    (pkgs.runCommand "hmcl-assets" { } ''
      mkdir -p $out/share
      cp -r ${pkgs.hmcl}/share/applications $out/share/
      cp -r ${pkgs.hmcl}/share/icons $out/share/
    '')

    selfPackages.bedrockboot
    selfPackages.purevox
  ];
}
