{ pkgs }:

# Pins — create and edit application shortcuts (.desktop files).
# Upstream: https://github.com/fabrialberio/Pins  (GTK4 / libadwaita, meson)
# Arch AUR: pins-git
pkgs.stdenv.mkDerivation {
  pname = "pins";
  version = "2.4.5-unstable-2026-08-12";

  src = pkgs.fetchFromGitHub {
    owner = "fabrialberio";
    repo  = "Pins";
    rev   = "d1b7bace3307d5723522045df36d8f823af02d48";
    sha256 = "sha256-8fkz8Edy1MysAJmGpVZ5IHkFDhGCC3ZyijqyyOxbqlY=";
  };

  nativeBuildInputs = [ pkgs.meson pkgs.ninja pkgs.pkg-config pkgs.wrapGAppsHook ];
  buildInputs = [ pkgs.gtk4 pkgs.libadwaita ];

  meta = {
    description = "Create and edit app shortcuts (.desktop files)";
    homepage    = "https://github.com/fabrialberio/Pins";
    license     = pkgs.lib.licenses.gpl3Plus;
    mainProgram = "pins";
    platforms   = pkgs.lib.platforms.linux;
  };
}
