# Nautilus Image Converter（GTK4 增强版）
# 右键缩放/旋转/转格式（WebP/PNG/JPEG/AVIF/GIF/PDF）/按目标大小压缩/合并 PDF
# https://github.com/Ameen-Sha-Cheerangan/nautilus-image-converter-gnome43plus
{ pkgs }:
pkgs.stdenv.mkDerivation rec {
  pname = "nautilus-image-converter";
  version = "0.5.0";

  src = pkgs.fetchFromGitHub {
    owner = "Ameen-Sha-Cheerangan";
    repo = "nautilus-image-converter-gnome43plus";
    rev = "e834b762f662a2e62131ca188cbf98e6ab04679d";
    hash = "sha256-4QfXKAwZXzJNHT4oFEbFf9dLjI0PE0FI1MwHYu/Rh7k=";
  };

  nativeBuildInputs = with pkgs; [
    meson
    ninja
    pkg-config
    gettext
  ];

  buildInputs = with pkgs; [
    gtk4
    glib
    nautilus
  ];

  # extensiondir 由 pkg-config 提供（指向 nautilus 包 store 路径），覆盖到 $out
  postPatch = ''
    substituteInPlace meson.build --replace-fail \
      "nautilus_extension_dir = libnautilus_extension.get_pkgconfig_variable('extensiondir')" \
      "nautilus_extension_dir = join_paths(get_option('prefix'), 'lib', 'nautilus', 'extensions-4')"
  '';

  # 安装中文翻译（.po → .mo 编译后注入）
  postInstall = ''
    mkdir -p $out/share/locale/zh_CN/LC_MESSAGES
    msgfmt -o $out/share/locale/zh_CN/LC_MESSAGES/nautilus-image-converter.mo \
      ${./zh_CN.po}
  '';

  meta = with pkgs.lib; {
    description = "Nautilus extension to resize, rotate, convert and compress images (GTK4)";
    homepage = "https://github.com/Ameen-Sha-Cheerangan/nautilus-image-converter-gnome43plus";
    license = licenses.gpl2Plus;
    platforms = platforms.linux;
  };
}
