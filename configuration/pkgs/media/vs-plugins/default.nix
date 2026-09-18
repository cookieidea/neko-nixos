{ pkgs }:

rec {
  l-smash = pkgs.callPackage ./l-smash.nix {};
  vapoursynth-lsmash = pkgs.callPackage ./vapoursynth-lsmash.nix { inherit l-smash; };
  vapoursynth-akarin = pkgs.callPackage ./vapoursynth-akarin.nix {};
  vapoursynth-rife-ncnn = pkgs.callPackage ./vapoursynth-rife-ncnn.nix {};
  k7sfunc = pkgs.python3Packages.callPackage ./k7sfunc.nix {};
  vapoursynth-with-plugins = pkgs.callPackage ./vapoursynth-with-plugins.nix {
    inherit vapoursynth-lsmash vapoursynth-akarin vapoursynth-rife-ncnn k7sfunc;
  };
}
