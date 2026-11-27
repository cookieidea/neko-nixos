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

  # 给两个 obs 插件补上游缺失的 zh-CN 翻译。
  (_final: prev: {
    obs-studio-plugins = prev.obs-studio-plugins // {
      obs-pipewire-audio-capture =
        prev.obs-studio-plugins.obs-pipewire-audio-capture.overrideAttrs
          (old: {
            postInstall = (old.postInstall or "") + ''
              install -Dm644 ${../pkgs/media/obs-plugin-locales/pipewire-audio.zh-CN.ini} \
                $out/share/obs/obs-plugins/linux-pipewire-audio/locale/zh-CN.ini
            '';
          });
      obs-vkcapture = prev.obs-studio-plugins.obs-vkcapture.overrideAttrs (old: {
        postInstall = (old.postInstall or "") + ''
          install -Dm644 ${../pkgs/media/obs-plugin-locales/vkcapture.zh-CN.ini} \
            $out/share/obs/obs-plugins/linux-vkcapture/locale/zh-CN.ini
        '';
      });
    };
  })

  # 微信：nixpkgs 的 wechat 先校验上游 deb 的 crc/version-id，不匹配才回退
  # web.archive.org 的存档。腾讯已把 4.1.13.26 换成 4.1.13.29，导致退到
  # archive.org；而 archive.org 对本机 IP 段限流（429），构建直接失败。
  #
  # 这里直接指向腾讯原始地址并配上实际哈希（4.1.13.29）。等 nixpkgs 自己
  # 更新到新版（届时 crc 校验会重新匹配上游）就可以删掉这段 override。
  (_final: prev: {
    wechat = prev.wechat.overrideAttrs (_old: {
      src = prev.fetchurl {
        url = "https://dldir1v6.qq.com/weixin/Universal/Linux/WeChatLinux_x86_64.deb";
        hash = "sha256-1bIcbiEYaliywv1BcSpO+Q+UUnNZMaa4UA6FxbCROws=";
      };
    });
  })
]
