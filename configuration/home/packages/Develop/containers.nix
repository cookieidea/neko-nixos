{ pkgs, ... }:

{
  home.packages = with pkgs; [
    docker-compose
    distrobox
  ];
}
