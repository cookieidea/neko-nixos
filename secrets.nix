let
  # ATRI 主机 age 公钥（私钥在 /etc/age/key，勿提交）
  atri = "age1j8pdqkestl8h4fl93vavsp68sh4vmk9jfd726lqfzq9s7yel0dnshxcry8";
in
{
  "secrets/test-secret.age".publicKeys = [ atri ];
  "secrets/bilibili-cookies.age".publicKeys = [ atri ];
}
