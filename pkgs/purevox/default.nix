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
in
pkgs.appimageTools.wrapType2 {
  pname = "purevox";
  inherit version;

  src = pkgs.fetchurl {
    url = "https://github.com/a2heng/PureVox/releases/download/v${version}/PureVox-Linux-x64-${version}-release.AppImage";
    sha256 = "cbae6a1ec0e5d29db8bd2cf87b0f5ff4cba76c79f08843132ccde83ad96b8892";
  };

  meta = with pkgs.lib; {
    description = "实时 AI 音频降噪（降噪/TSE/AEC/EQ，本地麦克风或手机远程推流，PipeWire）";
    homepage = "https://github.com/a2heng/PureVox";
    license = licenses.gpl3Only;
    mainProgram = "purevox";
    platforms = platforms.linux;
  };
}
