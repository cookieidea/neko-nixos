#!/usr/bin/env python3
"""星环菜单的绘制逻辑（自 niri-scratch-menu.py 提取）。

以 mixin 形式提供：绘制过程依赖主类上 25+ 个布局/弹簧/调色板属性，
拆成独立函数需传递大量参数，mixin 可自然共享 self 状态。

被 ScratchpadRadialMenu 继承；主文件不再保留这些方法。
"""

import math

# 与主脚本一致的 GI 导入方式（Pango/PangoCairo 来自 gi.repository，
# 不是独立顶层模块；且需先 require_version 才能 import）。
import gi
gi.require_version('Pango', '1.0')
gi.require_version('PangoCairo', '1.0')
from gi.repository import Pango, PangoCairo


# ── 共享布局常量 ──
# 主文件与绘制模块都用，故定义在绘制模块（几何/尺寸归渲染方所有），
# 主文件从本模块导入。
BASE_ORBIT_RADIUS = 168.0   # Golden ratio orbital radius (+16% breathing space)
DEADZONE_RADIUS = 48.0      # Calibrated deadzone radius (r < 48px: center hub focus)
FLOAT_SPRING = 16.0         # Radial outward displacement on activation (+16px)
CAPSULE_IDLE_H = 48.0       # Idle capsule height (px)
CAPSULE_ACTIVE_H = 54.0     # Active capsule height (px)


