# Home activation：初始化可写配置、壁纸和 mark-shot。
{ hmLib, pkgs, lib, selfPackages, ... }:

{
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

  # mark-shot helper 和 secret 注入。
  home.activation.markShotSetup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    MARK="$HOME/.local/share/mark-shot"
    $DRY_RUN_CMD mkdir -p "$MARK"

    $DRY_RUN_CMD ln -sfn "${selfPackages.markShotOcrHelper}/bin/ocr-helper.py" "$MARK/ocr-helper.sh"
    $DRY_RUN_CMD ln -sfn "${selfPackages.markShotScanHelper}/bin/code-scan-helper.py" "$MARK/code-scan-helper.sh"

    $DRY_RUN_CMD rm -rf "$MARK/ocr-venv" "$MARK/code-scan-venv"

    CFG="$HOME/.config/mark-shot/config.json"
    SECRET="/run/agenix/mark-shot-sensitive"
    if [ -f "$SECRET" ]; then
      if [ -L "$CFG" ]; then
        LINK_TARGET=$(${pkgs.coreutils}/bin/readlink -f "$CFG")
        $DRY_RUN_CMD rm -f "$CFG"
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/cp -f "$LINK_TARGET" "$CFG"
      fi
      if [ -f "$CFG" ]; then
        $DRY_RUN_CMD ${pkgs.python3}/bin/python3 ${../dotfiles/config/mark-shot/inject-secrets.py} "$CFG"
      fi
    fi
  '';
}
