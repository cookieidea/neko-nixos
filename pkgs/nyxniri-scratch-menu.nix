# NyxNiri 星环菜单（GTK3 + GtkLayerShell + pygobject）NixOS 包装
# 运行已部署到 ~/.config/niri/scripts/niri-scratch-menu.py 的脚本，
# 提供正确的 GI_TYPELIB_PATH（gtk3 / gtk-layer-shell / pango）。
# buildInputs 列出运行依赖确保进 nix closure，不会被 GC。
{ pkgs }:
let
  pythonEnv = pkgs.python3.withPackages (ps: [ ps.pygobject3 ps.pycairo ]);
in
pkgs.stdenv.mkDerivation {
  pname = "nyxniri-scratch-menu";
  version = "1.0.0";
  dontUnpack = true;
  buildInputs = [ pythonEnv pkgs.gtk3 pkgs.gtk-layer-shell pkgs.pango pkgs.cairo ];
  installPhase = ''
    mkdir -p $out/bin
    cat > $out/bin/niri-scratch-menu <<EOF
#!/bin/sh
export GI_TYPELIB_PATH="${pkgs.gtk3}/lib/girepository-1.0:${pkgs.gtk-layer-shell}/lib/girepository-1.0:${pkgs.pango}/lib/girepository-1.0"
exec "${pythonEnv}/bin/python3" "$HOME/.config/niri/scripts/niri-scratch-menu.py" "\$@"
EOF
    chmod +x $out/bin/niri-scratch-menu
  '';
  meta.mainProgram = "niri-scratch-menu";
}