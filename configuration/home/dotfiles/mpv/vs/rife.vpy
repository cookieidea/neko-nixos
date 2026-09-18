import os
import vapoursynth as vs
import k7sfunc

# Nix 的 VapourSynth 包不扫描额外插件目录；显式加载 RIFE 依赖。
plugin_dir = os.environ["VAPOURSYNTH_EXTRA_PLUGIN_PATH"].split(":")[0]
for name in ("libvslsmashsource.so", "libakarin.so", "librife.so", "libmvtools.so"):
    vs.core.std.LoadPlugin(path=os.path.join(plugin_dir, name))

# AMD 路径：RIFE-ncnn-Vulkan，直接使用 RADV；不依赖 Windows DirectML/ONNX。
# 模型：23(v4.6) / 70(v4.25 lite) / 72(v4.26) / 73(v4.26 heavy)。
model = 23
turbo = 1
fnum = 2
fden = 1
sc_mode = 1
gpu = 0
gpu_t = 1

# mpv 的 vapoursynth vf 会预置 clip。
clip = k7sfunc.RIFE_STD(clip, model, turbo, fnum, fden, sc_mode, 60.0, gpu, gpu_t)
clip.set_output()
