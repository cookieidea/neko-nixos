# BedrockBoot —— 我的世界基岩版（Minecraft Bedrock）启动器
#
# Round-Studio/BedrockBoot（Avalonia UI / .NET 跨平台）
# 功能：游戏实例管理、微软/Xbox 账户登录、联机（Gravitycone/PaperConnect）、
#       CurseForge 资源、配置同步、主题自定义。
# 发布：GitHub Releases 自动构建，Linux 资产为 AppImage。
#
# 打包：appimageTools.extract 解包 + buildFHSEnv（同 purevox 方案）+ mkDerivation
#   - AppImage 捆绑应用运行时（.NET/ICU 等）自包含，原版 AppRun 直接用
#     （purevox 的 wrapType2 AppRun 修复不生效问题在此不适用——不改 AppRun）。
#   - buildFHSEnv 提供 FHS 结构（/lib64/ld-linux 等）+ 宿主依赖库兜底，
#     ld.so.cache 自动生成，dlopen 直接命中。
#   - buildFHSEnv 产物只有 bin/，无 desktop/图标 → mkDerivation 补
#     $out/share/applications + pixmaps（freedesktop 标准路径，应用列表可见）。
#
# ⚠️ 更新：CI 自动发版（tag 形如 v2.1.10.96），升级改 version + 下方 sha256。
{ pkgs }:

let
  version = "2.1.10.96";

  src = pkgs.fetchurl {
    url = "https://github.com/Round-Studio/BedrockBoot/releases/download/v${version}/BedrockBoot-x86_64-linux.AppImage";
    sha256 = "3729d04efc5531d73e06d2bb23ff053f35e498be999c825ba042474f8a55c525";
  };

  extracted = pkgs.appimageTools.extract {
    pname = "bedrockboot";
    inherit version src;
  };

  fhsEnv = pkgs.buildFHSEnv {
    name = "bedrockboot";
    runScript = "${extracted}/AppRun";

    targetPkgs = pkgs: [
      # 基础 C 库
      pkgs.glibc
      pkgs.stdenv.cc.cc.lib            # libstdc++
      pkgs.zlib
      pkgs.openssl
      pkgs.icu                          # .NET ICU
      # 图形 / 字体 / X11 / Wayland（Avalonia 渲染）
      pkgs.fontconfig
      pkgs.freetype
      pkgs.libx11
      pkgs.libxext
      pkgs.libxcb
      pkgs.libxkbcommon
      pkgs.wayland
      pkgs.libGL
      pkgs.dbus
      pkgs.glib
      pkgs.gsettings-desktop-schemas
    ];
  };
in
pkgs.stdenv.mkDerivation {
  pname = "bedrockboot";
  inherit version;
  src = extracted;   # 解包内容（找图标用）

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin $out/share/applications $out/share/pixmaps
    ln -s ${fhsEnv}/bin/bedrockboot $out/bin/bedrockboot

    # 图标：从解包产物找（AppImage 内 usr/share/icons 或根目录 .png）
    icon=$(find . -path "*icons*" -name "*.png" 2>/dev/null | head -1)
    [ -n "$icon" ] && cp "$icon" "$out/share/pixmaps/bedrockboot.png" || true

    cat > $out/share/applications/bedrockboot.desktop <<EOF
[Desktop Entry]
Type=Application
Name=BedrockBoot
Name[zh_CN]=BedrockBoot 基岩启动器
Comment=Minecraft Bedrock 版启动器（Avalonia UI；实例/账户/联机/CurseForge）
Exec=bedrockboot
Icon=bedrockboot
Terminal=false
Categories=Game;Utility;
EOF
    runHook postInstall
  '';

  meta = with pkgs.lib; {
    description = "Minecraft Bedrock 版启动器（Avalonia UI；实例/账户/联机/CurseForge）";
    homepage = "https://github.com/Round-Studio/BedrockBoot";
    license = licenses.unfreeRedistributable;
    mainProgram = "bedrockboot";
    platforms = platforms.linux;
  };
}
