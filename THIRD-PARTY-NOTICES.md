# Third-Party Notices

## NyxNiri

- 上游：https://github.com/ech678/NyxNiri
- 本仓库中来源于 NyxNiri 的移植/衍生内容，继续遵循上游 **GNU GPL v3 (GPL-3.0)**。
- 相关内容包括：
  - `configuration/pkgs/desktop/nyxniri-scratch-menu/`
  - `configuration/home/dotfiles/config/niri/` 中来自 NyxNiri 的配置与脚本
  - `configuration/home/dotfiles/config/fish/conf.d/ATRI.fish` 中明确标注源自 NyxNiri 的部分
  - 其他文件如保留 NyxNiri 原始版权/许可证声明，应以文件自身声明为准。
- 上游完整许可证文本：`THIRD-PARTY-LICENSES/NyxNiri-GPL-3.0.txt`

这个仓库的顶层 `LICENSE` 仅适用于本仓库作者原创的配置、脚本和代码。
仓库中直接分发的第三方文件继续遵循其原始版权和许可证；文件自身已有的 license header 优先。

## MPV / 视频处理

### uosc

- 上游：https://github.com/tomasklaen/uosc
- 本仓库路径：`configuration/home/dotfiles/mpv/scripts/uosc/`
- 许可证：LGPL-2.1-or-later
- 上游许可证文件：`LICENSE.LGPL`

### Anime4K

- 上游：https://github.com/bloc97/Anime4K
- 本仓库路径：`configuration/home/dotfiles/mpv/shaders/Anime4K/`
- 许可证：MIT
- 文件保留原始版权与 MIT 许可文本。

### CuNNy

- 本仓库路径：`configuration/home/dotfiles/mpv/shaders/CuNNy/`
- 许可证：GNU LGPL v3 或更高版本（以文件内原始声明为准）。

### FSRCNNX / RAVU

- FSRCNNX：`configuration/home/dotfiles/mpv/shaders/FSRCNNX/`
- RAVU：`configuration/home/dotfiles/mpv/shaders/RAVU/`
- 许可证：GNU LGPL v3 或更高版本（以文件内原始声明为准）。
- 相关文件保留原始版权与许可证文本。

### Adaptive Sharpen

- 文件：`configuration/home/dotfiles/mpv/shaders/Adaptive_sharpen/Adaptive_sharpen_lite_RT.glsl`
- 文件内保留原作者版权和 2-Clause BSD 风格许可证声明。

## Nautilus 扩展

### Video to Audio

- 文件：`configuration/home/dotfiles/config/nautilus-python/video-to-audio.py`
- 原始作者：Tof
- 许可证：GNU GPL v3（按文件内许可证声明）。
- 该文件不会因为仓库顶层采用 MIT 而转为 MIT。

## 其他第三方内容

部分 Lua、GLSL、Python 或其他资源来源于上游项目或在上游代码基础上修改。
对于仍保留原始版权/许可证头的文件，不应移除这些声明，也不应将其视为顶层 MIT 许可证覆盖的原创代码。

本文件用于说明许可证边界，不替代各第三方项目的完整许可证文本。
使用、再分发或修改具体第三方文件时，应同时遵守对应上游项目的许可证要求。