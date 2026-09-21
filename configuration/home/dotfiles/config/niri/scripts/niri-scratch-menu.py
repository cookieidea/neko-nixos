#!/usr/bin/env python3
"""
NyxNiri Scratchpad Star-Ring Menu (星环菜单)
Architecture: Material 3 Expressive (Android Gemini M3E) · 100% Stateless & On-Demand (Zero Daemons)

Core Design Principles:
- 100% Stateless On-Demand Execution: Zero background daemons, zero lingering memory, exits instantly when closed.
- Multi-source Declarative Configuration (Priority: TOML -> JSON -> Built-in Defaults)
- Android Gemini Chubby Search Hub: 390px × 64px plush pill with 32px stadium curve and 44px circular engine avatar island.
- Curated Tier-1 Suite: Bing, Google, DeepSeek, ChatGPT, Claude.
- Zero-Noise Atmosphere: Outer capsules seamlessly dissolve to 0% opacity during search, leaving 100% focus.
- Pure Minimalism: Zero bottom hints, crisp 13.5pt typography, subtle ambient aura.
- Forgiving Navigation: Right-click inside search mode smoothly returns to star-ring instead of quitting.
- Exact Native IME Alignment: Integrated Gdk.Rectangle cursor location tracking for Fcitx5/IBus popups.
- Deterministic Click & Spatial Keyboard Navigation (Zero external threads)
- 100% Native GTK/Wayland Layer-Shell event-driven execution (0% CPU at idle)
- Precision Polar Voronoi Sector Partitioning (48px deadzone & ±6° hysteresis)
- Analytical Second-Order Spring Dynamics Matrix (Exact differential solver)
- Hierarchical Submenu Tree (Drill-down & Return transitions with Gravitational Metaphor)
- Optical Subpixel-Centering & Concentric Endcap Alignment (chip_cx = cx_box + ch / 2.0)
- Content-Aware Adaptive Streamline Capsules with Zero-Alloc Pango Layouts
- Wayland Compositor-synced 144Hz+ GdkFrameClock VBLANK rendering
"""

import sys
import os
import math
import json
import subprocess
import signal
import fcntl
import urllib.parse

# 绘制模块按脚本目录显式加载，不走 sys.path import：
# 该文件经 Home Manager 以 symlink 部署，python3 会把 sys.path[0] 设为
# store 中的真实父目录，且文件名含连字符（非合法模块名），常规 import 会失败。
import importlib.util as _ilu

# 注意用 __file__ 而非 realpath(__file__)：HM 把每个文件展平为
# /nix/store/hm_<name>，realpath 后两者的父目录都变成 /nix/store，
# 无法互相定位；symlink 路径的目录才是部署后的真实同目录。
_here = os.path.dirname(os.path.abspath(__file__))
_spec = _ilu.spec_from_file_location(
    "scratch_menu_render", os.path.join(_here, "scratch-menu-render.py")
)
_mod = _ilu.module_from_spec(_spec)
_spec.loader.exec_module(_mod)
RenderMixin = _mod.RenderMixin
BASE_ORBIT_RADIUS = _mod.BASE_ORBIT_RADIUS
DEADZONE_RADIUS = _mod.DEADZONE_RADIUS
FLOAT_SPRING = _mod.FLOAT_SPRING
CAPSULE_IDLE_H = _mod.CAPSULE_IDLE_H
CAPSULE_ACTIVE_H = _mod.CAPSULE_ACTIVE_H

try:
    import tomllib
    HAS_TOMLLIB = True
except ImportError:
    try:
        import tomli as tomllib
        HAS_TOMLLIB = True
    except ImportError:
        HAS_TOMLLIB = False

import gi
gi.require_version('Gtk', '3.0')
gi.require_version('Gdk', '3.0')
gi.require_version('GtkLayerShell', '0.1')
gi.require_version('Pango', '1.0')
gi.require_version('PangoCairo', '1.0')
from gi.repository import Gtk, Gdk, GtkLayerShell, GLib, Pango, PangoCairo
import cairo

CUSTOM_TOML_PATH = os.path.expanduser("~/.config/niri/scratchpad-items__custom__.toml")
LEGACY_TOML_PATH = os.path.expanduser("~/.config/niri/scratchpad-items.toml")
CUSTOM_JSON_PATH = os.path.expanduser("~/.config/niri/scratchpad-items.json")

RUNTIME_DIR = os.environ.get("XDG_RUNTIME_DIR") or f"/tmp/nyxniri-{os.getuid()}"
try:
    os.makedirs(RUNTIME_DIR, exist_ok=True)
except Exception:
    pass
LOCK_FILE_PATH = os.path.join(RUNTIME_DIR, "nyxniri-scratch-menu.lock")
PID_FILE_PATH = os.path.join(RUNTIME_DIR, "nyxniri-scratch-menu.pid")

# 布局和动画参数。
HYSTERESIS_DEG = 6.0        # Angular hysteresis margin (±6° entry threshold)


