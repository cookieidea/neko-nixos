# 安全策略、polkit 和用户账户。
{ username, ... }:

{
  security.polkit.enable = true;
  # Noctalia greeter 的免密外观同步不在此处配置 —— 见 modules/desktop.nix 的
  # services.displayManager.noctalia-greeter.passwordless-sync-users。
  # （原先用 extraConfig 自行放行整个 wheel 组的该 action，授权范围比上游宽：
  #   上游会额外限定 action、目标须为 root、且调用者须为本地活跃会话中的允许用户。）

  users.users.${username} = {
    isNormalUser = true;
    description = username;
    # 功能相关组由对应模块追加；停用功能时权限也会随模块移除。
    #   libvirtd/docker/uinput/adbusers/gamemode → modules/virtualisation.nix
    #   i2c                                      → device/gpu.nix
    #   video/audio                              → 基础设备访问
    extraGroups = [ "networkmanager" "wheel" "video" "audio" ];

    # 登录用的公钥（声明式）。NixOS 据此生成 /etc/ssh/authorized_keys.d/<用户名>，
    # sshd 的 AuthorizedKeysFile 同时含该路径与 %h/.ssh/authorized_keys ——
    # 故无需手工往 ~/.ssh/authorized_keys 追加，重装/换机后同一把密钥即可登录。
    # 与 modules/services/openssh.nix 的「仅密钥登录」配套。
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMuZpLadDhA+oJfVRBlMAaYL0qCnBla9uaCAAS3/RFf9 cookie@ATRI-neko-nixos"
    ];
  };
}
