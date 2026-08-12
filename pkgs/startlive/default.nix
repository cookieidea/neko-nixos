# StartLive —— 绕过 B 站官方直播姬获取推流地址（PySide6 GUI，纯 Python 脚本项目）
#
# 原 AUR: startlive-git (https://github.com/Radekyspec/StartLive)
# 打包方式：fetchGit 固定 rev（内容寻址免 hash）+ python.withPackages 组装运行时，
#           外层 wrapper 启动 StartLive.py。
# 关键适配：
#   - velopack（Windows 自动更新器）在 Linux 是 no-op，用 stub 模块顶掉 import
#     （StartLive.py 顶层 `from velopack import App`，不 stub 会直接 ImportError）
#   - qdarktheme 由 python3Packages.pyqtdarktheme 提供
#   - requests[socks] 需要 pysocks
{ pkgs }:

let
  src = builtins.fetchGit {
    url = "https://github.com/Radekyspec/StartLive";
    rev = "98c27d88e2b497c663e55d17991825985b2481c9";
  };

  # 运行用 Python 环境（StartLive 要求 3.11 <= py <= 3.13）
  # 用 python312：python311 下 keyring→secretstorage 依赖链的 sphinx-9.1.0 不支持 py311
  py = pkgs.python312.withPackages (ps: with ps; [
    pyside6
    pillow
    qrcode
    requests
    pysocks            # requests[socks]
    keyring
    darkdetect
    semver
    cryptography
    pyqtdarktheme      # qdarktheme 模块
    obsws-python
  ]);
in
pkgs.stdenv.mkDerivation {
  pname = "startlive";
  version = "2026-08-13";

  inherit src;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin $out/share/startlive
    cp -r . "$out/share/startlive/"
    # nix store 源只读（444/555），cp 保留只读权限 → 先放开写权限再清理
    chmod -R u+w "$out/share/startlive/"
    rm -rf "$out/share/startlive/.git"

    # velopack Linux stub（Windows 自动更新器在 Linux 下是 no-op）
    mkdir -p "$out/share/startlive/velopack-stub/velopack"
    cat > "$out/share/startlive/velopack-stub/velopack/__init__.py" <<'STUB'
class App:
    def __init__(self, *args, **kwargs):
        pass
    def on_first_run(self, cb):
        return self
    def run(self):
        return 0
class UpdateManager:
    def __init__(self, *args, **kwargs):
        pass
STUB

    cat > $out/bin/startlive <<EOF
#!${pkgs.runtimeShell}
export PYTHONPATH="$out/share/startlive/velopack-stub:\$PYTHONPATH"
exec ${py}/bin/python "$out/share/startlive/StartLive.py" "\$@"
EOF
    chmod +x $out/bin/startlive
    runHook postInstall
  '';

  meta = {
    description = "Bypass the requirement to use Bilibili's official LiveHime client to start streaming (PySide6 GUI)";
    homepage = "https://github.com/Radekyspec/StartLive";
    license = pkgs.lib.licenses.gpl3Plus;
    mainProgram = "startlive";
  };
}
