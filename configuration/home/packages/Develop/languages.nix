{ pkgs, ... }:

{
  home.packages = with pkgs; [
    (pkgs.lib.setPrio (-20) pkgs.zulu25)
    (pkgs.lib.setPrio (-15) pkgs.zulu21)
    (pkgs.lib.setPrio (-10) pkgs.zulu17)
    (pkgs.lib.setPrio (-5) pkgs.zulu8)
    (python3.withPackages (ps: [ ps.pip ]))
    uv
    rustc
    cargo
    rustfmt
    go
    nodejs_22
  ];
}
