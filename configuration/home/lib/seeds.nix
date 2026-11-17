# activation 复制到 $HOME 的可写种子文件。
{ pkgs, username }:

{
  seedKittyTheme     = "${./../dotfiles/config/kitty/themes/noctalia.conf}";
  # Noctalia 的 kitty 模板要往 kitty.conf 里维护 include 行，故部署为可写副本。
  seedKittyConf      = "${./../dotfiles/config/kitty/kitty.conf}";
  # activation 会把配置复制为可写文件，因此这里先按 username 替换家目录。
  seedNoctaliaConfig = pkgs.writeText "noctalia-config.toml"
    (builtins.replaceStrings
      [ "__NEKO_HOME__" ]
      [ "/home/${username}" ]
      (builtins.readFile ./../dotfiles/config/noctalia/config.toml));
  seedStarship       = "${./../dotfiles/config/starship.toml}";
  seedMangoHud       = "${./../dotfiles/config/MangoHud/MangoHud.conf}";
  seedWallpaperVideo = "${./../dotfiles/Pictures/Wallpapers/video/hatsune-miku.mp4}";
  # mark-shot 的配置含密钥，由 activation 注入，因此必须是可写副本。
  seedMarkShotConfig = pkgs.writeText "mark-shot-config.json" (builtins.toJSON {
    upload = {
      env = {
        MARK_SHOT_UPLOAD_FIELD_key = "";
      };
    };
    translation = {
      youdao = {
        appKey = "";
        appSecret = "";
      };
    };
  });
}
