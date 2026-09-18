# Home Manager 托管的程序（git/starship/fish/noctalia…）
{ hmLib, pkgs, username, selfPackages, noctalia, ... }:

{
  # ============================================================
  #  Home Manager 托管的程序（自动写 dotfiles，替代手写配置）
  # ============================================================
  programs = {
    git = {
      enable = true;
      settings = {
        user.name = "cookieidea";
        user.email = "jhbhyvv@outlook.com";
        # /etc/nixos 仓库是 root 所有，普通用户 git 操作会报 dubious ownership；
        # ~/.config/git/config 是只读 store 链接没法 --add，必须写进托管配置
        safe.directory = "/etc/nixos";
      };
    };
    starship.enable = true;       # starship
    zoxide.enable = true;         # zoxide
    eza.enable = true;            # eza
    bat.enable = true;            # bat
    fzf.enable = true;            # fzf（脚本里也装了）
    fish = {
      enable = true;
    };

    # ── Noctalia V5（原生 C++ Wayland 桌面 shell，替代 v4 noctalia-shell）──
    # settings 指向 NyxNiri 移植的 config.toml（见 xdg.configFile 部署注释）。
    # 不启用 systemd 服务：由 config.kdl 的 spawn-at-startup "noctalia" 拉起。
    noctalia = {
      enable = true;
      systemd.enable = false;
      settings = ../../config/config/noctalia/config.toml;
    };

    # ── niri：Wayland 滚动平铺 compositor ────────────────
    # 配置改用 dotfiles/niri/*.kdl，通过文件末尾的 xdg.configFile 部署，
    # 不再用 programs.niri.settings 生成，以免和手写的拆分 kdl 冲突。
  };
}
