{ pkgs }:

# Pins：创建和编辑 .desktop 快捷方式。
pkgs.stdenv.mkDerivation {
  pname = "pins";
  version = "2.4.5-unstable-2026-08-12";

  # pkgs.fetchgit（固定输出派生）取代 builtins.fetchGit —— 后者在求值期联网，
  # 会强制 flake 以 --impure 求值，网络不可达时求值失败。
  src = pkgs.fetchgit {
    url = "https://github.com/fabrialberio/Pins";
    rev = "d1b7bace3307d5723522045df36d8f823af02d48";
    hash = "sha256-fRHx+97itr4I30rNqK/PViUViVU7wRhAqVmAfTNuolc=";
  };

  nativeBuildInputs = [ pkgs.meson pkgs.ninja pkgs.pkg-config pkgs.wrapGAppsHook4 pkgs.desktop-file-utils ];
  buildInputs = [ pkgs.gtk4 pkgs.libadwaita ];

  meta = {
    description = "Create and edit app shortcuts (.desktop files)";
    homepage    = "https://github.com/fabrialberio/Pins";
    license     = pkgs.lib.licenses.gpl3Plus;
    mainProgram = "pins";
    platforms   = pkgs.lib.platforms.linux;
  };
}
