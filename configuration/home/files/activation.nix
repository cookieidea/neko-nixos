# Home activation：初始化可写配置、壁纸和 mark-shot helper。
{ hmLib, pkgs, lib, selfPackages, ... }:

{
  # Noctalia、Kitty 和 MangoHud 的可写配置初始化。
  home.activation.noctaliaV5Seed = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    copy_seed() {
      seed_source="$1"
      seed_target="$2"
      seed_mode="''${3-}"

      if [ -L "$seed_target" ] || [ ! -e "$seed_target" ]; then
        $DRY_RUN_CMD mkdir -p "$(dirname "$seed_target")"
        $DRY_RUN_CMD rm -f "$seed_target"
        $DRY_RUN_CMD cp -f "$seed_source" "$seed_target"
        if [ -n "$seed_mode" ]; then
          $DRY_RUN_CMD chmod "$seed_mode" "$seed_target"
        fi
      fi
    }

    NIRI_DIR="$HOME/.config/niri"
    NOCT_DIR="$HOME/.config/noctalia"

    if [ ! -e "$NIRI_DIR/effects.kdl" ]; then
      $DRY_RUN_CMD mkdir -p "$NIRI_DIR"
      $DRY_RUN_CMD ln -sfn "effects_normal.kdl" "$NIRI_DIR/effects.kdl"
    fi

    copy_seed "${hmLib.seedKittyTheme}" "$HOME/.config/kitty/current-theme.conf"

    if [ -L "$NOCT_DIR/config.toml" ] || [ ! -e "$NOCT_DIR/config.toml" ]; then
      $DRY_RUN_CMD mkdir -p "$NOCT_DIR"
      $DRY_RUN_CMD rm -f "$NOCT_DIR/config.toml" "$NOCT_DIR/noctalia-config.toml"
      $DRY_RUN_CMD cp -f "${hmLib.seedNoctaliaConfig}" "$NOCT_DIR/config.toml"
    fi

    copy_seed "${hmLib.seedStarship}" "$HOME/.config/starship.toml"
    copy_seed "${hmLib.seedMangoHud}" "$HOME/.config/MangoHud/MangoHud.conf" 644
  '';

  home.activation.wallpaperRealFiles = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    WP="$HOME/Pictures/Wallpapers"
    for dest in "$WP/video/hatsune-miku.mp4" "$HOME/Videos/wallpaper/hatsune-miku.mp4"; do
      if [ -L "$dest" ] || [ ! -e "$dest" ]; then
        $DRY_RUN_CMD mkdir -p "$(dirname "$dest")"
        $DRY_RUN_CMD rm -f "$dest"
        $DRY_RUN_CMD cp -f "${hmLib.seedWallpaperVideo}" "$dest"
      fi
    done
  '';

  # mark-shot 使用 Nix 构建的 OCR / 扫码环境，不在 activation 阶段联网安装 Python 依赖。
  home.activation.markShotSetup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    MARK="$HOME/.local/share/mark-shot"
    $DRY_RUN_CMD mkdir -p "$MARK"

    # OCR helper。
    $DRY_RUN_CMD cat > "$MARK/ocr-helper.sh" << 'OCRSCRIPT'
#!/usr/bin/env bash
exec ${selfPackages.markShotOcr}/bin/python3 -c '
from rapidocr import RapidOCR
import sys, json
# rapidocr 包内模型版本与 Python API 默认名称不一致，因此显式指定模型文件。
import glob as _g
_M = _g.glob("${selfPackages.markShotOcr}/lib/python*/site-packages/rapidocr/models")[0]
e = RapidOCR(params={
    "Det.model_path": _M + "/ch_PP-OCRv4_det_infer.onnx",
    "Rec.model_path": _M + "/ch_PP-OCRv4_rec_infer.onnx",
    "Cls.model_path": _M + "/ch_ppocr_mobile_v2.0_cls_infer.onnx",
})
result = e(sys.argv[1])
tokens = []
if result and result.txts:
    for i, txt in enumerate(result.txts):
        box = result.boxes[i].tolist() if result.boxes is not None else []
        tokens.append({"text": txt, "confidence": float(result.scores[i]), "box": box})
print(json.dumps({"backend": "rapidocr", "tokens": tokens}))
' "$1"
OCRSCRIPT
    $DRY_RUN_CMD chmod +x "$MARK/ocr-helper.sh"

    # Barcode / QR helper。
    $DRY_RUN_CMD cat > "$MARK/code-scan-helper.sh" << 'SCANSCRIPT'
#!/usr/bin/env bash
exec ${selfPackages.markShotScan}/bin/python3 -c '
import zxingcpp, sys, json, numpy as np
from PIL import Image
img = Image.open(sys.argv[1]).convert("RGB")
arr = np.array(img)[:, :, ::-1]
results = zxingcpp.read_barcodes(arr)
output = {"backend": "zxing", "results": [], "errors": []}
for r in results:
    output["results"].append({"text": r.text, "format": str(r.format)})
print(json.dumps(output))
' "$1"
SCANSCRIPT
    $DRY_RUN_CMD chmod +x "$MARK/code-scan-helper.sh"

    # 删除旧的 pip venv。
    $DRY_RUN_CMD rm -rf "$MARK/ocr-venv" "$MARK/code-scan-venv"

    # 将 HM 的只读 config symlink 转为真实文件后再注入 secret。
    CFG="$HOME/.config/mark-shot/config.json"
    if [ -L "$CFG" ] && [ -f "/run/agenix/mark-shot-sensitive" ]; then
      LINK_TARGET=$(${pkgs.coreutils}/bin/readlink -f "$CFG")
      $DRY_RUN_CMD ${pkgs.python3}/bin/python3 ${../dotfiles/config/mark-shot/inject-secrets.py} "$CFG" "$LINK_TARGET"
    fi
  '';
}
