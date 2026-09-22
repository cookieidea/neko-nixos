# Home Manager 程序配置。
{ pkgs, username, nix-vscode-extensions, ... }:

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

    # Discord（Vencord/Equicord）的声明式封装。
    # 取代此前的 flatpak Discord，使其进入 generation 管理。
    # user / homeDirectory / xdgConfigHome 由模块以 mkDefault 取自 HM 配置。
    nixcord = {
      enable = true;
      discord = {
        enable = true;
        # 必须显式启用 Vencord，否则装出来的只是原版 Discord
        # （两者都关时 nixcord 会给出 warning）。
        vencord.enable = true;
      };
    };

    # VSCodium：扩展经 nix-vscode-extensions 声明式管理。
    # 安装包本身由本模块负责，故 home.packages 里不再重复声明 vscodium。
    #
    # 必须用 programs.vscodium 而非 programs.vscode + package = pkgs.vscodium：
    # programs.vscode 固定按 VS Code 的路径写（~/.vscode、Code/User），
    # 而 VSCodium 实际读 .vscode-oss（其 product.json 的 dataFolderName）。
    # 用错模块会导致扩展落在 ~/.vscode/extensions 而 VSCodium 永远看不到 ——
    # HM 对此有明确提示，要求改用对应 fork 的专用模块。
    vscodium = {
      enable = true;
      profiles.default.extensions =
        with nix-vscode-extensions.extensions.${pkgs.stdenv.hostPlatform.system}.vscode-marketplace;
        [
          # 简体中文语言包。
          ms-ceintl.vscode-language-pack-zh-hans
        ];
    };

    # niri 配置由 xdg.configFile 部署。
  };
}
