# 配置踩坑与设计取舍

代码注释只写「这是什么」；本文件记录「为什么这样做」——非显而易见的约束、踩过的坑、
以及将来改动时的注意事项。按主题分组。

---

## 通用原则

- **相对路径**：`configuration/home/*.nix` 里的 `./dotfiles/...` 是相对该文件所在目录；
  `configuration/system/*.nix` 用 `../assets/`、`../../secrets/`。移动文件必须同步改路径。
- **`nixos-generate-config` 生成的 `configuration/device/hardware/hardware-config.nix`
  不要手改**（会被覆盖）；要改写到别处声明。
- **新增文件必须 `git add`**，否则 flake 看不见（flake 只认 git 跟踪文件）。

## Home Manager

### `home.file` vs `home.activation`

- **软链**（`home.file.<path>.source`）指向 store，GC 后旧 store 路径失效 → 断链。
  壁纸这类需要长期存在的文件用 `home.activation.*` **复制成真实文件**。
- **`force = true`**：目标路径已存在普通文件时 HM 默认拒绝覆盖，需要显式声明。
- **目录级 source 不能覆盖已存在目录**（`ln` 语义），即使 `force = true` 也不行 →
  图标这类要逐文件部署。
- 有些路径**故意不部署**，让程序自己生成（否则只读软链挡住写入）：
  - `fish/fish_variables`（fish 运行时写，会 EROFS）
  - `gtk-3.0/settings.ini`（HM `gtk` 模块负责写）
  - `gtk-*/noctalia.css`、`fuzzel/themes/noctalia`（Noctalia 模板生成）

### `home.file` 与 `xdg.configFile` 的键不要混

两个选项的键都是**相对家目录**的路径，规则不同：

| 选项 | 键的相对基准 | 例 |
| --- | --- | --- |
| `home.file` | `$HOME` | `".local/share/applications/qq.desktop"` |
| `xdg.configFile` | `$HOME/.config` | `"mpv/mpv.conf"` |

把 `home.file` 风格的键（以 `.local/`、`.config/` 开头）误写进 `xdg.configFile`
会落到 `~/.config/.local/...`、`~/.config/.config/...`（实测踩过两次），
程序读不到、还留下垃圾目录。改完可用这条自查：

```bash
grep -nE '^\s+"\.' configuration/home/xdg/default.nix   # 应为空
```

### fish 插件

用 `programs.fish.plugins` 声明式管理（原 `fish_plugins` 文件 + fisher 已移除）。
注意选项类型是 `{ name, src }` 列表，**要取 `.src` 而不是直接给包**：

```nix
plugins = [ { name = "autopair"; src = pkgs.fishPlugins.autopair.src; } ];
```

### activation 三兄弟

| 脚本 | 作用 |
| --- | --- |
| `noctaliaV5Seed` | Noctalia V5 需要的可写种子（`niri/effects.kdl` 软链、kitty 主题、config.toml、starship） |
| `wallpaperRealFiles` | 壁纸复制为真实文件（不用软链，见上） |
| `markShotSetup` | mark-shot 的 OCR / 扫码 venv 初始化 |

均只在文件缺失或是 store 链接时执行，不覆盖用户运行期修改。

## 桌面（niri / Noctalia）

- **`prefer-no-csd`**：让窗口放弃客户端装饰 → 鼠标边缘拖拽缩放失效。
  用 `Mod + 右键拖拽` 代替（命中区是窗口的 1/3）。浏览器等自绘 UI 的程序不受影响。
- **`effects.kdl` 是软链**，由 `toggle-eyecare.sh` 在「普通 / 护眼」间切换（`Mod+N`）。
  开机跑一次 `--sync` 对齐状态。
- **niri 26.04 缺 `wp_fifo_manager_v1`**：SDL3 程序会因此回退到 XWayland，
  而 XWayland 下取不到 OpenGL 函数 → 启动即崩。给这类程序设 `SDL_VIDEO_DRIVER=wayland`
  （hmcl / lunarclient 的 wrapper 都这么做）。
- **Noctalia 的 `[backdrop]` 段默认 `enabled = false`**（源码默认值），想开面板背景模糊
  要显式写 `enabled = true`。这是 Noctalia 自身 UI 的模糊，与 niri 的窗口模糊无关。
