# Home Manager 程序配置。
{ pkgs, username, ... }:

{
  programs = {
    git = {
      enable = true;
      settings = {
        user.name = "cookieidea";
        user.email = "jhbhyvv@outlook.com";
        # /etc/nixos 通常由 root 管理，需要声明 safe.directory。
        safe.directory = "/etc/nixos";
      };
    };
    starship.enable = true;
    zoxide.enable = true;
    eza.enable = true;
    bat.enable = true;
    fzf.enable = true;
    # Fish 及其插件。
    fish = {
      enable = true;
      plugins = [
        { name = "autopair"; src = pkgs.fishPlugins.autopair.src; }
        { name = "fzf-fish"; src = pkgs.fishPlugins.fzf-fish.src; }
      ];
    };

    # Noctalia V5；按 username 替换配置中的家目录。
    noctalia = {
      enable = true;
      systemd.enable = false;
      settings = builtins.replaceStrings
        [ "__NEKO_HOME__" ]
        [ "/home/${username}" ]
        (builtins.readFile ./dotfiles/config/noctalia/config.toml);
    };

    # niri 配置由 xdg.configFile 部署。
  };
}