class RenderMixin:
    def draw_rounded_pill(self, cr, x, y, w, h, r):
        r = min(r, w / 2.0, h / 2.0)
        cr.new_path()
        cr.arc(x + r, y + r, r, math.pi, 3.0 * math.pi / 2.0)
        cr.arc(x + w - r, y + r, r, 3.0 * math.pi / 2.0, 2.0 * math.pi)
        cr.arc(x + w - r, y + h - r, r, 0.0, math.pi / 2.0)
        cr.arc(x + r, y + h - r, r, math.pi / 2.0, math.pi)
        cr.close_path()

    def on_draw(self, widget, cr):
        entry_val = max(0.0, min(1.0, self.entry_spring.current))
        if entry_val <= 0.001:
            return False

        trans_val = max(0.2, self.trans_spring.current)
        search_prog = max(0.0, min(1.0, self.search_spring.current))
        cx, cy = (self.center_x or 960.0), (self.center_y or 540.0)
        p = self.palette
        active_idx = self.keyboard_selected if self.keyboard_selected is not None else self.hovered_index

        dim_r, dim_g, dim_b = p["surface_dim"]
        surf_r, surf_g, surf_b = p["surface"]
        out_r, out_g, out_b = p["outline"]

        is_submenu = len(self.menu_stack) > 0

        # 搜索时隐藏外围菜单。
        outer_alpha = max(0.0, 1.0 - search_prog * 1.05) * entry_val if not is_submenu else entry_val

        # 背景遮罩。
        cr.save()
        cr.set_source_rgba(dim_r, dim_g, dim_b, (0.42 if p["is_dark"] else 0.22) * entry_val)
        cr.paint()
        cr.restore()

        # 缩放和透明度。
        cr.save()
        scale = (0.76 + 0.24 * entry_val) * trans_val
        cr.translate(cx, cy)
        cr.scale(scale, scale)
        cr.translate(-cx, -cy)

        core_x = cx + self.core_spring_x.current
        core_y = cy + self.core_spring_y.current

        # 搜索状态径向位移。
        search_disp = search_prog * 20.0 if not is_submenu else 0.0
        orbit_r = max(BASE_ORBIT_RADIUS, 120.0 + self.num_items * 12.0) + search_disp

        # 星环。
        if outer_alpha > 0.01:
            cr.save()
            cr.new_path()
            cr.arc(cx, cy, orbit_r, 0, 2 * math.pi)
            cr.set_line_width(18.0)
            if active_idx is not None and active_idx < self.num_items and search_prog <= 0.01:
                ar, ag, ab = self.apps[active_idx]["color"]
                cr.set_source_rgba(ar, ag, ab, 0.06 * outer_alpha)
            else:
                cr.set_source_rgba(out_r, out_g, out_b, 0.02 * outer_alpha)
            cr.stroke()
            cr.restore()

            cr.save()
            cr.new_path()
            cr.arc(cx, cy, orbit_r, 0, 2 * math.pi)
            cr.set_line_width(1.0)
            cr.set_source_rgba(out_r, out_g, out_b, 0.10 * outer_alpha)
            cr.stroke()

            cr.new_path()
            cr.arc(cx, cy, orbit_r, 0, 2 * math.pi)
            cr.set_dash([3.0, 7.0])
            cr.set_line_width(1.2)
            cr.set_source_rgba(out_r, out_g, out_b, 0.18 * outer_alpha)
            cr.stroke()
            cr.restore()

            step_deg = 360.0 / self.num_items
            for i in range(self.num_items):
                div_rad = math.radians(-90.0 + (i + 0.5) * step_deg)
                tx1, ty1 = cx + (orbit_r - 6.0) * math.cos(div_rad), cy + (orbit_r - 6.0) * math.sin(div_rad)
                tx2, ty2 = cx + (orbit_r + 6.0) * math.cos(div_rad), cy + (orbit_r + 6.0) * math.sin(div_rad)
                cr.save()
                cr.new_path()
                cr.move_to(tx1, ty1)
                cr.line_to(tx2, ty2)
                cr.set_line_width(1.0)
                cr.set_source_rgba(out_r, out_g, out_b, 0.16 * outer_alpha)
                cr.stroke()
                cr.restore()

            for i, app in enumerate(self.apps):
                if i < len(self.node_springs):
                    prog = max(0.0, min(1.0, self.node_springs[i].current))
                    if prog > 0.01:
                        app_r, app_g, app_b = app["color"]
                        ang_deg = app["center_angle"]
                        half_span = (step_deg / 2.0) - 4.0
                        start_rad = math.radians(ang_deg - half_span)
                        end_rad = math.radians(ang_deg + half_span)

                        cr.save()
                        cr.new_path()
                        cr.arc(cx, cy, orbit_r, start_rad, end_rad)
                        cr.set_line_width(14.0)
                        cr.set_source_rgba(app_r, app_g, app_b, 0.15 * prog * outer_alpha)
                        cr.stroke()

                        cr.new_path()
                        cr.arc(cx, cy, orbit_r, start_rad, end_rad)
                        cr.set_line_width(2.5 + prog * 1.5)
                        cr.set_source_rgba(app_r, app_g, app_b, (0.50 + 0.45 * prog) * outer_alpha)
                        cr.stroke()
                        cr.restore()

        # 中心到节点的动态连线。
        if search_prog <= 0.01:
            cr.save()
            cr.new_path()
            cr.arc(cx, cy, DEADZONE_RADIUS, 0, 2 * math.pi)
            cr.set_dash([2.0, 4.0])
            cr.set_line_width(0.8)
            cr.set_source_rgba(out_r, out_g, out_b, 0.12 * outer_alpha)
            cr.stroke()
            cr.restore()

            for i, app in enumerate(self.apps):
                if i < len(self.node_springs):
                    prog = max(0.0, min(1.0, self.node_springs[i].current))
                    if prog > 0.01:
                        app_r, app_g, app_b = app["color"]
                        ang_rad = math.radians(app["center_angle"])
                        node_dist = orbit_r + prog * FLOAT_SPRING
                        target_x = cx + node_dist * math.cos(ang_rad)
                        target_y = cy + node_dist * math.sin(ang_rad)

                        cr.save()
                        cr.new_path()
                        cr.move_to(core_x, core_y)
                        cr.line_to(target_x, target_y)
                        cr.set_dash([2.0, 5.0])
                        cr.set_line_width(1.2 + prog * 0.8)
                        cr.set_source_rgba(app_r, app_g, app_b, (0.15 + 0.65 * prog) * outer_alpha)
                        cr.stroke()
                        cr.restore()

        # 中心控件形态过渡。
        if is_submenu:
            # 子菜单返回节点。
            cr.save()
            core_radius = 18.0
            cr.new_path()
            cr.arc(core_x, core_y, core_radius, 0, 2 * math.pi)
            cr.set_source_rgba(out_r, out_g, out_b, 0.12 * entry_val)
            cr.fill()

            cr.new_path()
            cr.arc(core_x, core_y, 10.0, 0, 2 * math.pi)
            cr.set_source_rgba(p["on_surface_var"][0], p["on_surface_var"][1], p["on_surface_var"][2], 0.40 * entry_val)
            cr.set_line_width(1.4)
            cr.stroke()

            bw, bh = self.back_ink_rect.width, self.back_ink_rect.height
            bx = core_x - self.back_ink_rect.x - (bw / 2.0)
            by = core_y - self.back_ink_rect.y - (bh / 2.0)
            cr.move_to(bx, by)
            cr.set_source_rgba(p["on_surface"][0], p["on_surface"][1], p["on_surface"][2], 0.95 * entry_val)
            PangoCairo.show_layout(cr, self.layout_back)
            cr.restore()
        else:
            # 根菜单中心控件。
            if search_prog <= 0.01:
                # 空闲中心点。
                cr.save()
                core_radius = 14.0
                cr.new_path()
                cr.arc(core_x, core_y, core_radius, 0, 2 * math.pi)
                if active_idx is not None and active_idx < self.num_items:
                    ar, ag, ab = self.apps[active_idx]["color"]
                    cr.set_source_rgba(ar, ag, ab, 0.22 * entry_val)
                else:
                    cr.set_source_rgba(out_r, out_g, out_b, 0.08 * entry_val)
                cr.fill()

                cr.new_path()
                cr.arc(core_x, core_y, 8.0, 0, 2 * math.pi)
                if active_idx is not None and active_idx < self.num_items:
                    ar, ag, ab = self.apps[active_idx]["color"]
                    cr.set_source_rgba(ar, ag, ab, 0.85 * entry_val)
                else:
                    cr.set_source_rgba(p["on_surface_var"][0], p["on_surface_var"][1], p["on_surface_var"][2], 0.40 * entry_val)
                cr.set_line_width(1.4)
                cr.stroke()

                cr.new_path()
                cr.arc(core_x, core_y, 3.2, 0, 2 * math.pi)
                if active_idx is not None and active_idx < self.num_items:
                    ar, ag, ab = self.apps[active_idx]["color"]
                    cr.set_source_rgba(ar, ag, ab, 1.0 * entry_val)
                else:
                    cr.set_source_rgba(p["on_surface"][0], p["on_surface"][1], p["on_surface"][2], 0.90 * entry_val)
                cr.fill()
                cr.restore()
            else:
                # 搜索胶囊。
                sw = 36.0 + (390.0 - 36.0) * search_prog
                sh = 36.0 + (64.0 - 36.0) * search_prog
                sr = sh / 2.0
                sx = cx - sw / 2.0
                sy = cy - sh / 2.0

                # 环境光晕。
                cr.save()
                halo_radius = (sw / 2.0) + 48.0
                pattern = cairo.RadialGradient(cx, cy, 10.0, cx, cy, halo_radius)
                pattern.add_color_stop_rgba(0.0, surf_r, surf_g, surf_b, 0.60 * search_prog * entry_val)
                pattern.add_color_stop_rgba(0.5, out_r, out_g, out_b, 0.15 * search_prog * entry_val)
                pattern.add_color_stop_rgba(1.0, 0.0, 0.0, 0.0, 0.0)
                cr.set_source(pattern)
                cr.arc(cx, cy, halo_radius, 0, 2 * math.pi)
                cr.fill()
                cr.restore()

                # 阴影。
                cr.save()
                self.draw_rounded_pill(cr, sx, sy + 4.0 * search_prog, sw, sh, sr)
                cr.set_source_rgba(0.0, 0.0, 0.0, (0.32 * search_prog) * entry_val)
                cr.fill()
                cr.restore()

                # 半透明磨砂表面。
                cr.save()
                self.draw_rounded_pill(cr, sx, sy, sw, sh, sr)
                fill_alpha = (0.92 + 0.06 * search_prog) * entry_val
                cr.set_source_rgba(surf_r, surf_g, surf_b, fill_alpha)
                cr.fill_preserve()

                out_alpha = (0.24 + 0.30 * search_prog) * entry_val
                cr.set_source_rgba(out_r, out_g, out_b, out_alpha)
                cr.set_line_width(1.2 + 0.3 * search_prog)
                cr.stroke()
                cr.restore()

                # 左侧搜索引擎图标。
                if search_prog > 0.25 and self.search_engines:
                    tag_fade = min(1.0, (search_prog - 0.25) / 0.75) * entry_val
                    cur_eng = self.search_engines[self.current_engine_idx % len(self.search_engines)]
                    eng_layout = cur_eng.get("layout")
                    ink_rect = cur_eng.get("icon_ink")

                    avatar_d = 44.0
                    avatar_r = avatar_d / 2.0
                    avatar_cx = sx + 10.0 + avatar_r
                    avatar_cy = cy

                    switch_prog = max(0.8, min(1.25, self.engine_switch_spring.current))
                    cr.save()
                    cr.translate(avatar_cx, avatar_cy)
                    cr.scale(switch_prog, switch_prog)
                    cr.translate(-avatar_cx, -avatar_cy)

                    # 图标背景。
                    cr.new_path()
                    cr.arc(avatar_cx, avatar_cy, avatar_r, 0, 2 * math.pi)
                    cr.set_source_rgba(dim_r, dim_g, dim_b, (0.55 + 0.15 * search_prog) * tag_fade)
                    cr.fill_preserve()
                    cr.set_source_rgba(out_r, out_g, out_b, (0.18 + 0.14 * search_prog) * tag_fade)
                    cr.set_line_width(1.0)
                    cr.stroke()

                    # 居中引擎图标。
                    if ink_rect:
                        draw_icon_x = avatar_cx - ink_rect.x - (ink_rect.width / 2.0)
                        draw_icon_y = avatar_cy - ink_rect.y - (ink_rect.height / 2.0)
                    else:
                        draw_icon_x = avatar_cx - 8.0
                        draw_icon_y = avatar_cy - 8.0

                    cr.move_to(draw_icon_x, draw_icon_y)
                    cr.set_source_rgba(p["on_surface"][0], p["on_surface"][1], p["on_surface"][2], tag_fade)
                    PangoCairo.show_layout(cr, eng_layout)
                    cr.restore()

                    # 搜索文本和光标。
                    text_start_x = avatar_cx + avatar_r + 14.0
                    avail_w = max(20.0, (sx + sw - 22.0) - text_start_x)

                    if self.search_query:
                        lt_query = self.create_pango_layout(self.search_query)
                        lt_query.set_font_description(Pango.FontDescription("Noto Sans CJK SC, Inter Bold 13.5"))
                        qw, qh = lt_query.get_pixel_size()

                        cr.save()
                        cr.rectangle(text_start_x, cy - sh / 2.0, avail_w, sh)
                        cr.clip()

                        draw_qx = text_start_x if qw <= avail_w else (text_start_x + avail_w - qw)
                        cr.move_to(draw_qx, cy - qh / 2.0)
                        cr.set_source_rgba(p["on_surface"][0], p["on_surface"][1], p["on_surface"][2], tag_fade)
                        PangoCairo.show_layout(cr, lt_query)
                        cr.restore()

                        # 光标呼吸动画。
                        cursor_x = min(draw_qx + qw + 2.0, sx + sw - 22.0)
                        sin_val = (math.sin(self.cursor_time * 5.5) + 1.0) / 2.0
                        cursor_alpha = (0.35 + 0.65 * sin_val) * tag_fade
                        cr.save()
                        cr.new_path()
                        cr.move_to(cursor_x, cy - 12.0)
                        cr.line_to(cursor_x, cy + 12.0)
                        cr.set_line_width(1.8)
                        cr.set_source_rgba(p["on_surface"][0], p["on_surface"][1], p["on_surface"][2], cursor_alpha)
                        cr.stroke()
                        cr.restore()

                        # 更新 IME 光标位置。
                        self.update_im_cursor_location(cursor_x, cy + 16.0)
                    else:
                        cr.save()
                        cr.move_to(text_start_x, cy - self.placeholder_h / 2.0)
                        cr.set_source_rgba(p["on_surface_var"][0], p["on_surface_var"][1], p["on_surface_var"][2], 0.48 * tag_fade)
                        PangoCairo.show_layout(cr, self.layout_placeholder)
                        cr.restore()

                        sin_val = (math.sin(self.cursor_time * 5.5) + 1.0) / 2.0
                        cursor_alpha = (0.35 + 0.65 * sin_val) * tag_fade
                        cr.save()
                        cr.new_path()
                        cr.move_to(text_start_x, cy - 12.0)
                        cr.line_to(text_start_x, cy + 12.0)
                        cr.set_line_width(1.8)
                        cr.set_source_rgba(p["on_surface"][0], p["on_surface"][1], p["on_surface"][2], cursor_alpha)
                        cr.stroke()
                        cr.restore()

                        # 更新空搜索状态的 IME 位置。
                        self.update_im_cursor_location(text_start_x, cy + 16.0)

        # 自适应内容胶囊。
        if outer_alpha > 0.01:
            for i, app in enumerate(self.apps):
                prog = max(0.0, min(1.0, self.node_springs[i].current)) if i < len(self.node_springs) else 0.0
                app_r, app_g, app_b = app["color"]
                ang_rad = math.radians(app["center_angle"])

                cur_dist = orbit_r + prog * FLOAT_SPRING
                ix, iy = cx + cur_dist * math.cos(ang_rad), cy + cur_dist * math.sin(ang_rad)

                tw, th = app["title_w"], app["title_h"]
                dw, dh = app["desc_w"], app["desc_h"]
                kw, kh = app["badge_w"], app["badge_h"]
                ink_rect = app["icon_ink_rect"]

                cw = app["idle_w"] + (app["active_w"] - app["idle_w"]) * prog
                ch = CAPSULE_IDLE_H + (CAPSULE_ACTIVE_H - CAPSULE_IDLE_H) * prog
                cr_radius = ch / 2.0

                cx_box = ix - cw / 2.0
                cy_box = iy - ch / 2.0

                cr.save()
                shadow_y = 2.5 + prog * 4.5
                self.draw_rounded_pill(cr, cx_box, cy_box + shadow_y, cw, ch, cr_radius)
                cr.set_source_rgba(0.0, 0.0, 0.0, (0.16 + 0.22 * prog) * outer_alpha)
                cr.fill()
                cr.restore()

                fill_r = surf_r + (app_r - surf_r) * (0.34 * prog)
                fill_g = surf_g + (app_g - surf_g) * (0.34 * prog)
                fill_b = surf_b + (app_b - surf_b) * (0.34 * prog)
                fill_alpha = ((0.88 if p["is_dark"] else 0.94) + 0.08 * prog) * outer_alpha

                self.draw_rounded_pill(cr, cx_box, cy_box, cw, ch, cr_radius)
                cr.set_source_rgba(fill_r, fill_g, fill_b, fill_alpha)
                cr.fill_preserve()

                b_r = out_r + (app_r - out_r) * prog
                b_g = out_g + (app_g - out_g) * prog
                b_b = out_b + (app_b - out_b) * prog
                b_alpha = (0.16 + prog * 0.74) * outer_alpha
                b_width = 1.0 + prog * 1.2

                cr.set_source_rgba(b_r, b_g, b_b, b_alpha)
                cr.set_line_width(b_width)
                cr.stroke()

                # 左侧图标。
                chip_cx = cx_box + (ch / 2.0)
                chip_cy = iy
                chip_r = 15.0 + 1.5 * prog

                cr.save()
                cr.new_path()
                cr.arc(chip_cx, chip_cy, chip_r, 0, 2 * math.pi)
                chip_bg_r = out_r + (app_r - out_r) * prog
                chip_bg_g = out_g + (app_g - out_g) * prog
                chip_bg_b = out_b + (app_b - out_b) * prog
                chip_bg_alpha = (0.10 + 0.78 * prog) * outer_alpha
                cr.set_source_rgba(chip_bg_r, chip_bg_g, chip_bg_b, chip_bg_alpha)
                cr.fill_preserve()
                cr.set_source_rgba(chip_bg_r, chip_bg_g, chip_bg_b, (0.18 + 0.65 * prog) * outer_alpha)
                cr.set_line_width(1.0)
                cr.stroke()
                cr.restore()

                cr.save()
                draw_icon_x = chip_cx - ink_rect.x - (ink_rect.width / 2.0)
                draw_icon_y = chip_cy - ink_rect.y - (ink_rect.height / 2.0)
                cr.move_to(draw_icon_x, draw_icon_y)

                if prog > 0.45:
                    cr.set_source_rgba(dim_r, dim_g, dim_b, 1.0 * outer_alpha) if p["is_dark"] else cr.set_source_rgba(1.0, 1.0, 1.0, 1.0 * outer_alpha)
                else:
                    cr.set_source_rgba(p["on_surface"][0], p["on_surface"][1], p["on_surface"][2], 0.94 * outer_alpha)
                PangoCairo.show_layout(cr, app["layout_icon"])
                cr.restore()

                # 标题和副标题。
                text_x = chip_cx + chip_r + 9.0

                if prog < 0.18:
                    title_y = iy - th / 2.0
                    cr.save()
                    cr.move_to(text_x, title_y)
                    cr.set_source_rgba(p["on_surface"][0], p["on_surface"][1], p["on_surface"][2], 0.90 * outer_alpha)
                    PangoCairo.show_layout(cr, app["layout_title"])
                    cr.restore()
                else:
                    title_y = iy - (th + dh + 1.0) / 2.0 + (1.0 - prog) * 2.0
                    desc_y = title_y + th + 1.0

                    cr.save()
                    cr.move_to(text_x, title_y)
                    cr.set_source_rgba(p["on_surface"][0], p["on_surface"][1], p["on_surface"][2], 0.98 * outer_alpha)
                    PangoCairo.show_layout(cr, app["layout_title"])

                    desc_alpha = min(1.0, (prog - 0.18) / 0.82) * 0.85 * outer_alpha
                    cr.move_to(text_x, desc_y)
                    cr.set_source_rgba(p["on_surface_var"][0], p["on_surface_var"][1], p["on_surface_var"][2], desc_alpha)
                    PangoCairo.show_layout(cr, app["layout_desc"])
                    cr.restore()

                # 快捷键标签。
                right_pad = 13.0
                key_x = cx_box + cw - right_pad - kw
                key_y = iy - kh / 2.0
                pill_w, pill_h = kw + 8.0, kh + 4.0
                pill_x, pill_y = key_x - 4.0, key_y - 2.0

                cr.save()
                self.draw_rounded_pill(cr, pill_x, pill_y, pill_w, pill_h, pill_h / 2.0)
                badge_bg_alpha = (0.12 + 0.18 * prog) * outer_alpha
                cr.set_source_rgba(p["on_surface_var"][0], p["on_surface_var"][1], p["on_surface_var"][2], badge_bg_alpha)
                cr.fill()

                cr.move_to(key_x, key_y)
                badge_text_alpha = (0.65 + 0.35 * prog) * outer_alpha
                cr.set_source_rgba(p["on_surface_var"][0], p["on_surface_var"][1], p["on_surface_var"][2], badge_text_alpha)
                PangoCairo.show_layout(cr, app["layout_badge"])
                cr.restore()

        cr.restore()
        return False
