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

    # OCR / 扫码 helper：安装 Nix 构建好的脚本（Python 代码见
    # pkgs/tools/mark-shot-python/*.py），此处不再内联生成。
    $DRY_RUN_CMD ln -sfn "${selfPackages.markShotOcrHelper}/bin/ocr-helper.py" "$MARK/ocr-helper.sh"
    $DRY_RUN_CMD ln -sfn "${selfPackages.markShotScanHelper}/bin/code-scan-helper.py" "$MARK/code-scan-helper.sh"

    # 清理遗留的 pip venv：早期版本在此创建 venv 装 OCR/扫码依赖，
    # 现改由 Nix 环境提供（见 pkgs/tools/mark-shot-python），此处只负责收尾。
    $DRY_RUN_CMD rm -rf "$MARK/ocr-venv" "$MARK/code-scan-venv"

    # HM 配置是 /nix/store 的只读 symlink；先物化到用户目录，再注入 secret。
    CFG="$HOME/.config/mark-shot/config.json"
    if [ -L "$CFG" ] && [ -f "/run/agenix/mark-shot-sensitive" ]; then
      LINK_TARGET=$(${pkgs.coreutils}/bin/readlink -f "$CFG")
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/cp -f "$LINK_TARGET" "$CFG"
      $DRY_RUN_CMD ${pkgs.python3}/bin/python3 ${../dotfiles/config/mark-shot/inject-secrets.py} "$CFG" "$CFG"
    fi
  '';
}
