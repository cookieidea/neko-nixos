{ pkgs }:

# Pins — 创建/编辑 .desktop 快捷方式（GTK4/libadwaita）
pkgs.stdenv.mkDerivation {
  pname = "pins";
  version = "2.4.5-unstable-2026-08-12";

  src = builtins.fetchGit {
    url = "https://github.com/fabrialberio/Pins";
    rev = "d1b7bace3307d5723522045df36d8f823af02d48";
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
