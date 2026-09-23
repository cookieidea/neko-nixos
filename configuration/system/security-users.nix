{ username, ... }:

{
  security.polkit.enable = true;

  users.users.${username} = {
    isNormalUser = true;
    description = username;

    # 功能组由对应模块追加
    extraGroups = [ "networkmanager" "wheel" "video" "audio" ];

    # 公钥登录；与 openssh 模块配套
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMuZpLadDhA+oJfVRBlMAaYL0qCnBla9uaCAAS3/RFf9 cookie@ATRI-neko-nixos"
    ];
  };
}
