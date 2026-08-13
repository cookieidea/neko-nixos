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
  # ⚠️ pyside6 override 剔除 qtwebengine/qtwebview：PySide6 在 Linux 全量绑定
  #    Qt 模块（packages ++ [qtwebengine]），会引入 qtwebengine 编译（GCC15 崩溃+OOM）。
  #    StartLive 只用 QtWidgets/QtCore，缺 WebEngine 绑定无影响（pythonImportsCheck 只 import PySide6）。
  pyside6-lite = pkgs.python312.pkgs.pyside6.overrideAttrs (old: {
    buildInputs = builtins.filter
      (p: !(builtins.elem (pkgs.lib.getName p) [ "qtwebengine" "qtwebview" ]))
      old.buildInputs;
  });

  py = pkgs.python312.withPackages (ps: with ps; [
    pyside6-lite
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

  nativeBuildInputs = [ pkgs.icoutils ];   # ico → png 图标转换

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin $out/share/startlive $out/share/pixmaps $out/share/applications
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

    # ── 图标 + desktop 文件（noctalia launcher / fuzzel / 应用列表可见）──
    # resources/icon_left.ico（项目自带，256x256）→ icotool 提取 png
    tmpicons=$(mktemp -d)
    icotool -x "$out/share/startlive/resources/icon_left.ico" -o "$tmpicons"
    # 取最大尺寸 png 作为应用图标
    big=$(find "$tmpicons" -name "*.png" -printf "%s %p\n" | sort -n | tail -1 | cut -d' ' -f2-)
    cp "$big" "$out/share/pixmaps/startlive.png"
    cat > $out/share/applications/startlive.desktop <<EOF
[Desktop Entry]
Type=Application
Name=StartLive
Name[zh_CN]=StartLive 推流地址
Comment=Bilibili streaming address helper (bypass LiveHime)
Exec=startlive
Icon=startlive
Terminal=false
Categories=Network;AudioVideo;
StartupWMClass=StartLive
EOF
    runHook postInstall
  '';

  meta = {
    description = "Bypass the requirement to use Bilibili's official LiveHime client to start streaming (PySide6 GUI)";
    homepage = "https://github.com/Radekyspec/StartLive";
    license = pkgs.lib.licenses.gpl3Plus;
    mainProgram = "startlive";
  };
}
