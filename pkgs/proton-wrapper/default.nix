{ pkgs }:

# shorin-proton-wrapper — a simple wrapper to run EXE files via Proton (Steam).
# Upstream: https://github.com/SHORiN-KiWATA/proton-wrapper
# Arch AUR: shorin-proton-wrapper-git
#
# ⚠️ 打包要点：
# - shorin-proton-wrapper-manager 是 python3 + PyGObject(GTK) 脚本，直接装会
#   「打不开」（NixOS PATH 无 python3/GTK 绑定）→ makeWrapper 注入 python 环境
# - bash 脚本需要 notify-send/xdg-open/update-desktop-database → --prefix PATH
let
  py = pkgs.python3.withPackages (ps: with ps; [
    pygobject3     # gi.repository (Gtk/Gdk/GLib)
    icoextract     # exe 图标提取（缩略图）
    pillow         # 图像处理（缩略图）
  ]);
  runtimePath = pkgs.lib.makeBinPath [
    pkgs.libnotify            # notify-send（下载进度通知）
    pkgs.xdg-utils            # xdg-open（管理器导出/打开）
    pkgs.desktop-file-utils   # update-desktop-database（导出到应用菜单）
  ];
in
pkgs.stdenv.mkDerivation {
  pname = "shorin-proton-wrapper";
  version = "unstable-2026-08-12";

  src = builtins.fetchGit {
    url = "https://github.com/SHORiN-KiWATA/proton-wrapper";
    rev = "7e70126ecae420f00783d0375b72451c06956549";
  };

  nativeBuildInputs = [ pkgs.makeWrapper ];

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/bin" "$out/share/applications" "$out/share/icons/hicolor/256x256/apps"

    # bash 脚本（wrapper / configure）：注入 PATH 依赖
    for s in shorin-proton-wrapper shorin-proton-wrapper-configure; do
      install -Dm755 "$s" "$out/bin/.$s-raw"
      makeWrapper "$out/bin/.$s-raw" "$out/bin/$s" \
        --prefix PATH : "${runtimePath}"
    done

    # manager（python3 + PyGObject GUI）：用完整 python 环境 wrap
    install -Dm755 shorin-proton-wrapper-manager "$out/bin/.shorin-proton-wrapper-manager-raw"
    makeWrapper "${py}/bin/python3" "$out/bin/shorin-proton-wrapper-manager" \
      --add-flags "$out/bin/.shorin-proton-wrapper-manager-raw" \
      --prefix PATH : "${runtimePath}"

    install -Dm644 *.desktop -t "$out/share/applications/" 2>/dev/null || true
    # 图标放 hicolor/<size>/apps/（desktop Icon=shorin-proton 才能被主题扫描到）
    [ -d icons ] && cp icons/*.png "$out/share/icons/hicolor/256x256/apps/" 2>/dev/null || true
    runHook postInstall
  '';

  meta = {
    description = "A simple wrapper to run EXEs via Proton";
    homepage    = "https://github.com/SHORiN-KiWATA/proton-wrapper";
    license     = "see https://github.com/SHORiN-KiWATA/proton-wrapper";
    mainProgram = "shorin-proton-wrapper";
    platforms   = pkgs.lib.platforms.linux;
  };
}
