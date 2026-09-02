{ lib, stdenv, autoPatchelfHook, fetchurl, p7zip, libgcc, gcc-unwrapped, vulkan-loader, vapoursynth }:

stdenv.mkDerivation rec {
  pname = "vapoursynth-rife-ncnn";
  version = "r9-mod-v33";

  # 预编译插件（ncnn+Vulkan 静态链接，仅依赖 libgomp/libstdc++，运行期 dlopen libvulkan）
  plugin = fetchurl {
    url = "https://github.com/styler00dollar/VapourSynth-RIFE-ncnn-Vulkan/releases/download/${version}/librife_linux_x86-64.so";
    hash = "sha256-GKAKXjrJCl38/fhf24HZdzgaWiVgpMRdvppGnQB7GIY=";
  };

  models = fetchurl {
    url = "https://github.com/cookieidea/vs-models/releases/download/rife-std-v1/vs-k7sfunc.0_6_3.rife_std-core_models.7z";
    hash = "sha256-Vdb6aZMI253BtAP/TH5NPvB05Weg/rP2FEl9IHjvWb8=";
  };

  nativeBuildInputs = [ autoPatchelfHook p7zip ];
  buildInputs = [ stdenv.cc.cc.lib gcc-unwrapped.lib vulkan-loader ];
  sourceRoot = ".";

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/vapoursynth $out/models
    cp ${plugin} $out/lib/vapoursynth/librife.so
    chmod +w $out/lib/vapoursynth/librife.so
    7z x -y ${models} -o$out/models >/dev/null
    runHook postInstall
  '';

  meta = with lib; {
    description = "RIFE VapourSynth plugin (ncnn + Vulkan; AMD works)";
    homepage = "https://github.com/styler00dollar/VapourSynth-RIFE-ncnn-Vulkan";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
# vs plugins for RIFE interpolation
