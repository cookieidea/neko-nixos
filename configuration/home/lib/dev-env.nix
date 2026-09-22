# 开发工具的环境变量与包管理器镜像。
{ pkgs, selfPackages, username }:

rec {
  pySite = pkgs.python3.sitePackages;

  devEnv = {
    JAVA_HOME = "${pkgs.zulu25}";
    CARGO_HOME = "$HOME/.cargo";
    PYTHONPATH = "${pkgs.python3Packages.pygobject3}/${pySite}:${selfPackages.k7sfunc}/${pySite}:${pkgs.python3Packages.vapoursynth}/${pySite}";
    VAPOURSYNTH_EXTRA_PLUGIN_PATH = "${selfPackages.vapoursynth-with-plugins}/lib/vapoursynth";
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
