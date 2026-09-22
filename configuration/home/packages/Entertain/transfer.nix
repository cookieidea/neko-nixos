# 下载与文件传输。
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    transmission_4-gtk                        # BT 下载
    localsend                                 # 局域网文件互传
  ];
}