# 默认菜单树。
DEFAULT_MENU_TREE = [
    {
        "id": "kitty",
        "name": "Kitty",
        "desc": "Terminal",
        "icon": "󰞷",
        "cmd": "kitty",
        "shortcut": "1",
        "mnemonics": ["t", "k"],
        "color_key": "secondary",
    },
    {
        "id": "tools",
        "name": "System Tools",
        "desc": "Folder · 3 Tools",
        "icon": "󰘳",
        "shortcut": "2",
        "mnemonics": ["s", "t"],
        "color_key": "secondary",
        "children": [
            {
                "id": "missioncenter",
                "name": "Mission Center",
                "desc": "System Monitor",
                "icon": "󰓅",
                "cmd": "missioncenter",
                "shortcut": "1",
                "mnemonics": ["m"],
                "color_key": "secondary",
            },
            {
                "id": "eyecare",
                "name": "Eye Care",
                "desc": "Toggle Warmth",
                "icon": "󰛨",
                "cmd": "~/.config/niri/scripts/toggle-eyecare.sh",
                "shortcut": "2",
                "mnemonics": ["e"],
                "color_key": "secondary",
            },
            {
                "id": "cache",
                "name": "Clean Cache",
                "desc": "Free Disk Space",
                "icon": "󰃢",
                "cmd": "~/.config/fish/clean-cache",
                "shortcut": "3",
                "mnemonics": ["c"],
                "color_key": "secondary",
            },
        ],
    },
    {
        "id": "websites",
        "name": "Websites",
        "desc": "Folder · 3 Sites",
        "icon": "󰖟",
        "shortcut": "3",
        "mnemonics": ["w"],
        "color_key": "secondary",
        "children": [
            {
                "id": "zhihu",
                "name": "Zhihu",
                "desc": "知乎 · 发现更大世界",
                "icon": "󰖟",
                "url": "https://www.zhihu.com",
                "shortcut": "1",
                "mnemonics": ["z"],
                "color_key": "secondary",
            },
            {
                "id": "bilibili",
                "name": "Bilibili",
                "desc": "哔哩哔哩 (゜-゜)つロ",
                "icon": "󰕧",
                "url": "https://www.bilibili.com",
                "shortcut": "2",
                "mnemonics": ["b"],
                "color_key": "secondary",
            },
            {
                "id": "github",
                "name": "GitHub",
                "desc": "Code Repository",
                "icon": "󰊤",
                "url": "https://github.com",
                "shortcut": "3",
                "mnemonics": ["g"],
                "color_key": "secondary",
            },
        ],
    },
    {
        "id": "nautilus",
        "name": "Nautilus",
        "desc": "File Manager",
        "icon": "󰉋",
        "cmd": "nautilus",
        "shortcut": "4",
        "mnemonics": ["n", "f"],
        "color_key": "secondary",
    },
]

# ── Built-in Declarative Tier-1 Search Engine Suite ───────────────────────────
DEFAULT_SEARCH_ENGINES = [
    {
        "id": "bing",
        "name": "Bing",
        "icon": "󰍉",
        "url": "https://www.bing.com/search?q={query}",
    },
    {
        "id": "google",
        "name": "Google",
        "icon": "󰊭",
        "url": "https://www.google.com/search?q={query}",
    },
    {
        "id": "deepseek",
        "name": "DeepSeek",
        "icon": "󰈺",
        "url": "https://chat.deepseek.com/?q={query}",
    },
    {
        "id": "chatgpt",
        "name": "ChatGPT",
        "icon": "󰚩",
        "url": "https://chatgpt.com/?hints=search&q={query}",
    },
    {
        "id": "claude",
        "name": "Claude",
        "icon": "󰣆",
        "url": "https://claude.ai/new?q={query}",
    },
]


# Material You 动态配色。
def hex_to_rgb(hex_str, default=(0.5, 0.5, 0.5)):
    try:
        hex_str = hex_str.strip().lstrip("#")
        if len(hex_str) == 6:
            return tuple(int(hex_str[i:i + 2], 16) / 255.0 for i in (0, 2, 4))
    except Exception:
        pass
    return default


def load_material_palette():
    palette = {
        "primary": (0.42, 0.70, 1.00),
        "secondary": (0.38, 0.85, 0.65),
        "tertiary": (1.00, 0.75, 0.35),
        "surface": (0.12, 0.13, 0.18),
        "surface_dim": (0.05, 0.06, 0.09),
        "on_surface": (0.95, 0.96, 0.99),
        "on_surface_var": (0.68, 0.72, 0.78),
        "outline": (0.80, 0.84, 0.90),
        "is_dark": True,
    }

    starship_path = os.path.expanduser("~/.cache/noctalia/starship-palette.toml")
    if os.path.isfile(starship_path):
        try:
            with open(starship_path, "r", encoding="utf-8") as f:
                for line in f:
                    line = line.strip()
                    if "=" in line and not line.startswith(("#", "[")):
                        k, v = [x.strip() for x in line.split("=", 1)]
                        v = v.strip('"\'')
                        rgb = hex_to_rgb(v)
                        palette[k] = rgb
                        if k in ("blue", "sapphire", "primary"):
                            palette["primary"] = rgb
                        elif k in ("teal", "green", "secondary"):
                            palette["secondary"] = rgb
                        elif k in ("peach", "pink", "mauve", "yellow", "tertiary"):
                            palette["tertiary"] = rgb
                        elif k in ("surface0", "surface1", "base"):
                            palette["surface"] = rgb
                        elif k in ("crust", "mantle"):
                            palette["surface_dim"] = rgb
                        elif k in ("text", "white"):
                            palette["on_surface"] = rgb
                        elif k in ("subtext0", "subtext1", "overlay2"):
                            palette["on_surface_var"] = rgb
                        elif k in ("overlay0", "overlay1"):
                            palette["outline"] = rgb
        except Exception:
            pass

    sr, sg, sb = palette["surface"]
    palette["is_dark"] = (0.299 * sr + 0.587 * sg + 0.114 * sb < 0.5)
    return palette


