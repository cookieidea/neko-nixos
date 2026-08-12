# rime-wanxiang（万象拼音）—— amzxyz/rime-wanxiang GitHub 最新版
#
# 纯 RIME 数据包（yaml 方案 + AI 语料词库，无编译），默认分支 wanxiang。
# 打包成 share/rime 目录，经 fcitx5-rime.override { rimeDataPkgs = ... } 接入。
# 替代 nixpkgs 自带 rime-wanxiang（版本可能滞后于 GitHub 最新）。
{ pkgs }:

let
  src = builtins.fetchGit {
    url = "https://github.com/amzxyz/rime-wanxiang";
    ref = "wanxiang";
    rev = "22723512903b45bf01d37fbb5541896f2590aa5e";
  };
in
pkgs.stdenv.mkDerivation {
  pname = "rime-wanxiang";
  version = "2026-08-13";

  inherit src;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/rime
    cp -r $src/. "$out/share/rime/"
    # nix store 源只读（444/555），cp 保留只读权限 → 先放开写权限再清理
    chmod -R u+w "$out/share/rime/"
    # 清理非 RIME 文件（保留 dicts/ custom/ lua/ 等运行时数据）
    rm -rf "$out/share/rime/.git" "$out/share/rime/.github" \
           "$out/share/rime/docs" "$out/share/rime/mkdocs.yml" \
           "$out/share/rime/README.md" "$out/share/rime/CHANGELOG.md" \
           "$out/share/rime/LICENSE" \
           "$out/share/rime/.release-please-manifest.json" \
           "$out/share/rime/.gitattributes" "$out/share/rime/.gitignore" \
           "$out/share/rime/.yamlfmt"
    runHook postInstall
  '';

  meta = {
    description = "万象拼音 RIME 方案（AI 语料优化词库，支持全拼/双拼/Pro）";
    homepage = "https://github.com/amzxyz/rime-wanxiang";
    license = pkgs.lib.licenses.cc-by-40;
  };
}
