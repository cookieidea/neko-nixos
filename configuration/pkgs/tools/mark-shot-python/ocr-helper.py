#!/usr/bin/env python3
"""mark-shot 的 OCR 后端：读图片路径，输出 rapidocr 识别结果的 JSON。

由 Nix 部署（见 pkgs/tools/mark-shot-python），用该环境的 python3 执行，
不再依赖 activation 现场创建 venv 装依赖。

用法: ocr-helper.py <图片路径>
输出: {"backend": "rapidocr", "tokens": [{"text", "confidence", "box"}]}
"""

import sys
import json
import glob

from rapidocr import RapidOCR

# rapidocr 包内模型文件名与 Python API 默认查找的名称不一致，需显式指定。
# 从 sys.prefix 推导，避免硬编码 store 哈希或 python 版本号。
_CANDIDATES = glob.glob(sys.prefix + "/lib/python*/site-packages/rapidocr/models")
_M = _CANDIDATES[0] if _CANDIDATES else ""

e = RapidOCR(
    params={
        "Det.model_path": _M + "/ch_PP-OCRv4_det_infer.onnx",
        "Rec.model_path": _M + "/ch_PP-OCRv4_rec_infer.onnx",
        "Cls.model_path": _M + "/ch_ppocr_mobile_v2.0_cls_infer.onnx",
    }
)

result = e(sys.argv[1])
tokens = []
if result and result.txts:
    for i, txt in enumerate(result.txts):
        box = result.boxes[i].tolist() if result.boxes is not None else []
        tokens.append({"text": txt, "confidence": float(result.scores[i]), "box": box})
print(json.dumps({"backend": "rapidocr", "tokens": tokens}))