- **Noctalia 壁纸被插件接管会消失**：mpvpaper 插件会把输出标记为「外部托管」，
  Noctalia 随即销毁自己的壁纸层。若插件被禁用而标记未清（只在内存里），
  图片壁纸不再重建 → 重启 Noctalia 恢复。

## NixOS 系统层

### polkit 与 gvfs

- **polkitd 只扫描系统路径**（`/run/current-system/sw/share/polkit-1/actions`）。
  gvfs 若只装在用户 profile，其 policy（`org.gtk.vfs.file-operations`）读不到 →
  文件管理器访问 `/root` 报 `is not registered`。所以 gvfs 在**系统层**启用。
- 指定 `package = pkgs.gvfs` 而非模块默认的 `pkgs.gnome.gvfs`：两者版本相同但
  store 路径不同，混用会让 GIO 模块与守护进程错配。

### snapper

- 配置键名**全大写**（`SUBVOLUME` / `TIMELINE_*`）；26.05 起旧 camelCase 被静默忽略
  → 快照不生效。
- **`NUMBER_LIMIT = 0` 是「不限量」而不是「不保留」**。配合 `snapshotRootOnBoot`
  会让 boot 快照永不回收（实测堆到 335 个、73G）。
- 清理：`snapper -c root cleanup number` + `cleanup timeline`。
  别用 `du -sh /.snapshots`（btrfs 共享 extent，极慢），看 `btrfs filesystem usage /`。

### 其他

- **`GSETTINGS_SCHEMA_DIR`** 要包含 `gtk3` 与 `gsettings-desktop-schemas` 两者的
  schema 目录（冒号拼接），否则 `gsettings` 查 `org.gnome.desktop.interface` 报
  「没有这个架构」。
- **Docker 绕过主机防火墙**（走 `DOCKER-USER` 链）。要真正隔绝得改成
  `127.0.0.1:host:container` 绑定。
- **Steam 远程游玩 / 专用服务器**需要 `openFirewall = true`，防火墙开启时不加连不上。

## 自建包（`configuration/pkgs/`）

| 包 | 注意 |
| --- | --- |
| `obs-vdoninja` | pin 在 v1.1.63。**v1.1.64+ 要求 libobs 32.2**，本机 OBS 32.1.2 会被
OBS 的版本门（`obs_module_ver`）拒绝加载。产物路径 `lib/obs-plugins` +
`share/obs/obs-plugins` 正好是 `wrapOBS` 期望的布局，所以直接当 plugin 传给
`programs.obs-studio` 即可。 |
| `astral` | bundle 由 `build.sh` **联网构建**到 `~/.cache/astral/bundle`（沙箱内无法
联网编译），经 flake 输入 `astral-bundle` 打包，产物不入 git。装后需手动
`setcap cap_net_admin=ep`（TUN 用），每次升级 core 都要重跑。 |
| `nautilus-extensions` | 图片工具的 `.ui` 是**自维护**的（覆盖上游）：上游用独立
`GtkBox` 拼行导致控件宽度参差，改用 `GtkGrid` + `GtkSizeGroup`。
另外 `GtkDialog` 自身**不能设 margin**——会在窗口边缘留透明带，niri 按
`geometry-corner-radius` 裁剪时圆角处透出壁纸。 |
| `purevox` / `bedrockboot` / `tabby` / `splayer-next` | 都是 AppImage wrap。
`tabby` / `splayer-next` 注意与 nixpkgs 同名包**不是同一个软件**。 |

## 版本 / 升级

- **nixos-26.05 是稳定分支**：`nix flake update` 只带 bugfix 与安全补丁，
  包版本不变（要升版本需切 unstable）。
- **`nix-cachyos-kernel` 用 `?ref=release` 分支**（README 推荐）；master 上的新版本
  需等沉淀到 release。
- 升级 `*.nix` 里 pin 了 `rev` + `sha256` 的自建包时，两者要一起改。

## 常用排障

```bash
# 服务状态
systemctl --user status <unit>        # 用户级（如 kdeconnect）
systemctl status <unit>               # 系统级

# 桌面进程
niri msg layers                       # 检查 layer-shell 层
niri msg --json windows               # 窗口列表

# Noctalia
noctalia msg wallpaper-get            # 当前壁纸
journalctl --user -b | grep -i noctalia

# gvfs / polkit
pkaction --action-id org.gtk.vfs.file-operations   # 应能查到
busctl --user list | grep -i vfs
```
