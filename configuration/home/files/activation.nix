# Home activation：初始化可写配置、壁纸和 mark-shot helper。
{ hmLib, pkgs, lib, selfPackages, ... }:

{
  # NyxNiri Dunder Protocol 兼容层。
  #
  # - 名称包含 "__custom__" 的文件/目录跨 Home Manager generation 保留。
  # - 旧的 /nix/store symlink 仅作为初始模板，首次迁移时物化为可编辑文件。
  # - Niri 的 monitor.kdl / effects.kdl 属于固定文件名保留项，单独保护。
  #
  # 使用“先快照、再 linkGeneration、后恢复”的顺序，
  # 避免 Home Manager 更新时把用户覆盖重新指回 /nix/store。
  home.activation.nyxniriDunderPrepare = lib.hm.dag.entryBefore [ "linkGeneration" ] ''
    NEKO_DUNDER_SNAPSHOT="$(mktemp -d "${TMPDIR:-/tmp}/neko-nixos-dunder.XXXXXX")"
    export NEKO_DUNDER_SNAPSHOT

    preserve_dunder_root() {
      local root_name="$1"
      local root="$HOME/.config/$root_name"
      local snapshot_root="$NEKO_DUNDER_SNAPSHOT/$root_name"
      local manifest="$snapshot_root/.manifest"
      local src rel target resolved parent_rel parent_name skip

      if [ ! -d "$root" ]; then
        return 0
      fi

      run mkdir -p "$snapshot_root"
      : > "$manifest"

      while IFS= read -r -d '' src; do
        rel="${src#"$root"/}"
        skip=0
        parent_rel="$rel"

        while [[ "$parent_rel" == */* ]]; do
          parent_rel="${parent_rel%/*}"
          parent_name="${parent_rel##*/}"
          if [[ "$parent_name" == *__custom__* ]]; then
            skip=1
            break
          fi
        done
        [ "$skip" -eq 1 ] && continue

        target="$snapshot_root/$rel"
        run mkdir -p "$(dirname "$target")"

        if [ -L "$src" ]; then
          resolved="$(readlink -f -- "$src" 2>/dev/null || true)"
          case "$resolved" in
            /nix/store/*)
              run cp -aL -- "$src" "$target"
              ;;
            *)
              run cp -a -- "$src" "$target"
              ;;
          esac
        else
          run cp -a -- "$src" "$target"
        fi

        printf '%s\\0' "$rel" >> "$manifest"
      done < <(${pkgs.findutils}/bin/find "$root" -mindepth 1 -name '*__custom__*' -print0)
    }

    preserve_niri_file() {
      local name="$1"
      local root="$HOME/.config/niri"
      local src="$root/$name"
      local snapshot_root="$NEKO_DUNDER_SNAPSHOT/niri"
      local target="$snapshot_root/$name"
      local resolved

      if [ ! -e "$src" ] && [ ! -L "$src" ]; then
        return 0
      fi

      run mkdir -p "$snapshot_root"

      if [ -L "$src" ]; then
        resolved="$(readlink -f -- "$src" 2>/dev/null || true)"
        case "$resolved" in
          /nix/store/*)
            run cp -aL -- "$src" "$target"
            ;;
          *)
            run cp -a -- "$src" "$target"
            ;;
        esac
      else
        run cp -a -- "$src" "$target"
      fi
    }

    preserve_dunder_root "niri"
    preserve_dunder_root "kitty"
    preserve_dunder_root "fish"
    preserve_niri_file "monitor.kdl"
    preserve_niri_file "effects.kdl"
  '';

  home.activation.nyxniriDunderRestore = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    if [ -n "${NEKO_DUNDER_SNAPSHOT:-}" ] && [ -d "$NEKO_DUNDER_SNAPSHOT" ]; then
      restore_dunder_root() {
        local root_name="$1"
        local root="$HOME/.config/$root_name"
        local snapshot_root="$NEKO_DUNDER_SNAPSHOT/$root_name"
        local manifest="$snapshot_root/.manifest"
        local rel src dest

        [ -f "$manifest" ] || return 0

        while IFS= read -r -d '' rel; do
          src="$snapshot_root/$rel"
          dest="$root/$rel"
          [ -e "$src" ] || [ -L "$src" ] || continue

          run rm -rf -- "$dest"
          run mkdir -p "$(dirname "$dest")"
          run cp -a -- "$src" "$(dirname "$dest")/"
        done < "$manifest"
      }

      restore_niri_file() {
        local name="$1"
        local src="$NEKO_DUNDER_SNAPSHOT/niri/$name"
        local dest="$HOME/.config/niri/$name"

        if [ -e "$src" ] || [ -L "$src" ]; then
          run rm -rf -- "$dest"
          run mkdir -p "$(dirname "$dest")"
          run cp -a -- "$src" "$(dirname "$dest")/"
        fi
      }

      restore_dunder_root "niri"
      restore_dunder_root "kitty"
      restore_dunder_root "fish"
      restore_niri_file "monitor.kdl"
      restore_niri_file "effects.kdl"

      run rm -rf -- "$NEKO_DUNDER_SNAPSHOT"
      unset NEKO_DUNDER_SNAPSHOT
    fi
  '';

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
