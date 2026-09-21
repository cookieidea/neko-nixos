# mark-shot 的 OCR / 扫码 Python 环境（供 activation 生成的 helper 脚本使用）
#
# 原先由 activation 里 `python -m venv` + `pip install` 现场创建，
# 会联网访问 PyPI 并按运行时解析版本，导致：
#   · home-manager switch 需要联网，--offline 不可用
#   · 同一配置在不同时间装出不同依赖版本
# 改为 Nix 构建后，依赖固定、离线可用。
{ pkgs }:

{
  # OCR：rapidocr + onnxruntime（RapidOCR 推理）
  markShotOcr = pkgs.python3.withPackages (ps: with ps; [
    rapidocr
    onnxruntime
  ]);

  # 扫码：zxing-cpp 负责解码，Pillow/numpy 负责图像预处理
  markShotScan = pkgs.python3.withPackages (ps: with ps; [
    zxing-cpp
    pillow
    numpy
  ]);
}
