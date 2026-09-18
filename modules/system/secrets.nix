# agenix 加密 secrets
{ username, ... }:

{
  # 私钥 /etc/age/key（root only，不入 git）；加密文件在 secrets/，
  # 收件人公钥清单见 secrets/secrets.nix。
  # 用法：age -r <公钥> -o secrets/foo.age <明文>，然后此处声明
  # 注意：本文件在 modules/system/ 下，相对路径需回退两级到仓库根
  age.identityPaths = [ "/etc/age/key" ];
  age.secrets."mark-shot-sensitive" = {
    file = ../../secrets/mark-shot-sensitive.age;
    owner = username;
    group = "users";
  };
}
