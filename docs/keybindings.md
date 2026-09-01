# 快捷键速查（niri + Noctalia + 应用）

> `Mod` = **Super / Win 键**（桌面徽标键）。
> 来源：`dotfiles/config/niri/binds.kdl` + fcitx5 配置。
> 按 `Mod+Shift+/` 可查看 niri 内置的快捷键教程浮层。

## 应用 / 启动

| 快捷键 | 功能 |
|---|---|
| `Mod+Return` | 独立终端（kitty） |
| `Mod+T` | 共享终端（kitty --single-instance） |
| `Mod+/` | 临时浮动终端（kitty quickterminal） |
| `Mod+Alt+O` | **opencode AI 助手**（kitty 内打开） |
| `Mod+B` | 浏览器（google-chrome） |
| `Mod+E` | 文件管理器（thunar，缺则 nautilus） |
| `Mod+Alt+E` | nautilus（强制） |
| `Mod+Z` | 程序菜单（noctalia launcher，失败回退 fuzzel） |
| `Alt+Tab` | 窗口切换器（noctalia windows launcher） |
| `Mod+F1` | 开关输入法（重启 fcitx5） |
| `Mod+F2` | 设置面板（noctalia settings） |

## 窗口：聚焦

| 快捷键 | 功能 |
|---|---|
| `Mod+←/→`、`Mod+H/L` | 聚焦左/右列 |
| `Mod+↑/↓`、`Mod+K/J` | 聚焦上/下窗口 |
| `Mod+W/S` | 聚焦上/下窗口（备用） |
| `Mod+Home/End` | 聚焦第一/最后一列 |
| `Mod+PageUp/PageDown`、`Mod+U/I` | 聚焦上/下工作区 |
| `Mod+鼠标前/后侧键` | 聚焦上/下窗口 |

## 窗口：移动 / 尺寸 / 布局

| 快捷键 | 功能 |
|---|---|
| `Mod+Ctrl+←/→`、`Mod+Ctrl+H/L`、`Mod+Ctrl+A/D` | 向左/右移动列 |
| `Mod+Ctrl+↑/↓`、`Mod+Ctrl+K/J`、`Mod+Ctrl+W/S` | 向上/下移动窗口 |
| `Mod+Ctrl+Home/End` | 列移到最前/最后 |
| `Mod+A/D`、`Mod+[` / `Mod+]` | 窗口跨列左移/右移（consume/expel） |
| `Mod+,` / `Mod+.`、`Mod+Shift+A/D` | 窗口并入/踢出当前列 |
| `Mod+Shift+X` | 列标签页模式 |
| `Mod+R` / `Mod+Shift+R` / `Mod+Ctrl+R` | 预设列宽 / 预设窗高 / 重置窗高 |
| `Mod+-` / `Mod+=` | 列宽 -5% / +5% |
| `Mod+Shift+-` / `Mod+Shift+=` | 窗高 -5% / +5% |
| `Mod+F` / `Mod+Alt+F` | 最大化列 / 全屏窗口 |
| `Mod+Ctrl+F` | 列扩展到可用宽度 |
| `Mod+C` / `Mod+Ctrl+C` | 居中当前列 / 居中所有可见列 |
| `Mod+V` / `Mod+Shift+V`、`Mod+N`、`Alt+\`` | 切换浮动 / 浮动-平铺间切换聚焦 |

## 窗口：关闭 / 其他

| 快捷键 | 功能 |
|---|---|
| `Mod+Q` | 关闭聚焦窗口 |
| `Alt+F4` | 强制杀窗口（-9） |
| `Alt+Shift+F4` | 强杀窗口及其进程树 |
| `Mod+鼠标中键` | 关闭窗口 |
| `Mod+Escape` | 切换快捷键抑制（临时禁用自身绑定） |

## 工作区

