{ pkgs, llm-agents-nix, ... }:

{
  home.packages = with pkgs; [
    glib
    llm-agents-nix.packages.${pkgs.stdenv.hostPlatform.system}.dsh
    llm-agents-nix.packages.${pkgs.stdenv.hostPlatform.system}.opencode
  ];
}