def is_modifier_or_nav_key(keyval):
    """Check if keyval is a modifier or special navigation key that should never trigger search."""
    # 修饰键。
    if 0xffe1 <= keyval <= 0xffee:
        return True
    # ISO / AltGr 修饰键。
    if 0xfe00 <= keyval <= 0xfeff:
        return True
    # F1-F35。
    if Gdk.KEY_F1 <= keyval <= Gdk.KEY_F35:
        return True
    # 系统和导航键。
    if keyval in (
        Gdk.KEY_Insert, Gdk.KEY_Delete, Gdk.KEY_Home, Gdk.KEY_End,
        Gdk.KEY_Page_Up, Gdk.KEY_Page_Down, Gdk.KEY_Pause, Gdk.KEY_Print,
        Gdk.KEY_Menu, Gdk.KEY_Num_Lock, Gdk.KEY_Scroll_Lock, Gdk.KEY_VoidSymbol
    ):
        return True
    return False


# 二阶弹簧动画模型。
class Spring:
    def __init__(self, initial=0.0, omega=14.0, zeta=0.70):
        self.current = initial
        self.target = initial
        self.velocity = 0.0
        self.omega = omega
        self.zeta = zeta

    def update(self, dt):
        dt = min(0.05, max(0.001, dt))
        force = -(self.omega ** 2) * (self.current - self.target) - 2.0 * self.zeta * self.omega * self.velocity
        self.velocity += force * dt
        self.current += self.velocity * dt
        if abs(self.current - self.target) > 0.001 or abs(self.velocity) > 0.001:
            return True
        self.current = self.target
        self.velocity = 0.0
        return False


