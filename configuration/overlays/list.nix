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

    # 0.9.1 起修复重载 AMD GPU 时的 DRI fd 泄漏，pinned 的 nixpkgs 仍是 0.9.0
    (_final: prev: {
      lact = prev.lact.overrideAttrs (old: {
        version = "0.10.1";
        src = prev.fetchFromGitHub {
          owner = "ilya-zlobintsev";
          repo = "LACT";
          tag = "v0.10.1";
          hash = "sha256-e5imWq5+LOySCLAQRNkL6cMznAlaXv24vZuzG8giS7s=";
        };
        cargoDeps = prev.rustPlatform.fetchCargoVendor {
          src = prev.fetchFromGitHub {
            owner = "ilya-zlobintsev";
            repo = "LACT";
            tag = "v0.10.1";
            hash = "sha256-e5imWq5+LOySCLAQRNkL6cMznAlaXv24vZuzG8giS7s=";
          };
          hash = "sha256-KKMWUoJ3QJxwdRm65pj5VyhX9WLe5up1OxFYhmRsgZc=";
        };
        buildInputs = (old.buildInputs or [ ]) ++ [ prev.libdisplay-info ];
        # 只跳过需要挂载 mock fs 的那个测试
        cargoTestFlags = [ "--" "--skip" "tests::apply_settings" ];
      });
    })
]
