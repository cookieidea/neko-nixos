# NyxNiri 星环菜单（GTK3 + GtkLayerShell + pygobject）
# 跑 ~/.config/niri/scripts/niri-scratch-menu.py；wrapGAppsHook 收集 GI typelib，
# gtk-layer-shell 需手动 prepend
{ pkgs }:
let
  pythonEnv = pkgs.python3.withPackages (ps: [ ps.pygobject3 ps.pycairo ]);
in
pkgs.stdenv.mkDerivation {
  pname = "nyxniri-scratch-menu";
  version = "1.0.0";
  dontUnpack = true;
  nativeBuildInputs = [ pkgs.wrapGAppsHook3 ];
  buildInputs = [ pythonEnv pkgs.gtk3 pkgs.gtk-layer-shell pkgs.cairo pkgs.gobject-introspection ];
  installPhase = ''
    mkdir -p $out/bin
    cat > $out/bin/niri-scratch-menu <<EOF
#!/bin/sh
export GI_TYPELIB_PATH="${pkgs.gtk-layer-shell}/lib/girepository-1.0:${pkgs.gtk3}/lib/girepository-1.0:\$GI_TYPELIB_PATH"
exec "${pythonEnv}/bin/python3" "\$HOME/.config/niri/scripts/niri-scratch-menu.py" "\$@"
EOF
    chmod +x $out/bin/niri-scratch-menu
  '';
  meta.mainProgram = "niri-scratch-menu";
}