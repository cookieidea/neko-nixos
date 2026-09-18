# home.packages 聚合入口：按用途分到 programs/<分类>/default.nix
{ ... }:

{
  imports = [
    ./programs/Terminal
    ./programs/Develop
    ./programs/Games
    ./programs/Entertain
    ./programs/Desktop
    ./programs/Utility
  ];
}
