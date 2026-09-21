{ pkgs, ... }:

{
  home.packages = with pkgs; [
    fish
    starship
    zoxide
  ];
}
