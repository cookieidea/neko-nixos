# activation 使用的可写种子文件。
#
# 这些文件会被 activation 复制到 $HOME 成为可写副本（应用需自行改写），
# 故不能用只读的 store symlink 直接部署。
{ pkgs, username }:

{
  seedKittyTheme     = builtins.toString ./../dotfiles/config/kitty/themes/noctalia.conf;
  # activation 会把配置复制为可写文件，因此这里先按 username 替换家目录。
  seedNoctaliaConfig = pkgs.writeText "noctalia-config.toml"
    (builtins.replaceStrings
      [ "__NEKO_HOME__" ]
      [ "/home/${username}" ]
      (builtins.readFile ./../dotfiles/config/noctalia/config.toml));
  seedStarship       = builtins.toString ./../dotfiles/config/starship.toml;
  seedMangoHud       = builtins.toString ./../dotfiles/config/MangoHud/MangoHud.conf;
  seedWallpaperVideo = builtins.toString ./../dotfiles/Pictures/Wallpapers/video/hatsune-miku.mp4;
}
