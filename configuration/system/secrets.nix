# agenix 加密 secrets
{ username, ... }:

{
  age.identityPaths = [ "/etc/age/key" ];
  age.secrets."mark-shot-sensitive" = {
    file = ../../secrets/mark-shot-sensitive.age;
    owner = username;
    group = "users";
  };
}
