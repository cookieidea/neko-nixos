# Tabby — 可编程的现代化终端模拟器（Electron）
# Upstream: https://github.com/Eugeny/tabby（注意：nixpkgs 的 `tabby` 是 TabbyML AI 助手，同名不同项目）
#
# Electron 应用从源码构建在 Nix 下脆弱，直接 wrap 官方 release 的 AppImage（与 splayer-next 同法）。
{ pkgs }:

pkgs.appimageTools.wrapType2 {
  pname = "tabby-terminal";
  version = "1.0.235";
  src = pkgs.fetchurl {
    url = "https://github.com/Eugeny/tabby/releases/download/v1.0.235/tabby-1.0.235-linux-x64.AppImage";
    sha256 = "sha256-DKXcAV/l7nhA8rIGhkzDfFL3w2t6c06GU6Oa6KV23O8=";
  };
  # Electron 终端需要 xterm 相关资源，extraPkgs 补常用运行时
  extraPkgs = pkgs: with pkgs; [ ];
}
