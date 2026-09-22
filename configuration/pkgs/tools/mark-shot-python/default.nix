# mark-shot 的 OCR / 扫码 Python 环境，供 activation 生成的 helper 使用。
{ pkgs }:

# 需要 rec：helper 包引用同级的 markShotOcr / markShotScan
rec {
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

  # helper 入口：把上面的 Python 环境包装成可执行脚本，
  # 供 activation 安装到 ~/.local/share/mark-shot/。
  # 原先这两段 Python 内联在 activation.nix 的 heredoc 中，难以维护。
  markShotOcrHelper = pkgs.runCommand "mark-shot-ocr-helper" { nativeBuildInputs = [ pkgs.makeWrapper ]; } ''
    mkdir -p $out/bin
    cat > $out/bin/ocr-helper.py <<'PY'
${builtins.readFile ./ocr-helper.py}
PY
    chmod +x $out/bin/ocr-helper.py
    wrapProgram $out/bin/ocr-helper.py --set PATH ${markShotOcr}/bin
  '';

  markShotScanHelper = pkgs.runCommand "mark-shot-scan-helper" { nativeBuildInputs = [ pkgs.makeWrapper ]; } ''
    mkdir -p $out/bin
    cat > $out/bin/code-scan-helper.py <<'PY'
${builtins.readFile ./code-scan-helper.py}
PY
    chmod +x $out/bin/code-scan-helper.py
    wrapProgram $out/bin/code-scan-helper.py --set PATH ${markShotScan}/bin
  '';
}
