# activation 脚本（Noctalia seed、壁纸真实文件、mark-shot venv）
{ hmLib, pkgs, config, lib, username, selfPackages, ... }:

{
  # ============================================================
  #  Noctalia V5 迁移所需的可写 seed
  # ============================================================
  # 1) niri/effects.kdl 软链接：config.kdl `include "effects.kdl"`，由
  #    toggle-eyecare.sh 在普通/护眼模式间切换。首次缺失时建为 Normal。
  # 2) kitty/current-theme.conf：由 Noctalia kitty 模板生成（写色），只读
  #    symlink 会挡住写入 → 首次缺失时种子写入一个可写真实文件。
# 3) noctalia-config.toml（V5 读 ~/.config/noctalia/config.toml）：programs.noctalia.settings
    #    部署的是只读 store symlink，而 V5 设置面板会回写该文件 → 复制为可写真实文件。
  # 4) starship.toml：palette 段由 Noctalia starship 模板重写 → 复制为可写。
  # 均仅在文件缺失/是 store 链接时执行，不覆盖用户运行期修改。
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

  # ── 壁纸真实文件（不用软链：GC 会删旧 store 路径导致断链）──
  home.activation.wallpaperRealFiles = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    WP="$HOME/Pictures/Wallpapers"
    for f in wallhaven-d88d53.png wallhaven-yq8w67.jpg; do
      if [ -L "$WP/$f" ] || [ ! -e "$WP/$f" ]; then
        $DRY_RUN_CMD mkdir -p "$WP"
        $DRY_RUN_CMD rm -f "$WP/$f"
        $DRY_RUN_CMD cp -f "${hmLib.seedWallpaperDir}/$f" "$WP/$f"
      fi
    done
    # 视频壁纸本体 + mpvpaper 插件赋值路径（assignments.json 指向 ~/Videos/wallpaper/）
    for dest in "$WP/video/hatsune-miku.mp4" "$HOME/Videos/wallpaper/hatsune-miku.mp4"; do
      if [ -L "$dest" ] || [ ! -e "$dest" ]; then
        $DRY_RUN_CMD mkdir -p "$(dirname "$dest")"
        $DRY_RUN_CMD rm -f "$dest"
        $DRY_RUN_CMD cp -f "${hmLib.seedWallpaperVideo}" "$dest"
      fi
    done
  '';

  # mark-shot OCR + 扫码 venv 自动初始化
  home.activation.markShotSetup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    MARK="$HOME/.local/share/mark-shot"
    OCR_VENV="$MARK/ocr-venv"
    SCAN_VENV="$MARK/code-scan-venv"
    PYTHON="${pkgs.python3}/bin/python3"
    LD_PATH="${pkgs.stdenv.cc.cc.lib}/lib:${pkgs.zlib.out}/lib:${pkgs.libgcc.lib}/lib:${pkgs.libxcb}/lib:${pkgs.libglvnd}/lib:${pkgs.glib.out}/lib"

    # OCR venv
    if [ ! -f "$OCR_VENV/bin/python" ] || ! env LD_LIBRARY_PATH="$LD_PATH" "$OCR_VENV/bin/python" -c "import rapidocr" 2>/dev/null; then
      $DRY_RUN_CMD rm -rf "$OCR_VENV"
      $DRY_RUN_CMD $PYTHON -m venv "$OCR_VENV"
      $DRY_RUN_CMD env LD_LIBRARY_PATH="$LD_PATH" "$OCR_VENV/bin/pip" install rapidocr onnxruntime
    fi

    # code-scan venv
    if [ ! -f "$SCAN_VENV/bin/python" ] || ! env LD_LIBRARY_PATH="$LD_PATH" "$SCAN_VENV/bin/python" -c "import zxingcpp" 2>/dev/null; then
      $DRY_RUN_CMD rm -rf "$SCAN_VENV"
      $DRY_RUN_CMD $PYTHON -m venv "$SCAN_VENV"
      $DRY_RUN_CMD env LD_LIBRARY_PATH="$LD_PATH" "$SCAN_VENV/bin/pip" install zxing-cpp pillow numpy
    fi

    # OCR helper script（mark-shot 调用入口，读图片路径 → rapidocr）
    $DRY_RUN_CMD cat > "$MARK/ocr-helper.sh" << 'OCRSCRIPT'
#!/usr/bin/env bash
export LD_LIBRARY_PATH="LIBPATH_PLACEHOLDER"
/home/cookie/.local/share/mark-shot/ocr-venv/bin/python -c "
from rapidocr import RapidOCR
import sys, json
e = RapidOCR()
result = e(sys.argv[1])
tokens = []
if result and result.txts:
    for i, txt in enumerate(result.txts):
        box = result.boxes[i].tolist() if result.boxes is not None else []
        tokens.append({'text': txt, 'confidence': float(result.scores[i]), 'box': box})
print(json.dumps({'backend': 'rapidocr', 'tokens': tokens}))
" "$1"
OCRSCRIPT
    $DRY_RUN_CMD sed -i "s|LIBPATH_PLACEHOLDER|$LD_PATH|" "$MARK/ocr-helper.sh"
    $DRY_RUN_CMD chmod +x "$MARK/ocr-helper.sh"

    # code-scan helper script（mark-shot 调用入口，用 {imagePath} 占位符）
    $DRY_RUN_CMD cat > "$MARK/code-scan-helper.sh" << 'SCANSCRIPT'
#!/usr/bin/env bash
export LD_LIBRARY_PATH="LIBPATH_PLACEHOLDER"
/home/cookie/.local/share/mark-shot/code-scan-venv/bin/python -c "
import zxingcpp, sys, json, numpy as np
from PIL import Image
img = Image.open(sys.argv[1]).convert('RGB')
arr = np.array(img)[:, :, ::-1]
results = zxingcpp.read_barcodes(arr)
output = {'backend': 'zxing', 'results': [], 'errors': []}
for r in results:
    output['results'].append({'text': r.text, 'format': str(r.format)})
print(json.dumps(output))
" "$1"
SCANSCRIPT
    $DRY_RUN_CMD sed -i "s|LIBPATH_PLACEHOLDER|$LD_PATH|" "$MARK/code-scan-helper.sh"
    $DRY_RUN_CMD chmod +x "$MARK/code-scan-helper.sh"
    # xdg.configFile 创建的是 nix store symlink（只读），覆盖为真实文件再注入 agenix secrets
    CFG="$HOME/.config/mark-shot/config.json"
    if [ -L "$CFG" ] && [ -f "/run/agenix/mark-shot-sensitive" ]; then
      LINK_TARGET=$(${pkgs.coreutils}/bin/readlink -f "$CFG")
      $DRY_RUN_CMD ${pkgs.python3}/bin/python3 ${../../dotfiles/config/mark-shot/inject-secrets.py} "$CFG" "$LINK_TARGET"
    fi
  '';
}
