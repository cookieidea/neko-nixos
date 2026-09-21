# activation 脚本（Noctalia seed、壁纸真实文件、mark-shot helper）
{ hmLib, pkgs, lib, selfPackages, ... }:

{
  # Noctalia V5 可写 seed（文件缺失或是 store 链接时复制）
  home.activation.noctaliaV5Seed = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    NIRI_DIR="$HOME/.config/niri"
    KITTY_DIR="$HOME/.config/kitty"
    NOCT_DIR="$HOME/.config/noctalia"

    # effects.kdl 软链接（指向 Normal 效果）
    if [ ! -e "$NIRI_DIR/effects.kdl" ]; then
      $DRY_RUN_CMD mkdir -p "$NIRI_DIR"
      $DRY_RUN_CMD ln -sfn "effects_normal.kdl" "$NIRI_DIR/effects.kdl"
    fi

    # kitty current-theme.conf：Noctalia kitty 模板生成，缺失时种子写入 NyxNiri 主题
    if [ ! -e "$KITTY_DIR/current-theme.conf" ]; then
      $DRY_RUN_CMD mkdir -p "$KITTY_DIR"
      $DRY_RUN_CMD cp -f "${hmLib.seedKittyTheme}" "$KITTY_DIR/current-theme.conf"
    fi

    # noctalia-config.toml：覆盖 HM 的只读 symlink 为可写真实文件
    if [ -L "$NOCT_DIR/config.toml" ] || [ ! -e "$NOCT_DIR/config.toml" ]; then
      $DRY_RUN_CMD mkdir -p "$NOCT_DIR"
      $DRY_RUN_CMD rm -f "$NOCT_DIR/config.toml" "$NOCT_DIR/noctalia-config.toml"
      $DRY_RUN_CMD cp -f "${hmLib.seedNoctaliaConfig}" "$NOCT_DIR/config.toml"
    fi

    # starship.toml：覆盖只读 symlink 为可写真实文件（Noctalia 会重写 palette 段）
    if [ -L "$HOME/.config/starship.toml" ] || [ ! -e "$HOME/.config/starship.toml" ]; then
      $DRY_RUN_CMD rm -f "$HOME/.config/starship.toml"
      $DRY_RUN_CMD cp -f "${hmLib.seedStarship}" "$HOME/.config/starship.toml"
    fi

    # MangoHud.conf：mangojuice/GOverlay 保存设置时会写此文件 → 覆盖只读 symlink 为可写副本
    if [ -L "$HOME/.config/MangoHud/MangoHud.conf" ] || [ ! -e "$HOME/.config/MangoHud/MangoHud.conf" ]; then
      $DRY_RUN_CMD mkdir -p "$HOME/.config/MangoHud"
      $DRY_RUN_CMD rm -f "$HOME/.config/MangoHud/MangoHud.conf"
      $DRY_RUN_CMD cp -f "${hmLib.seedMangoHud}" "$HOME/.config/MangoHud/MangoHud.conf"
      $DRY_RUN_CMD chmod 644 "$HOME/.config/MangoHud/MangoHud.conf"
    fi
  '';

  # 视频壁纸真实文件（不用软链）
  home.activation.wallpaperRealFiles = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    WP="$HOME/Pictures/Wallpapers"
    # 视频壁纸本体 + mpvpaper 插件赋值路径（assignments.json 指向 ~/Videos/wallpaper/）
    for dest in "$WP/video/hatsune-miku.mp4" "$HOME/Videos/wallpaper/hatsune-miku.mp4"; do
      if [ -L "$dest" ] || [ ! -e "$dest" ]; then
        $DRY_RUN_CMD mkdir -p "$(dirname "$dest")"
        $DRY_RUN_CMD rm -f "$dest"
        $DRY_RUN_CMD cp -f "${hmLib.seedWallpaperVideo}" "$dest"
      fi
    done
  '';

  # mark-shot OCR / 扫码后端
  #
  # 原先在 activation 里 `python -m venv` + `pip install`（联网访问 PyPI、
  # 依赖运行时解析、破坏可复现性，且 home-manager switch --offline 不可用）。
  # 现改为 Nix 构建的 Python 环境：依赖全部固定、离线可用、无网络副作用。
  #
  # helper 脚本路径与调用接口保持不变（config.json 里 command 指向它们），
  # 故 mark-shot 侧无需改动。
  home.activation.markShotSetup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    MARK="$HOME/.local/share/mark-shot"
    $DRY_RUN_CMD mkdir -p "$MARK"

    # OCR helper（mark-shot 调用入口，读图片路径 → rapidocr）
    $DRY_RUN_CMD cat > "$MARK/ocr-helper.sh" << 'OCRSCRIPT'
#!/usr/bin/env bash
exec ${selfPackages.markShotOcr}/bin/python3 -c '
from rapidocr import RapidOCR
import sys, json
# 显式指定模型路径：nixpkgs 的 rapidocr 包版本（3.8.1）与其内置模型不同步
# （包内是 v1.1.0 的 *_infer.onnx，而 3.8.1 默认找 *_mobile 并要求联网下载）。
# 不指定会尝试写入只读的 store 目录而失败。
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

    # code-scan helper（用 {imagePath} 占位符）
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

    # 清理旧 pip venv（已由 Nix 环境取代）
    $DRY_RUN_CMD rm -rf "$MARK/ocr-venv" "$MARK/code-scan-venv"

    # xdg.configFile 创建的是 nix store symlink（只读），覆盖为真实文件再注入 agenix secrets
    CFG="$HOME/.config/mark-shot/config.json"
    if [ -L "$CFG" ] && [ -f "/run/agenix/mark-shot-sensitive" ]; then
      LINK_TARGET=$(${pkgs.coreutils}/bin/readlink -f "$CFG")
      $DRY_RUN_CMD ${pkgs.python3}/bin/python3 ${../dotfiles/config/mark-shot/inject-secrets.py} "$CFG" "$LINK_TARGET"
    fi
  '';
}
