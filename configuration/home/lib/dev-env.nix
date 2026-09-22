# 开发工具的默认环境与包管理器镜像。
{ pkgs, username, ... }:

{
  # 这两个变量属于用户级开发环境，保留全局设置。
  # Python / VapourSynth 的专用路径改由对应程序 wrapper 注入，避免污染整个 session。
  devEnv = {
    JAVA_HOME = "${pkgs.zulu25}";
    CARGO_HOME = "$HOME/.cargo";
  };

  devBinPath = [ "$HOME/.cargo/bin" "$HOME/.npm-global/bin" ];

  npmrc = ''
    registry=https://registry.npmmirror.com
    prefix=/home/${username}/.npm-global
  '';
  cargoConfig = ''
    [source.crates-io]
    replace-with = 'ustc'
    [source.ustc]
    registry = "sparse+https://mirrors.ustc.edu.cn/crates.io-index/"
    [net]
    git-fetch-with-cli = true
  '';
  pipConf = ''
    [global]
    index-url = https://mirrors.ustc.edu.cn/pypi/simple
  '';
  uvToml = ''
    [[index]]
    url = "https://mirrors.ustc.edu.cn/pypi/simple"
    default = true
  '';
}
