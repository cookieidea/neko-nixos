# 踩坑与注意事项

## 通用

- 相对路径移动文件后必须同步修改
- `hardware-configuration.nix` 不要手改
- 新增文件必须 `git add`（flake 只认 tracked 文件）

## Home Manager

### home.file vs activation

- 壁纸等长期文件用 `home.activation` 复制真实文件（软链 GC 后会断）
- 目录级 source 无法覆盖已存在目录
- 以下路径故意不部署：`fish_variables`、`gtk-3.0/settings.ini`、Noctalia 模板文件

### xdg.configFile 键

| 选项 | 基准 |
|------|------|
| home.file | $HOME |
| xdg.configFile | $HOME/.config |

误写会导致路径落到 `~/.config/.local/...`。

### fish 插件

```nix
plugins = [ { name = "autopair"; src = pkgs.fishPlugins.autopair.src; } ];
```

## 桌面

- `prefer-no-csd`：用 `Mod+右键拖拽` 缩放窗口
- SDL3 程序需设 `SDL_VIDEO_DRIVER=wayland`（否则崩）
- Noctalia 壁纸被 mpvpaper 接管后需重启恢复

## 系统层

- gvfs 必须装在系统层（polkit 只扫系统路径）
- snapper 键名必须全大写；`NUMBER_LIMIT = 0` 表示不限量
- Docker 会绕过主机防火墙

## 自建包

| 包 | 注意 |
|----|------|
| obs-vdoninja | pin v1.1.63（更高版本要求 libobs 32.2） |
| astral | fetchurl 取上游 Release（含官方 core）；core 由 GUI 管理，TUN 需手动 setcap cap_net_admin |
| nautilus-extensions | .ui 自维护，GtkDialog 不能设 margin |
| tabby / splayer-next | 与 nixpkgs 同名包不同 |

## 排障

```bash
systemctl --user status <unit>
niri msg layers
niri msg --json windows
noctalia msg wallpaper-get
pkaction --action-id org.gtk.vfs.file-operations
```
