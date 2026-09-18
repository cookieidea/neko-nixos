# home.packages 聚合入口：按用途分到 programs/<分类>/default.nix
#
# 分类参照 yigexuanmu/my-nixos-config 的组织方式（Terminal/Develop/
# Entertain/Games/Utility/Desktop），每个分类一个模块，便于按用途查找。
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
