# mark-shot 的 OCR / 扫码 Python 环境，供 activation 生成的 helper 使用。
{ pkgs }:

{
  # OCR：RapidOCR + ONNX Runtime。
  markShotOcr = pkgs.python3.withPackages (ps: with ps; [
    rapidocr
    onnxruntime
  ]);

  # 扫码：zxing-cpp + Pillow + NumPy。
  markShotScan = pkgs.python3.withPackages (ps: with ps; [
    zxing-cpp
    pillow
    numpy
  ]);
}
