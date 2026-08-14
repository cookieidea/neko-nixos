# PureVox —— 实时 AI 音频降噪工具（降噪 / TSE 目标说话人提取 / AEC 回声消除 / EQ）
#
# a2heng/PureVox（GPL-3.0，AI 模型除外见 MODEL-LICENSE.md）
# 技术栈：Python + PySide6 + C 扩展 + ONNX Runtime；Linux 音频走原生 PipeWire。
# 发布：CI 自动按 tag 构建 deb / rpm / AppImage / Windows / Android。
#
# 打包方式：AppImage（捆绑内嵌 Python3.8 + PySide6 全部依赖，开箱即用，
# 只需系统有 PipeWire —— NixOS 已启用）。用 appimageTools.wrapType2 解包，
# 运行时不依赖 FUSE。
#
# ⚠️ 更新：项目每天自动发版（tag 形如 v2026.08.14.1643），升级只需改
#     version + 下方 fetchurl 的 sha256（对应 tag 的 AppImage 资产 hash）。
{ pkgs }:

let
  # 最新发布版 tag（2026-08-14 CI 构建）
  version = "2026.08.14.1643";
  # 资产文件名里的日期是连字符格式（2026-08-14-1643），tag 是点格式
  # （v2026.08.14.1643）——URL 里两处不能混用，否则 404。
  assetDate = "2026-08-14-1643";
in
pkgs.appimageTools.wrapType2 {
  pname = "purevox";
  inherit version;

  src = pkgs.fetchurl {
    url = "https://github.com/a2heng/PureVox/releases/download/v${version}/PureVox-Linux-x64-${assetDate}-release.AppImage";
    sha256 = "cbae6a1ec0e5d29db8bd2cf87b0f5ff4cba76c79f08843132ccde83ad96b8892";
  };

  # ⚠️ AppRun 覆盖：原版 AppRun 的 LD_LIBRARY_PATH 只含 usr/lib/purevox，不含
  # 内嵌 python 的 lib 目录 → python3 加载 libpython3.8.so.1.0 失败
  # （wrapType2 解包后无 AppImage runtime 的 usr/lib 兜底，且 extract 会 patchelf
  # 二进制，rpath 不可靠）。这里用 find 动态收集解包产物内所有 lib 目录，
  # 全部注入 LD_LIBRARY_PATH，一次性覆盖 python38/lib 等任意位置。
  extraInstallCommands = ''
    cat > $out/AppRun <<'EOF'
    #!/bin/sh
    HERE="$(dirname "$(readlink -f "$0")")"
    export PYTHONHOME="$HERE/usr/python38"
    LIBS=$(find "$HERE" -type d \( -name lib -o -name lib64 \) 2>/dev/null | tr '\n' ':')
    export LD_LIBRARY_PATH="$LIBS''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    export PATH="$HERE/usr/python38/bin:$PATH"
    cd "$HERE/usr/lib/purevox" || exit 1
    exec "$HERE/usr/python38/bin/python3" run_pyside6.py "$@"
    EOF
    chmod +x $out/AppRun
  '';

  meta = with pkgs.lib; {
    description = "实时 AI 音频降噪（降噪/TSE/AEC/EQ，本地麦克风或手机远程推流，PipeWire）";
    homepage = "https://github.com/a2heng/PureVox";
    license = licenses.gpl3Only;
    mainProgram = "purevox";
    platforms = platforms.linux;
  };
}
