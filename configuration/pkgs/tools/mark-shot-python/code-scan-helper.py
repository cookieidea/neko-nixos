#!/usr/bin/env python3
"""mark-shot 的条码/二维码后端：读图片路径，输出 zxingcpp 解码结果的 JSON。

由 Nix 部署（见 pkgs/tools/mark-shot-python），用该环境的 python3 执行。

用法: code-scan-helper.py <图片路径>
输出: {"backend": "zxing", "results": [{"text", "format"}]}
"""

import sys
import json

import numpy as np
import zxingcpp
from PIL import Image

img = Image.open(sys.argv[1]).convert("RGB")
arr = np.array(img)[:, :, ::-1]
results = zxingcpp.read_barcodes(arr)

output = {"backend": "zxing", "results": [], "errors": []}
for r in results:
    output["results"].append({"text": r.text, "format": str(r.format)})
print(json.dumps(output))
