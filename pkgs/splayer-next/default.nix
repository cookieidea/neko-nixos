{ pkgs }:

# SPlayer-Next — cross-platform desktop music player (Electron + Vue3 + Rust).
# Upstream: https://github.com/SPlayer-Dev/SPlayer-Next
#
# IMPORTANT: this is NOT the nixpkgs `splayer` package (which is the unrelated
# "Simple Netease Cloud Music player"). This is SPlayer-Dev/SPlayer-Next, the
# real app the original Arch setup intended via the AUR `splayer-next-git`.
#
# Building an Electron app reproducibly from source in Nix is fragile: it needs
# an FHS build env, a system Electron, and prebuilt Rust native modules
# (audio-engine / media-ctrl / taskbar-lyric). The reliable, working approach
# used here is to wrap the official release AppImage with `appimage-run`.
#
# To build from source instead, use the AUR `splayer-next-git` PKGBUILD as a
# reference and adapt it into a `pkgs.buildFHSUserEnv` derivation — but expect
# to iterate (electron version pin, ffmpeg patch, native module compile).
pkgs.appimage-run {
  name = "splayer-next";
  src = pkgs.fetchurl {
    url = "https://github.com/SPlayer-Dev/SPlayer-Next/releases/download/v1.0.0/splayer-next-1.0.0-x86_64.AppImage";
    sha256 = "sha256-d756900f183be90b471bc72e44519945be62b3535ee587ab70f5da23c95af548";
  };
  extraPkgs = pkgs: with pkgs; [ ffmpeg ];
}