# 单实例与切换锁。
def acquire_instance_lock():
    """Ensure single-instance execution. If already running, signal active instance to toggle-close."""
    try:
        lock_fd = os.open(LOCK_FILE_PATH, os.O_CREAT | os.O_RDWR, 0o600)
        fcntl.flock(lock_fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except (BlockingIOError, OSError):
        if os.path.isfile(PID_FILE_PATH):
            try:
                with open(PID_FILE_PATH, "r") as pf:
                    old_pid = int(pf.read().strip())
                os.kill(old_pid, signal.SIGTERM)
            except Exception:
                pass
        sys.exit(0)

    try:
        with open(PID_FILE_PATH, "w") as pf:
            pf.write(str(os.getpid()))
    except Exception:
        pass

    return lock_fd


def release_instance_lock(lock_fd):
    try:
        if os.path.isfile(PID_FILE_PATH):
            os.remove(PID_FILE_PATH)
    except Exception:
        pass
    try:
        if lock_fd is not None:
            fcntl.flock(lock_fd, fcntl.LOCK_UN)
            os.close(lock_fd)
    except Exception:
        pass


class ScratchpadRadialMenu(RenderMixin, Gtk.Window):
    def __init__(self, lock_fd=None):
        super().__init__(type=Gtk.WindowType.TOPLEVEL)

        self.lock_fd = lock_fd
        self.palette = load_material_palette()
        self.root_items = self.load_menu_tree()
        self.menu_stack = []
        self.apps = self.root_items
        self.num_items = len(self.apps)

        # 搜索配置。
        self.search_engines, self.search_meta = self.load_search_config()
        self.default_engine_id = self.search_meta.get("default_engine", "bing")
        self.placeholder_text = self.search_meta.get("placeholder", "Search or ask...")
        self.current_engine_idx = 0
        for idx, eng in enumerate(self.search_engines):
            if eng.get("id") == self.default_engine_id:
                self.current_engine_idx = idx
                break

        self.search_query = ""
        self.search_active = False
        self.cursor_time = 0.0

        # 预缓存返回图标。
        self.layout_back = self.create_pango_layout("󰌍")
        self.layout_back.set_font_description(Pango.FontDescription("JetBrainsMono Nerd Font Bold 16"))
        self.back_ink_rect, _ = self.layout_back.get_pixel_extents()

        self.hovered_index = None
        self.keyboard_selected = None
        self.center_x = None
        self.center_y = None
        self.origin_locked = False
        self.is_dismissing = False
        self.last_mouse_pos = None

        # 初始化动画状态。
        self.entry_spring = Spring(0.0, omega=14.0, zeta=0.70)
        self.trans_spring = Spring(1.0, omega=15.0, zeta=0.80)
        self.core_spring_x = Spring(0.0, omega=18.0, zeta=1.00)
        self.core_spring_y = Spring(0.0, omega=18.0, zeta=1.00)
        self.search_spring = Spring(0.0, omega=18.0, zeta=0.75)
        self.engine_switch_spring = Spring(1.0, omega=22.0, zeta=0.78)
        self.node_springs = []

        # 原生 Wayland 输入法上下文。
        self.im_context = Gtk.IMMulticontext()
        self.im_context.set_use_preedit(True)
        self.im_context.connect("commit", self.on_im_commit)
        self.im_context.connect("preedit-changed", self.on_im_preedit_changed)

        self.setup_current_tier()

        # GdkFrameClock 帧同步。
        self.tick_callback_id = None
        self.last_frame_time = 0

        # Layer Shell。
        GtkLayerShell.init_for_window(self)
        GtkLayerShell.set_layer(self, GtkLayerShell.Layer.OVERLAY)
        GtkLayerShell.set_keyboard_mode(self, GtkLayerShell.KeyboardMode.EXCLUSIVE)
        GtkLayerShell.set_exclusive_zone(self, -1)

        for edge in (GtkLayerShell.Edge.LEFT, GtkLayerShell.Edge.RIGHT, GtkLayerShell.Edge.TOP, GtkLayerShell.Edge.BOTTOM):
            GtkLayerShell.set_anchor(self, edge, True)
            GtkLayerShell.set_margin(self, edge, 0)

        self.set_app_paintable(True)
        visual = self.get_screen().get_rgba_visual()
        if visual:
            self.set_visual(visual)

        self.add_events(
            Gdk.EventMask.POINTER_MOTION_MASK
            | Gdk.EventMask.BUTTON_PRESS_MASK
            | Gdk.EventMask.ENTER_NOTIFY_MASK
            | Gdk.EventMask.SCROLL_MASK
            | Gdk.EventMask.KEY_PRESS_MASK
            | Gdk.EventMask.KEY_RELEASE_MASK
            | Gdk.EventMask.STRUCTURE_MASK
        )

        self.connect("realize", self.on_realize)
        self.connect("draw", self.on_draw)
        self.connect("motion-notify-event", self.on_motion_notify)
        self.connect("enter-notify-event", self.on_enter_notify)
        self.connect("button-press-event", self.on_button_press)
        self.connect("scroll-event", self.on_scroll)
        self.connect("key-press-event", self.on_key_press)
        self.connect("key-release-event", self.on_key_release)
        self.connect("delete-event", lambda w, e: (self.dismiss_menu(), True)[1])
        self.connect("destroy", lambda w: Gtk.main_quit())

        self.open_menu()

    def on_realize(self, widget):
        gdk_window = self.get_window()
        if gdk_window:
            self.im_context.set_client_window(gdk_window)

    def update_im_cursor_location(self, cursor_x, cursor_y):
        rect = Gdk.Rectangle()
        rect.x = int(cursor_x)
        rect.y = int(cursor_y)
        rect.width = 2
        rect.height = 26
        self.im_context.set_cursor_location(rect)

    def load_search_config(self):
        """Priority loader for search configuration: TOML (__custom__ -> legacy) -> JSON -> Defaults."""
        for toml_path in (CUSTOM_TOML_PATH, LEGACY_TOML_PATH):
            if HAS_TOMLLIB and os.path.isfile(toml_path):
                try:
                    with open(toml_path, "rb") as f:
                        data = tomllib.load(f)
                        engines = data.get("search_engines", [])
                        search_meta = data.get("search", {})
                        if isinstance(engines, list) and len(engines) > 0:
                            return engines, search_meta
                        elif isinstance(search_meta, dict) and "engines" in search_meta:
                            return search_meta["engines"], search_meta
                except Exception as e:
                    print(f"Error loading search config from {toml_path}: {e}", file=sys.stderr)

        if os.path.isfile(CUSTOM_JSON_PATH):
            try:
                with open(CUSTOM_JSON_PATH, "r", encoding="utf-8") as f:
                    data = json.load(f)
                    if isinstance(data, dict):
                        engines = data.get("search_engines", [])
                        search_meta = data.get("search", {})
                        if isinstance(engines, list) and len(engines) > 0:
                            return engines, search_meta
            except Exception as e:
                print(f"Error loading search config from {CUSTOM_JSON_PATH}: {e}", file=sys.stderr)

        return DEFAULT_SEARCH_ENGINES, {"default_engine": "bing", "placeholder": "Search or ask..."}

    def load_menu_tree(self):
        """Priority loader: TOML (__custom__ -> legacy) -> JSON -> Built-in Default Tree."""
        for toml_path in (CUSTOM_TOML_PATH, LEGACY_TOML_PATH):
            if HAS_TOMLLIB and os.path.isfile(toml_path):
                try:
                    with open(toml_path, "rb") as f:
                        data = tomllib.load(f)
                        items = data.get("items", [])
                        if isinstance(items, list) and len(items) > 0:
                            return items
                except Exception as e:
                    print(f"Error loading {toml_path}: {e}", file=sys.stderr)

        if os.path.isfile(CUSTOM_JSON_PATH):
            try:
                with open(CUSTOM_JSON_PATH, "r", encoding="utf-8") as f:
                    data = json.load(f)
                    if isinstance(data, list) and len(data) > 0:
                        return data
                    elif isinstance(data, dict) and "items" in data:
                        return data["items"]
            except Exception as e:
                print(f"Error loading {CUSTOM_JSON_PATH}: {e}", file=sys.stderr)

        return DEFAULT_MENU_TREE

    def setup_current_tier(self):
        if not self.apps or not isinstance(self.apps, list):
            self.apps = DEFAULT_MENU_TREE
        self.num_items = len(self.apps)
        if self.num_items == 0:
            return
        self.node_springs = [Spring(0.0, omega=12.0, zeta=0.65) for _ in range(self.num_items)]
        self.init_geometry()
        self.init_cached_layouts()

    def init_geometry(self):
        if self.num_items == 0:
            return
        start_angle = -90.0
        step = 360.0 / self.num_items
        for i, app in enumerate(self.apps):
            angle = (start_angle + i * step) % 360.0
            if angle > 180.0:
                angle -= 360.0
            app["center_angle"] = angle
            color_key = str(app.get("color_key", "secondary"))
            if color_key.startswith("#"):
                app["color"] = hex_to_rgb(color_key, default=(0.38, 0.85, 0.65))
            else:
                app["color"] = self.palette.get(color_key, (0.38, 0.85, 0.65))

    def init_cached_layouts(self):
        font_title = Pango.FontDescription("Noto Sans CJK SC, Inter, sans-serif SemiBold 11.5")
        font_desc = Pango.FontDescription("Noto Sans CJK SC, Inter, sans-serif Regular 8.5")
        font_icon = Pango.FontDescription("JetBrainsMono Nerd Font 14")
        font_badge = Pango.FontDescription("JetBrains Mono Bold 9")

        for app in self.apps:
            app_name = str(app.get("name") or app.get("id") or "App")
            lt = self.create_pango_layout(app_name)
            lt.set_font_description(font_title)
            tw, th = lt.get_pixel_size()
            app["layout_title"] = lt
            app["title_w"], app["title_h"] = tw, th

            desc_text = str(app.get("desc") or "")
            if not desc_text:
                if "children" in app and isinstance(app["children"], list):
                    desc_text = f"Folder · {len(app['children'])} Items"
                elif "url" in app:
                    desc_text = "Web Link"
            ld = self.create_pango_layout(desc_text)
            ld.set_font_description(font_desc)
            dw, dh = ld.get_pixel_size()
            app["layout_desc"] = ld
            app["desc_w"], app["desc_h"] = dw, dh

            li = self.create_pango_layout(str(app.get("icon", "󰣆")))
            li.set_font_description(font_icon)
            ink_rect, log_rect = li.get_pixel_extents()
            app["layout_icon"] = li
            app["icon_ink_rect"] = ink_rect
            app["icon_w"], app["icon_h"] = log_rect.width, log_rect.height

            lk = self.create_pango_layout(str(app.get("shortcut", "")))
            lk.set_font_description(font_badge)
            kw, kh = lk.get_pixel_size()
            app["layout_badge"] = lk
            app["badge_w"], app["badge_h"] = kw, kh

            needed_w = 14.0 + 32.0 + 8.0 + max(tw, dw) + 8.0 + (kw + 8.0) + 14.0
            app["idle_w"] = max(156.0, needed_w)
            app["active_w"] = app["idle_w"] + 24.0

        # 预缓存搜索引擎布局。
        font_engine_icon = Pango.FontDescription("JetBrainsMono Nerd Font Bold 16")
        font_placeholder = Pango.FontDescription("Noto Sans CJK SC, Inter Bold 13")
        for eng in self.search_engines:
            icon_text = str(eng.get("icon", "󰍉"))
            le = self.create_pango_layout(icon_text)
            le.set_font_description(font_engine_icon)
            ink_rect, log_rect = le.get_pixel_extents()
            eng["layout"] = le
            eng["icon_ink"] = ink_rect
            eng["layout_w"] = log_rect.width
            eng["layout_h"] = log_rect.height

        self.layout_placeholder = self.create_pango_layout(self.placeholder_text)
        self.layout_placeholder.set_font_description(font_placeholder)
        self.placeholder_w, self.placeholder_h = self.layout_placeholder.get_pixel_size()

    def open_menu(self):
        self.palette = load_material_palette()
        self.hovered_index = None
        self.keyboard_selected = None
        self.is_dismissing = False
        self.last_mouse_pos = None

        self.search_query = ""
        self.search_active = False
        self.cursor_time = 0.0

        self.entry_spring.current = 0.0
        self.entry_spring.target = 1.0
        self.entry_spring.velocity = 0.0

        self.trans_spring.current = 1.0
        self.trans_spring.target = 1.0
        self.trans_spring.velocity = 0.0

        self.core_spring_x.current = 0.0
        self.core_spring_x.target = 0.0
        self.core_spring_x.velocity = 0.0
        self.core_spring_y.current = 0.0
        self.core_spring_y.target = 0.0
        self.core_spring_y.velocity = 0.0

        self.search_spring.current = 0.0
        self.search_spring.target = 0.0
        self.search_spring.velocity = 0.0

        self.engine_switch_spring.current = 1.0
        self.engine_switch_spring.target = 1.0
        self.engine_switch_spring.velocity = 0.0

        self.show_all()
        self.present()
        self.im_context.focus_in()
        self._request_frame()

    def dismiss_menu(self):
        if self.is_dismissing:
            return
        self.is_dismissing = True
        self.im_context.focus_out()
        self.entry_spring.target = 0.0
        self._request_frame()

    def _finish_dismiss(self):
        release_instance_lock(self.lock_fd)
        self.lock_fd = None
        self.hide()
        Gtk.main_quit()

    def drill_down(self, child_items):
        if not child_items or not isinstance(child_items, list):
            return
        self.menu_stack.append((self.apps, self.hovered_index))
        self.apps = child_items
        self.setup_current_tier()
        self.hovered_index = None
        self.keyboard_selected = None

        self.trans_spring.omega = 15.0
        self.trans_spring.zeta = 0.80
        self.trans_spring.current = 0.75
        self.trans_spring.target = 1.0
        self.trans_spring.velocity = 0.0
        self._request_frame()

    def return_to_parent(self):
        if not self.menu_stack:
            self.dismiss_menu()
            return

        parent_items, prev_hover = self.menu_stack.pop()
        self.apps = parent_items
        self.setup_current_tier()
        self.hovered_index = prev_hover
        self.keyboard_selected = None

        self.trans_spring.omega = 16.0
        self.trans_spring.zeta = 0.90
        self.trans_spring.current = 1.15
        self.trans_spring.target = 1.0
        self.trans_spring.velocity = 0.0
        self._request_frame()

    def trigger_app(self, item):
        # 文件夹进入。
        if "children" in item and len(item["children"]) > 0:
            self.drill_down(item["children"])
            return

        # URL 通过 xdg-open 打开。
        url = item.get("url", "")
        cmd = item.get("cmd") or item.get("id") or item.get("name", "").lower()
        target_url = url if url else (cmd if cmd.startswith(("http://", "https://", "www.")) else "")

        if target_url:
            if target_url.startswith("www."):
                target_url = "https://" + target_url
            try:
                subprocess.Popen(["xdg-open", target_url])
            except Exception as e:
                print(f"Error opening URL: {e}", file=sys.stderr)
            self.dismiss_menu()
            return

        # 本地命令或应用。
        script_path = os.path.expanduser("~/.config/niri/scripts/niri-scratch-toggle.sh")
        if not os.path.isfile(script_path):
            script_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "niri-scratch-toggle.sh")
        try:
            subprocess.Popen(["/usr/bin/env", "bash", script_path, cmd])
        except Exception as e:
            print(f"Error launching scratchpad: {e}", file=sys.stderr)
        self.dismiss_menu()

    def trigger_search(self):
        query = self.search_query.strip()
        if not query or not self.search_engines:
            return
        engine = self.search_engines[self.current_engine_idx % len(self.search_engines)]
        encoded_query = urllib.parse.quote_plus(query)
        target_url = engine.get("url", "https://www.bing.com/search?q={query}").replace("{query}", encoded_query)
        try:
            subprocess.Popen(["xdg-open", target_url])
        except Exception as e:
            print(f"Error launching web search: {e}", file=sys.stderr)
        self.dismiss_menu()

    def set_anchor_center(self, cursor_x, cursor_y):
        w = self.get_allocated_width() or 1920
        h = self.get_allocated_height() or 1080
        pad_x, pad_y = 250.0, 210.0
        self.center_x = max(pad_x, min(w - pad_x, cursor_x))
        self.center_y = max(pad_y, min(h - pad_y, cursor_y))
        self.origin_locked = True

    def _request_frame(self):
        if self.tick_callback_id is None:
            self.last_frame_time = 0
            self.tick_callback_id = self.add_tick_callback(self.on_frame_tick)

    def on_frame_tick(self, widget, frame_clock):
        frame_time = frame_clock.get_frame_time()
        dt = 0.016 if self.last_frame_time == 0 else (frame_time - self.last_frame_time) / 1_000_000.0
        self.last_frame_time = frame_time
        self.cursor_time += dt

        still_animating = False

        if self.entry_spring.update(dt):
            still_animating = True

        if self.is_dismissing and self.entry_spring.current <= 0.02:
            self._finish_dismiss()
            self.tick_callback_id = None
            return GLib.SOURCE_REMOVE

        if self.trans_spring.update(dt):
            still_animating = True

        if self.search_spring.update(dt):
            still_animating = True

        if self.engine_switch_spring.update(dt):
            still_animating = True

        # 搜索状态保持光标动画。
        if self.search_spring.current > 0.01 and not self.is_dismissing and len(self.menu_stack) == 0:
            still_animating = True

        active_idx = self.keyboard_selected if self.keyboard_selected is not None else self.hovered_index
        for i in range(self.num_items):
            if i < len(self.node_springs):
                self.node_springs[i].target = 1.0 if (active_idx == i and not self.is_dismissing) else 0.0
                if self.node_springs[i].update(dt):
                    still_animating = True

        if active_idx is not None and not self.is_dismissing and active_idx < self.num_items and self.search_spring.current <= 0.01:
            ang_rad = math.radians(self.apps[active_idx]["center_angle"])
            self.core_spring_x.target = math.cos(ang_rad) * 10.0
            self.core_spring_y.target = math.sin(ang_rad) * 10.0
        else:
            self.core_spring_x.target = 0.0
            self.core_spring_y.target = 0.0

        if self.core_spring_x.update(dt) or self.core_spring_y.update(dt):
            still_animating = True

        self.queue_draw()

        if not still_animating:
            self.tick_callback_id = None
            return GLib.SOURCE_REMOVE

        return GLib.SOURCE_CONTINUE

    def update_hover(self, mx, my):
        if not self.origin_locked:
            self.set_anchor_center(mx, my)

        if self.keyboard_selected is not None:
            if self.last_mouse_pos is not None:
                dx_m = mx - self.last_mouse_pos[0]
                dy_m = my - self.last_mouse_pos[1]
                if math.hypot(dx_m, dy_m) > 6.0:
                    self.keyboard_selected = None
            else:
                self.last_mouse_pos = (mx, my)

        self.last_mouse_pos = (mx, my)
        dx = mx - self.center_x
        dy = my - self.center_y
        dist = math.hypot(dx, dy)

        if dist < DEADZONE_RADIUS:
            new_hover = None
        else:
            angle_deg = math.degrees(math.atan2(dy, dx))
            best_idx = None
            min_diff = 999.0

            for i, app in enumerate(self.apps):
                c_ang = app["center_angle"]
                diff = abs((angle_deg - c_ang + 180.0) % 360.0 - 180.0)
                if self.hovered_index == i:
                    diff -= HYSTERESIS_DEG
                if diff < min_diff:
                    min_diff = diff
                    best_idx = i

            new_hover = best_idx

        if new_hover != self.hovered_index:
            self.hovered_index = new_hover
            self._request_frame()

    def on_enter_notify(self, widget, event):
        if not self.origin_locked:
            self.set_anchor_center(event.x, event.y)
        return True

    def on_motion_notify(self, widget, event):
        if not self.is_dismissing:
            self.update_hover(event.x, event.y)
        return True

    def on_button_press(self, widget, event):
        if not self.origin_locked:
            self.set_anchor_center(event.x, event.y)

        is_search_mode = (self.search_spring.current > 0.05 or bool(self.search_query)) and len(self.menu_stack) == 0

        # 右键或中键。
        if event.button in (2, 3):
            if is_search_mode:
                # 收起搜索状态。
                self.search_query = ""
                self.search_active = False
                self.search_spring.target = 0.0
                self._request_frame()
                return True
            else:
                if len(self.menu_stack) > 0:
                    self.return_to_parent()
                else:
                    self.dismiss_menu()
                return True

        # 左键。
        if event.button == 1:
            cx, cy = (self.center_x or 960.0), (self.center_y or 540.0)
            dx = event.x - cx
            dy = event.y - cy
            dist = math.hypot(dx, dy)

            # 搜索模式点击处理。
            if len(self.menu_stack) == 0:
                search_prog = max(0.0, min(1.0, self.search_spring.current))
                if search_prog > 0.05:
                    sw = 36.0 + (390.0 - 36.0) * search_prog
                    sh = 36.0 + (64.0 - 36.0) * search_prog
                    if abs(dx) <= sw / 2.0 and abs(dy) <= sh / 2.0:
                        # 点击左侧引擎图标切换引擎。
                        if dx < -sw / 4.0 and len(self.search_engines) > 0:
                            self.current_engine_idx = (self.current_engine_idx + 1) % len(self.search_engines)
                            self.engine_switch_spring.current = 0.85
                            self.engine_switch_spring.target = 1.0
                        self.search_active = True
                        self.search_spring.target = 1.0
                        self.keyboard_selected = None
                        self._request_frame()
                        return True
                    else:
                        # 点击搜索框外部收起搜索。
                        self.search_query = ""
                        self.search_active = False
                        self.search_spring.target = 0.0
                        self._request_frame()
                        return True
                elif dist <= DEADZONE_RADIUS:
                    # 点击中心点进入搜索。
                    self.search_active = True
                    self.search_spring.target = 1.0
                    self.keyboard_selected = None
                    self._request_frame()
                    return True

            active_idx = self.keyboard_selected if self.keyboard_selected is not None else self.hovered_index
            if active_idx is not None and active_idx < self.num_items and self.search_spring.current <= 0.05:
                self.trigger_app(self.apps[active_idx])
            else:
                if len(self.menu_stack) > 0:
                    self.return_to_parent()
                else:
                    self.dismiss_menu()
            return True

        return False

    def on_scroll(self, widget, event):
        if self.is_dismissing or self.search_spring.current > 0.05:
            return False
        cur = self.keyboard_selected if self.keyboard_selected is not None else (self.hovered_index or 0)
        if event.direction == Gdk.ScrollDirection.DOWN:
            self.keyboard_selected = (cur + 1) % self.num_items
            self._request_frame()
            return True
        elif event.direction == Gdk.ScrollDirection.UP:
            self.keyboard_selected = (cur - 1 + self.num_items) % self.num_items
            self._request_frame()
            return True
        return False

    def on_im_commit(self, im_context, text):
        if len(self.menu_stack) == 0:
            self.search_active = True
            self.search_query += text
            self.search_spring.target = 1.0
            self.keyboard_selected = None
            self._request_frame()

    def on_im_preedit_changed(self, im_context):
        self._request_frame()

    def on_key_release(self, widget, event):
        if self.search_active and len(self.menu_stack) == 0 and self.im_context.filter_keypress(event):
            return True
        return False

    def on_key_press(self, widget, event):
        keyval = event.keyval

        if self.center_x is None:
            w = self.get_allocated_width() or 1920
            h = self.get_allocated_height() or 1080
            self.center_x = w / 2.0
            self.center_y = h / 2.0
            self.origin_locked = True

        is_search_mode = (self.search_spring.current > 0.05 or bool(self.search_query)) and len(self.menu_stack) == 0

        # 空闲模式。
        if not is_search_mode:
            # 忽略修饰键和功能键。
            if is_modifier_or_nav_key(keyval):
                return False

            # 数字键直接触发对应项目。
            if Gdk.KEY_1 <= keyval <= Gdk.KEY_9:
                num = keyval - Gdk.KEY_1
                if num < self.num_items:
                    self.trigger_app(self.apps[num])
                    return True

            # Escape / Backspace 返回或退出。
            if keyval in (Gdk.KEY_Escape, Gdk.KEY_BackSpace, Gdk.KEY_q, Gdk.KEY_Q):
                if len(self.menu_stack) > 0:
                    self.return_to_parent()
                else:
                    self.dismiss_menu()
                return True

            # Tab / Shift+Tab 唤醒搜索并切换引擎。
            if keyval in (Gdk.KEY_Tab, Gdk.KEY_ISO_Left_Tab):
                if len(self.menu_stack) == 0 and len(self.search_engines) > 0:
                    is_backward = bool(event.state & Gdk.ModifierType.SHIFT_MASK) or keyval == Gdk.KEY_ISO_Left_Tab
                    step = -1 if is_backward else 1
                    self.current_engine_idx = (self.current_engine_idx + step) % len(self.search_engines)
                    self.search_active = True
                    self.search_spring.target = 1.0
                    self.engine_switch_spring.current = 0.85
                    self.engine_switch_spring.target = 1.0
                    self.engine_switch_spring.velocity = 0.0
                    self._request_frame()
                    return True
                elif len(self.menu_stack) > 0:
                    is_backward = bool(event.state & Gdk.ModifierType.SHIFT_MASK) or keyval == Gdk.KEY_ISO_Left_Tab
                    cur = self.keyboard_selected if self.keyboard_selected is not None else (self.hovered_index if self.hovered_index is not None else -1)
                    step = -1 if is_backward else 1
                    self.keyboard_selected = (cur + step) % self.num_items
                    self._request_frame()
                    return True

            # Enter / Space 执行当前项目。
            if keyval in (Gdk.KEY_Return, Gdk.KEY_KP_Enter, Gdk.KEY_space):
                active_idx = self.keyboard_selected if self.keyboard_selected is not None else self.hovered_index
                if active_idx is not None and active_idx < self.num_items:
                    self.trigger_app(self.apps[active_idx])
                else:
                    if len(self.menu_stack) > 0:
                        self.return_to_parent()
                    else:
                        self.dismiss_menu()
                return True

            # 方向键导航。
            dir_map = {
                Gdk.KEY_h: 180.0, Gdk.KEY_Left: 180.0,
                Gdk.KEY_l: 0.0,   Gdk.KEY_Right: 0.0,
                Gdk.KEY_j: 90.0,  Gdk.KEY_Down: 90.0,
                Gdk.KEY_k: -90.0, Gdk.KEY_Up: -90.0,
            }
            if keyval in dir_map:
                target_angle = dir_map[keyval]
                best_idx = None
                min_diff = 999.0
                for i, app in enumerate(self.apps):
                    diff = abs((target_angle - app["center_angle"] + 180.0) % 360.0 - 180.0)
                    if diff < min_diff:
                        min_diff = diff
                        best_idx = i
                if best_idx is not None:
                    self.keyboard_selected = best_idx
                    self._request_frame()
                    return True

            # 输入字符或使用 IME 唤醒搜索。
            if len(self.menu_stack) == 0:
                if self.im_context.filter_keypress(event):
                    self.search_active = True
                    self.search_spring.target = 1.0
                    self.keyboard_selected = None
                    return True
                key_char = chr(keyval) if 32 <= keyval <= 126 else ""
                if key_char:
                    self.search_active = True
                    self.search_spring.target = 1.0
                    self.keyboard_selected = None
                    self.search_query += key_char
                    self._request_frame()
                    return True

            return False

        # 搜索模式。
        # 优先交给原生 IME 处理。
        if self.im_context.filter_keypress(event):
            return True

        # Escape 清空搜索并收起。
        if keyval in (Gdk.KEY_Escape,):
            self.search_query = ""
            self.search_active = False
            self.search_spring.target = 0.0
            self._request_frame()
            return True

        # Backspace 删除字符；清空后收起。
        if keyval in (Gdk.KEY_BackSpace,):
            if self.search_query:
                self.search_query = self.search_query[:-1]
            if not self.search_query:
                self.search_active = False
                self.search_spring.target = 0.0
            self._request_frame()
            return True

        # Tab / Shift+Tab 切换引擎。
        if keyval in (Gdk.KEY_Tab, Gdk.KEY_ISO_Left_Tab):
            if len(self.search_engines) > 0:
                is_backward = bool(event.state & Gdk.ModifierType.SHIFT_MASK) or keyval == Gdk.KEY_ISO_Left_Tab
                step = -1 if is_backward else 1
                self.current_engine_idx = (self.current_engine_idx + step) % len(self.search_engines)
                self.engine_switch_spring.current = 0.85
                self.engine_switch_spring.target = 1.0
                self.engine_switch_spring.velocity = 0.0
                self._request_frame()
                return True

        # Enter 执行搜索。
        if keyval in (Gdk.KEY_Return, Gdk.KEY_KP_Enter):
            if self.search_query.strip():
                self.trigger_search()
                return True

        # 继续输入搜索内容。
        key_char = chr(keyval) if 32 <= keyval <= 126 else ""
        if key_char:
            self.search_query += key_char
            self._request_frame()
            return True

        return False

def main():
    lock_fd = acquire_instance_lock()
    win = ScratchpadRadialMenu(lock_fd=lock_fd)

    def handle_signal(signum, frame):
        GLib.idle_add(win.dismiss_menu)

    signal.signal(signal.SIGTERM, handle_signal)
    signal.signal(signal.SIGINT, handle_signal)

    try:
        Gtk.main()
    finally:
        release_instance_lock(lock_fd)


if __name__ == "__main__":
    main()
