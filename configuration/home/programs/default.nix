# Home Manager 托管的程序（git/starship/fish/noctalia…）
{ pkgs, username, ... }:

{
  # Home Manager 托管的程序
  programs = {
    git = {
      enable = true;
      settings = {
        user.name = "cookieidea";
        user.email = "jhbhyvv@outlook.com";
        # /etc/nixos 仓库是 root 所有，需声明 safe.directory（只读 store 链接没法 --add）
        safe.directory = "/etc/nixos";
      };
    };
    starship.enable = true;       # starship
    zoxide.enable = true;         # zoxide
    eza.enable = true;            # eza
    bat.enable = true;            # bat
    fzf.enable = true;            # fzf
    # fish + 插件（声明式，等价于原 fisher 管理的 fish_plugins 列表）
    fish = {
      enable = true;
      plugins = [
        { name = "autopair"; src = pkgs.fishPlugins.autopair.src; }
        { name = "fzf-fish"; src = pkgs.fishPlugins.fzf-fish.src; }
      ];
    };

    # Noctalia V5（Wayland 桌面 shell；由 config.kdl 的 spawn-at-startup 拉起）
    #
    # settings 支持 raw TOML 字符串，故用 readFile + 替换硬编码的家目录路径。
    # 上游 config.toml 里有 9 处 /home/cookie（主题模板、壁纸目录），
    # 直接作为 path 传入会在非 cookie 用户下失效。
    noctalia = {
      enable = true;
      systemd.enable = false;
      settings = builtins.replaceStrings
        [ "/home/cookie" ]
        [ "/home/${username}" ]
        (builtins.readFile ../dotfiles/config/noctalia/config.toml);
    };

    # niri：配置走 dotfiles 的 kdl 拆分文件（见 xdg.configFile）
  };
}
