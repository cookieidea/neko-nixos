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
  # GTK4 全依赖链（gtk4 + 显式列出 typelib 提供者 + propagated 传递依赖）
  gtkPkgs = [
    pkgs.gtk4 pkgs.cairo pkgs.pango pkgs.glib pkgs.gdk-pixbuf
    pkgs.harfbuzz pkgs.fribidi pkgs.libthai pkgs.graphene
  ] ++ pkgs.gtk4.propagatedBuildInputs;
  # typelib 搜索路径：
  # - ⚠️ Cairo-1.0.typelib 由 gobject-introspection 包生成（cairo 包本身不构建
  #   introspection、不带 typelib！Gdk-4.0 加载时缺它报
  #   "Typelib file for namespace 'cairo', version '1.0' not found"）
  #   见 https://github.com/NixOS/nixpkgs/issues/34080
  # - 部分包（glib/pango/graphene 等）的 .typelib 在 dev 输出 → 每个包收 out+dev
  # - graphene 是 Gtk-4.0 typelib 的依赖（Graphene-1.0）
  typelibPkgs = [ pkgs.gobject-introspection ] ++ gtkPkgs
    ++ map (p: p.dev or p) [ pkgs.cairo pkgs.gtk4 pkgs.pango pkgs.glib pkgs.graphene pkgs.gdk-pixbuf ];
  giTypelibPath = pkgs.lib.makeSearchPath "lib/girepository-1.0" typelibPkgs;
  # GTK4 动态库路径（typelib 加载后 dlopen libgtk-4.so 需要；NixOS PATH 无）
  giLibPath = pkgs.lib.makeLibraryPath gtkPkgs;
  # GTK4 数据目录（schemas/icons/themes）
  giDataPath = pkgs.lib.makeSearchPath "share" (gtkPkgs ++ [ pkgs.gsettings-desktop-schemas ]);
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
      --prefix PATH : "${runtimePath}" \
      --prefix GI_TYPELIB_PATH : "${giTypelibPath}" \
      --prefix LD_LIBRARY_PATH : "${giLibPath}" \
      --prefix XDG_DATA_DIRS : "${giDataPath}"

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
