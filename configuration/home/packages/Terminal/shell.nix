# shell 相关。fish / zoxide 由 programs.fish、programs.zoxide 安装与配置
# （Home Manager 模块会自动装包），此处只列模块不提供的：
# starship 的 HM 模块只写配置、不装包，故仍需在此安装。
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    starship
  ];
}
