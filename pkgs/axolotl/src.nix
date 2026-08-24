# Axolotl —— 官方源码构建（vendored 自上游 PR #298 bfmhno3 的 nix/package.nix）
#
# 源码固定官方仓库 v1.8.9 tag（rev = 3743063...），含 cubiomes 子模块。
# 三段式构建：
#   1. unwrapped：rustPlatform.buildRustPackage —— Rust/Tauri 核心 + pnpm 前端
#      （apps/app-frontend，Vue3+Vite+turbo）+ Java 引擎（packages/app-lib/java，
#      gradle.fetchDeps mitmCache 预下载依赖）。
#   2. symlinkJoin + wrapGAppsHook3：注入 runtimeDependencies（GPU 驱动、
#      X11 库、glibc、flite、alsa/jack/pulse/pipewire、udev）与 PATH
#      （jdk8/17/21/25 + xrandr/xdg-utils）。
# 环境变量包装见 default.nix。
#
# ⚠️ 升级：改下方 src.rev + 重算 src.sha256（git ls-remote 查 tag SHA，
#   nix build 报错给实际 hash）；Cargo.lock 若变 cargoHash 同理；pnpm-lock
#   变化时重算 pnpmDeps.hash。
{ pkgs, rustToolchain }:

let
  inherit (pkgs) lib;

  frontendPackage = builtins.fromJSON (builtins.readFile "${src}/apps/app-frontend/package.json");

  # 上游 frontend package.json 版本号滞后于 tag（v1.8.9 仍是 1.8.1），
  # 这里统一以实际 tag 版本为准：包名 / tauri.conf.json（About 页）都显示 1.8.9
  launcherVersion = "1.8.9";

  # Mojang 自带 JRE 的 java.awt（ModernUI 初始化字体时触发）找不到
  # fontconfig.properties → "Fontconfig head is null" 崩溃。
  # 提供最小 Java 格式的 fontconfig 配置，指向 NixOS store 里的 DejaVu 字体，
  # 通过 JAVA_TOOL_OPTIONS 的 -Dsun.font.fontconfig 传给游戏 JVM。
  fontconfigProperties = pkgs.writeText "fontconfig.properties" ''
    # Minimal fontconfig.properties for Mojang JRE on NixOS
    version=1
    componentFontMappings=serif-plain-latin-1:DejaVu_Serif,serif-bold-latin-1:DejaVu_Serif_Bold,serif-italic-latin-1:DejaVu_Serif_Italic,serif-bolditalic-latin-1:DejaVu_Serif_Bold_Italic,sansserif-plain-latin-1:DejaVu_Sans,sansserif-bold-latin-1:DejaVu_Sans_Bold,sansserif-italic-latin-1:DejaVu_Sans_Italic,sansserif-bolditalic-latin-1:DejaVu_Sans_Bold_Italic,monospaced-plain-latin-1:DejaVu_Sans_Mono,monospaced-bold-latin-1:DejaVu_Sans_Mono_Bold,monospaced-italic-latin-1:DejaVu_Sans_Mono_Italic,monospaced-bolditalic-latin-1:DejaVu_Sans_Mono_Bold_Italic,dialog-plain-latin-1:DejaVu_Sans,dialog-bold-latin-1:DejaVu_Sans_Bold,dialog-italic-latin-1:DejaVu_Sans_Italic,dialog-bolditalic-latin-1:DejaVu_Sans_Bold_Italic,dialoginput-plain-latin-1:DejaVu_Sans_Mono,dialoginput-bold-latin-1:DejaVu_Sans_Mono_Bold,dialoginput-italic-latin-1:DejaVu_Sans_Mono_Italic,dialoginput-bolditalic-latin-1:DejaVu_Sans_Mono_Bold_Italic
    sequence.allfonts=latin-1
    filename.DejaVu_Sans=${pkgs.dejavu_fonts}/share/fonts/truetype/DejaVuSans.ttf
    filename.DejaVu_Serif=${pkgs.dejavu_fonts}/share/fonts/truetype/DejaVuSerif.ttf
    filename.DejaVu_Sans_Mono=${pkgs.dejavu_fonts}/share/fonts/truetype/DejaVuSansMono.ttf
    filename.DejaVu_Sans_Bold=${pkgs.dejavu_fonts}/share/fonts/truetype/DejaVuSans-Bold.ttf
    filename.DejaVu_Serif_Bold=${pkgs.dejavu_fonts}/share/fonts/truetype/DejaVuSerif-Bold.ttf
    filename.DejaVu_Sans_Mono_Bold=${pkgs.dejavu_fonts}/share/fonts/truetype/DejaVuSansMono-Bold.ttf
    filename.DejaVu_Sans_Italic=${pkgs.dejavu_fonts}/share/fonts/truetype/DejaVuSans-Oblique.ttf
    filename.DejaVu_Serif_Italic=${pkgs.dejavu_fonts}/share/fonts/truetype/DejaVuSerif-Italic.ttf
    filename.DejaVu_Sans_Mono_Italic=${pkgs.dejavu_fonts}/share/fonts/truetype/DejaVuSansMono-Oblique.ttf
    filename.DejaVu_Sans_Bold_Italic=${pkgs.dejavu_fonts}/share/fonts/truetype/DejaVuSans-BoldOblique.ttf
    filename.DejaVu_Serif_Bold_Italic=${pkgs.dejavu_fonts}/share/fonts/truetype/DejaVuSerif-BoldItalic.ttf
    filename.DejaVu_Sans_Mono_Bold_Italic=${pkgs.dejavu_fonts}/share/fonts/truetype/DejaVuSansMono-BoldOblique.ttf
  '';

  rustPlatform = pkgs.makeRustPlatform {
    cargo = rustToolchain;
    rustc = rustToolchain;
  };

  pnpm = pkgs.pnpm_10.overrideAttrs (_: rec {
    version = "10.33.2";
    src = pkgs.fetchurl {
      url = "https://registry.npmjs.org/pnpm/-/pnpm-${version}.tgz";
      hash = "sha512-qQ+vb+6rca1sblf5Tg/hoS9dzCLNdU20CulZPraj4LaxLjVAIYuzeuCDQEsfLObbKkEh6XmCm0r/lLmfSdoc+A==";
    };
  });

  # 官方仓库 v1.8.9（tag SHA，`git ls-remote --tags` 查询）
  src = pkgs.fetchFromGitHub {
    owner = "Mystic-Stars";
    repo = "Axolotl";
    rev = "3743063b1b2dede811bf5dae88c0d1ff37741abd";
    sha256 = "sha256-5wrC/A4A/oQR5+TH55R3N91k01HwgZjOFxQgcFV31rs=";
    fetchSubmodules = true;
  };

  gradle = pkgs.gradle_9.override { java = pkgs.jdk17; };
  gradleExe =
    pkgs.runCommand "gradle-exe-wrapper-${gradle.version}" { nativeBuildInputs = [ pkgs.makeShellWrapper ]; }
      ''
        makeShellWrapper ${lib.getExe gradle} $out \
          --add-flags "\''${NIX_GRADLEFLAGS_COMPILE:-}"
      '';

  unwrapped = rustPlatform.buildRustPackage (finalAttrs: {
    pname = "axolotl-launcher-unwrapped";
    version = launcherVersion;
    inherit src;

    patches = [
      (pkgs.replaceVars ./gradle-from-path.patch {
        gradle = gradleExe;
      })
    ];

    postPatch = ''
      test -f apps/app-frontend/src/data/about/contributors.json
      substituteInPlace apps/app-frontend/package.json \
        --replace-fail \
          'pnpm contributors:sync && vue-tsc --noEmit && vite build' \
          'vue-tsc --noEmit && vite build'
      # 上游未随 tag 同步 frontend 版本号（v1.8.9 的 package.json 仍是 1.8.1）→
      # 替换为实际 tag 版本，使 tauri.conf.json（About 页 getVersion）一致
      substituteInPlace apps/app-frontend/package.json \
        --replace-fail '"version": "${frontendPackage.version}"' '"version": "${launcherVersion}"'
    '';

    cargoHash = "sha256-KzX4hyUQXltDEEGyCIyUgQ7nWAm78lhk8YkPJhHZOmA=";

    # 跳过 cargo test（checkPhase 约 3.5 分钟），加速每次源码升级的增量构建
    doCheck = false;

    mitmCache = gradle.fetchDeps {
      pkg = finalAttrs.finalPackage;
      inherit (finalAttrs) pname;
      attrPath = null;
      data = ./gradle-deps.json;
    };

    pnpmDeps = pkgs.fetchPnpmDeps {
      inherit (finalAttrs) pname src;
      inherit pnpm;
      fetcherVersion = 4;
      hash = "sha256-/eX/Vir0xTI/SLs1nh1X8T3sYgSiVg/qLI/n8M/+1i8=";
    };

    nativeBuildInputs = [
      pkgs.cacert
      pkgs.cargo-tauri.hook
      pkgs.desktop-file-utils
      gradle
      pkgs.jdk17
      pkgs.nodejs
      pkgs.patchelf
      pkgs.pkg-config
      pnpm
      pkgs.pnpmConfigHook
    ];

    buildInputs = [
      pkgs.glib-networking
      pkgs.libayatana-appindicator
      pkgs.librsvg
      pkgs.openssl
      pkgs.webkitgtk_4_1
    ];

    gradleFlags = [
      "-Dfile.encoding=utf-8"
      "--no-configuration-cache"
      "-x"
      "spotlessJava"
    ];
    dontUseGradleBuild = true;
    dontUseGradleCheck = true;

    cargoTestFlags = [
      "--package"
      "theseus_gui"
    ];

    env.TURBO_BINARY_PATH = lib.getExe pkgs.turbo;

    preGradleUpdate = ''
      cd packages/app-lib/java
    '';
    gradleUpdateTask = "nixDownloadDeps authlibInjector";

    preBuild = ''
      local nixGradleFlags=()
      concatTo nixGradleFlags gradleFlags gradleFlagsArray
      export NIX_GRADLEFLAGS_COMPILE="''${nixGradleFlags[@]}"
    '';

    passthru = {
      gradle-deps-update = unwrapped.mitmCache.updateScript;
    };

    meta = {
      description = "Cross-platform Minecraft launcher from Axolotl Launcher";
      homepage = "https://www.axlmc.org";
      license = lib.licenses.gpl3Only;
      mainProgram = "Axolotl Launcher";
      platforms = lib.platforms.linux;
      sourceProvenance = with lib.sourceTypes; [
        fromSource
        binaryBytecode
      ];
    };
  });

  jdks = [
    pkgs.jdk8
    pkgs.jdk17
    pkgs.jdk21
    pkgs.jdk25
  ];

  packaged = pkgs.symlinkJoin {
    pname = "axolotl-launcher";
    inherit (unwrapped) version;

    paths = [ unwrapped ];
    strictDeps = true;

    nativeBuildInputs = [
      pkgs.glib
      pkgs.wrapGAppsHook3
    ];

    buildInputs = [
      pkgs.glib-networking
      pkgs.gsettings-desktop-schemas
    ];

    runtimeDependencies = lib.makeLibraryPath [
      pkgs.addDriverRunpath.driverLink
      pkgs.libGL
      pkgs.libx11
      pkgs.libxcursor
      pkgs.libxext
      pkgs.libxrandr
      pkgs.libxxf86vm
      (lib.getLib pkgs.stdenv.cc.cc)
      pkgs.flite
      # 游戏 JVM 的 Mojang 自带 JRE libfontmanager.so 依赖系统 libfreetype.so.6
      # （RPATH=$ORIGIN 只在 JRE lib/ 内找，而 JRE 不捆绑 freetype）→ 必须暴露在
      # LD_LIBRARY_PATH，否则 ModernUI 初始化 java.awt 字体时 UnsatisfiedLinkError 崩溃。
      pkgs.freetype
      # libawt_xawt.so 需要 X11 渲染库（libXrender/libXtst/libXi），否则 java.awt
      # X11 字体管理器 UnsatisfiedLinkError
      pkgs.libxrender
      pkgs.libxtst
      pkgs.libxi
      pkgs.dejavu_fonts
      pkgs.alsa-lib
      pkgs.libjack2
      pkgs.libpulseaudio
      pkgs.pipewire
      pkgs.udev
    ];

    postBuild = ''
      gappsWrapperArgs+=(
        --prefix PATH : ${lib.makeSearchPath "bin/java" jdks}
        --prefix PATH : ${
          lib.makeBinPath [
            pkgs.xrandr
            pkgs.xdg-utils
          ]
        }
        --set LD_LIBRARY_PATH $runtimeDependencies
        # 启动器/游戏所需环境（niri 下）：
        #   SDL 强制原生 Wayland（niri 缺 fifo-v1，SDL 默认回退 XWayland）
        --set SDL_VIDEO_DRIVER wayland
        #   radeonsi 下 WebKit DMABUF/合成路径崩 → 强制软件合成（仅 WebKit）
        --set WEBKIT_DISABLE_COMPOSITING_MODE 1
        --set WEBKIT_DISABLE_DMABUF_RENDERER 1
        #   Theseus 重置游戏 LD_LIBRARY_PATH，JVM 属性独立生效 → flite 可寻址
        --set JAVA_TOOL_OPTIONS "-Djna.library.path=${pkgs.flite}/lib -Dsun.font.fontconfig=${fontconfigProperties}"
      )

      glibPostInstallHook
      gappsWrapperArgsHook
      wrapGApp "$out/bin/Axolotl Launcher"
    '';

    passthru = {
      inherit unwrapped;
      gradle-deps-update = unwrapped.mitmCache.updateScript;
    };
  };
in
packaged
