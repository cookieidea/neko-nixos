{ pkgs }:
{
  nautilus-image-converter = import ./image-converter.nix { inherit pkgs; };
  nautilus-with-extensions = import ./nautilus-with-extensions.nix { inherit pkgs; };
}
