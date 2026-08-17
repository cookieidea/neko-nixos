{ pkgs }:

# shorin-proton-wrapper — a simple wrapper to run EXE files via Proton (Steam).
# Upstream: https://github.com/SHORiN-KiWATA/proton-wrapper
# Arch AUR: shorin-proton-wrapper-git
#
# ⚠️ 打包要点：
# - shorin-proton-wrapper-manager 是 python3 + PyGObject(GTK) 脚本，直接装会
#   「打不开」（NixOS PATH 无 python3/GTK 绑定）→ 手写 wrapper 内联环境
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

  # ── GTK4 动态库（typelib 加载后 dlopen libgtk-4.so 需要）──
  gtkLibPkgs = [
    pkgs.gtk4 pkgs.cairo pkgs.pango pkgs.glib pkgs.gdk-pixbuf
    pkgs.harfbuzz pkgs.fribidi pkgs.libthai pkgs.graphene
  ];
  giLibPath = pkgs.lib.concatStringsSep ":" (
    map (p: allOutputDirs p "lib") gtkLibPkgs
  );

  # ── typelib 搜索路径 ──
  # ⚠️ 核心坑：`${pkg}` 指向包的「第一个输出」，不一定是 out！
  #    pango 的 outputs=[bin out dev] → ${pkgs.pango} = pango-…-bin，typelib 却在 out；
  #    gdk-pixbuf 同理（第一输出是 dev）。必须逐输出遍历（out/bin/dev 全收）。
  # 另：Cairo-1.0.typelib 由 gobject-introspection 包生成（cairo 包不构建
  #   introspection、不带 typelib！见 https://github.com/NixOS/nixpkgs/issues/34080）
  #   graphene 是 Gtk-4.0 typelib 的依赖（Graphene-1.0）
  typelibPkgs = [
    pkgs.gobject-introspection
    pkgs.gtk4 pkgs.cairo pkgs.pango pkgs.glib pkgs.gdk-pixbuf
    pkgs.harfbuzz pkgs.fribidi pkgs.libthai pkgs.graphene
  ];
  allOutputDirs = p: sub: pkgs.lib.concatStringsSep ":" (
    map (o: "${p.${o}}/${sub}") (p.outputs or [ "out" ])
  );
  giTypelibPath = pkgs.lib.concatStringsSep ":" (
    map (p: allOutputDirs p "lib/girepository-1.0") typelibPkgs
  );

  # GTK4 数据目录（schemas/icons/themes）——同样逐输出遍历
  giDataPath = pkgs.lib.concatStringsSep ":" (
    map (p: allOutputDirs p "share") (gtkLibPkgs ++ [ pkgs.gsettings-desktop-schemas ])
  );
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

    # manager（python3 + PyGObject GUI）：手写 wrapper 内联全部环境变量。
    # 不用 makeWrapper：--prefix 对超长冒号列表不可靠（实测只剩最后一项）。
    # 这里由 Nix 构建期直接内联；$PATH/$GI_TYPELIB_PATH/$@ 等运行时变量由 shell 展开。
    install -Dm755 shorin-proton-wrapper-manager "$out/bin/.shorin-proton-wrapper-manager-raw"
    cat > "$out/bin/shorin-proton-wrapper-manager" <<'WRAPPER_EOF'
#! ${pkgs.bash}/bin/bash
export PATH="${runtimePath}:$PATH"
export GI_TYPELIB_PATH="${giTypelibPath}:$GI_TYPELIB_PATH"
export LD_LIBRARY_PATH="${giLibPath}:$LD_LIBRARY_PATH"
export XDG_DATA_DIRS="${giDataPath}:$XDG_DATA_DIRS"
export GSETTINGS_SCHEMA_DIR="${pkgs.gtk4}/share/gsettings-schemas/gtk4-${pkgs.gtk4.version}/glib-2.0/schemas"
exec "${py}/bin/python3" "${builtins.placeholder "out"}/bin/.shorin-proton-wrapper-manager-raw" "$@"
WRAPPER_EOF
    chmod +x "$out/bin/shorin-proton-wrapper-manager"

    install -Dm644 *.desktop -t "$out/share/applications/" 2>/dev/null || true
    # 图标放 hicolor/<size>/apps/（desktop Icon=shorin-proton 才能被主题扫描到）
    [ -d icons ] && cp icons/*.png "$out/share/icons/hicolor/256x256/apps/" 2>/dev/null || true
    runHook postInstall
  '';

  # 调试：nix eval --raw .#shorin-proton-wrapper.giTypelibPath 直接看构建期拼接值
  passthru = { inherit giTypelibPath giLibPath giDataPath; };

  meta = {
    description = "A simple wrapper to run EXEs via Proton";
    homepage    = "https://github.com/SHORiN-KiWATA/proton-wrapper";
    license     = "see https://github.com/SHORiN-KiWATA/proton-wrapper";
    mainProgram = "shorin-proton-wrapper";
    platforms   = pkgs.lib.platforms.linux;
  };
}
