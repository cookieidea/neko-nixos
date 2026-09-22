# OpenSSH。
{ ... }:

{
  services.openssh = {
    enable = true;
    settings = {
      # 只允许密钥登录。对应的用户公钥在 system/security-users.nix 的
      # openssh.authorizedKeys —— 两者需同时生效：若那里没有可用公钥，
      # 开启本项会导致无法登录（改前请确认 authorized_keys 已写入）。
      PasswordAuthentication = false;
      # 仅关 PasswordAuthentication 不够：keyboard-interactive 仍会走 PAM，
      # 可能保留密码通道。一并关闭才是真正的「仅密钥登录」。
      KbdInteractiveAuthentication = false;
      # 禁止 root 直接登录；需要提权时用普通用户 + sudo。
      PermitRootLogin = "no";
    };
  };
}
