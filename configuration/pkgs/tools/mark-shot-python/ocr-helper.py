#!/usr/bin/env python3
"""mark-shot 的 OCR 后端：读图片路径，输出 rapidocr 识别结果的 JSON。

由 Nix 部署（见 pkgs/tools/mark-shot-python），用该环境的 python3 执行，
不再依赖 activation 现场创建 venv 装依赖。

用法: ocr-helper.py <图片路径>
输出: {"backend": "rapidocr", "tokens": [{"text", "confidence", "box"}]}
"""

import sys
import json

from rapidocr import RapidOCR

# rapidocr 3.x 自带默认模型（PP-OCRv6），直接用默认初始化；
# 旧版硬编码的 v4 模型文件名在 3.9.2 里已不存在。
e = RapidOCR(params={"Global.log_level": "critical"})

result = e(sys.argv[1])
tokens = []
if result and result.txts:
    for i, txt in enumerate(result.txts):
        box = result.boxes[i].tolist() if result.boxes is not None else []
        tokens.append({"text": txt, "confidence": float(result.scores[i]), "box": box})
print(json.dumps({"backend": "rapidocr", "tokens": tokens}))
