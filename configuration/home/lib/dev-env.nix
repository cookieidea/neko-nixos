# 开发环境：环境变量、工具目录与包管理器镜像配置。
#
# 由 lib.nix 聚合并以扁平属性导出（hmLib.devEnv 等）。
{ pkgs, selfPackages, username }:

# 需要 rec：devEnv 引用同级的 pySite
rec {
  # Python site-packages 相对路径，由 nixpkgs 推导（如 lib/python3.13/site-packages）。
  # 不要硬编码 python3.13 —— 上游升到 3.14 时路径会失效且求值不报错。
  pySite = pkgs.python3.sitePackages;

  # 开发环境变量的唯一数据源；登录 shell 和 systemd user session 共用。
  devEnv = {
    JAVA_HOME = "${pkgs.zulu25}";          # 默认 JDK（HMCL 等多版本可自选）
    CARGO_HOME = "$HOME/.cargo";
    PYTHONPATH = "${pkgs.python3Packages.pygobject3}/${pySite}:${selfPackages.k7sfunc}/${pySite}:${pkgs.python3Packages.vapoursynth}/${pySite}";
    VAPOURSYNTH_EXTRA_PLUGIN_PATH = "${selfPackages.vapoursynth-with-plugins}/lib/vapoursynth";
  };

  # 用户级开发工具目录。
  devBinPath = [ "$HOME/.cargo/bin" "$HOME/.npm-global/bin" ];

  # 包管理器镜像配置；files.nix 负责部署真实文件。
  # npm prefix 使用绝对路径。
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
    trusted-host = mirrors.ustc.edu.cn
  '';
  uvToml = ''
    [[index]]
    url = "https://mirrors.ustc.edu.cn/pypi/simple"
    default = true
  '';
}