| 快捷键 | 功能 |
|---|---|
| `Mod+1` ~ `Mod+9` | 切换到数字工作区 |
| `Mod+Ctrl+1` ~ `Mod+Ctrl+9` | 移动当前列到数字工作区 |
| `Mod+Shift+WheelDown/Up` | 滚动切换上/下工作区 |
| `Mod+Ctrl+Shift+WheelDown/Up` | 移动列到上/下工作区 |
| `Mod+Shift+PageUp/PageDown`、`Mod+Shift+U/I` | 整体移动工作区 |

## 多显示器

| 快捷键 | 功能 |
|---|---|
| `Mod+Shift+方向键` / `Mod+Shift+H/J/K/L` | 聚焦左/下/上/右显示器 |
| `Mod+Ctrl+Shift+方向键`（+`H/J/K/L/A/S/W/D`） | 移动列到左/下/上/右显示器 |
| `Mod+Shift+Alt+方向键`（+`H/J/K/L/A/S/W/D`） | 移动整个工作区到相邻显示器 |

## 截图

| 快捷键 | 功能 |
|---|---|
| `Print` / `Mod+Alt+A` | 选取区域截图 |
| `Ctrl+Print` / `Mod+Alt+Ctrl+A` | 截取聚焦窗口 |
| `Shift+Print` / `Mod+Alt+Ctrl+Shift+A` | 截取整个显示器 |
| `Mod+Shift+S` | 用 satty 编辑剪贴板图片（截图后调用） |

## 系统 / 会话

| 快捷键 | 功能 |
|---|---|
| `Mod+Shift+E` | 退出 niri |
| `Mod+Shift+P` | 电源菜单（noctalia sessionMenu） |
| `Mod+Alt+L` | 锁屏 |
| `Mod+Alt+P` | 挂起（关显示器 + 锁屏 + suspend） |
| `Mod+O` / `Mod+G` | 切换总览界面 |
| `Mod+P` | 提取窗口信息（niri-pick） |

## 桌面（Noctalia）

| 快捷键 | 功能 |
|---|---|
| `Mod+Alt+W` | 壁纸选择（toggle） |
| `Mod+F10` | 随机切换壁纸 |
| `Mod+Shift+F10` | 随机下载壁纸（anime 脚本） |
| `Mod+Alt+V` | 剪贴板历史（launcher clipboard） |
| `Mod+Alt+S` / `Mod+M` | 收起窗口到侧边栏（niri-sidebar） |
| `Mod+Alt+Z` | 展开/收起侧边栏 |
| `Mod+Alt+X` | 侧边栏反向排序 |
| `Mod+Alt+R` | 重置侧边栏排列 |
| `Mod+F3` | 录屏菜单 |
| `Mod+F5` / `Mod+F8` | 快速存档 / 快速读档 |

## 媒体 / 硬件

| 快捷键 | 功能 |
|---|---|
| `XF86AudioRaiseVolume`（音量+） | 音量增加 |
| `XF86AudioLowerVolume`（音量-） | 音量降低 |
| `XF86AudioMute`（静音键） | 静音 |
| `XF86MonBrightnessUp` / `Down`（亮度键） | 亮度增/减 |

## 鼠标 / 滚轮

| 操作 | 功能 |
|---|---|
| `Mod+滚轮上/下` | 聚焦左/右列 |
| `Mod+Ctrl+滚轮上/下` | 移动列左/右 |
| `Mod+Shift+滚轮上/下` | 切换工作区 |
| `Mod+Ctrl+Shift+滚轮上/下` | 移动列到上/下工作区 |
| `Mod+鼠标中键` | 关闭窗口 |
| `Mod+鼠标前/后侧键` | 聚焦上/下窗口 |

## 应用内（fcitx5 输入法）

| 快捷键 | 功能 |
|---|---|
| `Ctrl+Space` | 激活 / 切换输入法（fcitx5 默认） |
| `Ctrl+Shift+F` | 简繁切换（chttrans） |
| `Ctrl+.` | 中英文标点切换（punctuation） |

> fcitx5 更多快捷键（候选翻页等）可在 `fcitx5-configtool` → 全局配置中查看/自定义。
