  # nixpkgs overlays 列表，flake 与 NixOS 模块共用。
{ nix-cachyos-kernel }:

[
  # CachyOS RT-BORE 内核。用上游 pinned overlay 才能命中其二进制缓存；
  # 该 input 刻意不 follows nixpkgs（见 flake.nix 注释）。
  nix-cachyos-kernel.overlays.pinned

  # 覆盖 neovim 的 nvim.desktop：
  # 上游为 Terminal=true，图形启动器点不开（freedesktop 规范下会尝试在终端
  # 里跑 GUI 程序）。改为 kitty 打开，MimeType 与用户级覆盖保持一致。
  (_final: prev: {
    neovim = prev.neovim.overrideAttrs (old: {
      postInstall = (old.postInstall or "") + ''
        rm -f "$out/share/applications/nvim.desktop"
        cat > "$out/share/applications/nvim.desktop" <<'DESKTOP'
[Desktop Entry]
Name=Neovim wrapper
GenericName=Text Editor
Comment=Edit text files
TryExec=nvim
Exec=kitty -e nvim %F
Icon=nvim
Type=Application
Terminal=false
Categories=Utility;TextEditor;Development;
MimeType=text/plain;text/x-makefile;application/x-shellscript;text/x-c;text/x-c++src;
StartupNotify=false
DESKTOP
      '';
    });
  })

  # terracotta（hmcl 的依赖）构建时 zstd-sys 要探测 pkg-config 和 libzstd，
  # 上游该版本两者都没给，补上。
  (_final: prev: {
    terracotta = prev.terracotta.overrideAttrs (old: {
      nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ prev.pkg-config ];
      buildInputs = (old.buildInputs or [ ]) ++ [ prev.zstd ];
    });
  })

  # splayer-next 的 Rust 依赖 aws-lc-sys 在 nixpkgs 的 cargo-setup-hook 里
  # 被强制走系统库（AWS_LC_SYS_USE_SYSTEM=1），但包本身没提供 aws-lc，
  # 补上即可正常构建。
  (_final: prev: {
    splayer-next = prev.splayer-next.overrideAttrs (old: {
      buildInputs = (old.buildInputs or [ ]) ++ [ prev.aws-lc ];
    });
  })
]
