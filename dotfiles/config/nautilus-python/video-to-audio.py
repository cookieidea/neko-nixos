#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
# NAME: Video to Audio — Nautilus Python Extension
# DESC: Extract audio from video files using ffmpeg
# AUTHOR: Tof
# VERSION: 1.0
# LICENSE: GNU General Public License v3.0
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# INSTALL:
#   cp video-to-audio.py ~/.local/share/nautilus-python/extensions/
#   nautilus -q

import os
import shutil
import subprocess
import threading
import locale
import re
import traceback

_LOG = os.path.join(os.path.expanduser("~"), ".cache",
                    "nautilus-video-to-audio.log")

def _log(msg):
    try:
        with open(_LOG, "a", encoding="utf-8") as f:
            f.write(msg + "\n")
    except Exception:
        pass

import gi
gi.require_version("Gtk",     "4.0")
gi.require_version("Adw",     "1")
# Nautilus typelib 已由 libnautilus-python.so 加载，不再重复 require
from gi.repository import GObject, Gtk, Adw, GLib, Pango, Gdk, Nautilus

# ---------------------------------------------------------------------------
# i18n
# ---------------------------------------------------------------------------
def _detect_lang():
    """nautilus-python 内嵌解释器 locale 常未初始化（getlocale → None），
    回退读 LANG/LANGUAGE/LC_ALL 环境变量。"""
    try:
        lang = locale.getlocale()[0] or ""
    except Exception:
        lang = ""
    if not lang:
        lang = (os.environ.get("LANG", "") or os.environ.get("LANGUAGE", "")
                or os.environ.get("LC_ALL", ""))
    return lang

_lang = _detect_lang()

if _lang.startswith("zh"):
    T = {
        "menu_label":   "提取音频",
        "title":        "音频提取",
        "format":       "格式",
        "quality":      "质量",
        "quality_high": "高质量 (320 kbps)",
        "quality_med":  "中等 (192 kbps)",
        "quality_low":  "低质量 (128 kbps)",
        "quality_copy": "直接复制（不重新编码）",
        "convert":      "提取",
        "cancel":       "取消",
        "close":        "关闭",
        "processing":   "正在提取…",
        "file_done":    "✓ {name}",
        "file_error":   "✗ {name}",
        "all_done":     "提取完成 — {ok}/{total} 个文件成功。",
        "cancelled":    "提取已取消。",
        "overwrite":    "文件已存在，将被覆盖。",
        "dest_folder":  "目标文件夹",
        "choose":       "选择…",
        "same_as_src":  "与源文件相同目录",
        "no_audio":     "无音频轨道，跳过",
        "no_audio_all": "所选视频都没有音频轨道，无法提取。",
        "skipped_suffix": "（{n} 个无音频轨道已跳过）",
    }
elif _lang.startswith("fr"):
    T = {
        "menu_label":   "Extraire l'audio",
        "title":        "Extraction audio",
        "format":       "Format",
        "quality":      "Qualité",
        "quality_high": "Haute (320 kbps)",
        "quality_med":  "Moyenne (192 kbps)",
        "quality_low":  "Basse (128 kbps)",
        "quality_copy": "Copier le flux (sans réencodage)",
        "convert":      "Extraire",
        "cancel":       "Annuler",
        "close":        "Fermer",
        "processing":   "Extraction en cours…",
        "file_done":    "✓ {name}",
        "file_error":   "✗ {name}",
        "all_done":     "Extraction terminée — {ok} sur {total} réussie(s).",
        "cancelled":    "Extraction annulée.",
        "overwrite":    "Le fichier existe déjà — il sera écrasé.",
        "dest_folder":  "Destination",
        "choose":       "Choisir…",
        "same_as_src":  "Même dossier que la source",
        "no_audio":     "Pas de piste audio, ignoré",
        "no_audio_all": "Aucune des vidéos sélectionnées ne contient de piste audio.",
        "skipped_suffix": "({n} sans piste audio ignorée(s))",
    }
elif _lang.startswith("de"):
    T = {
        "menu_label":   "Audio extrahieren",
        "title":        "Audio-Extraktion",
        "format":       "Format",
        "quality":      "Qualität",
        "quality_high": "Hoch (320 kbps)",
        "quality_med":  "Mittel (192 kbps)",
        "quality_low":  "Niedrig (128 kbps)",
        "quality_copy": "Stream kopieren (ohne Neukodierung)",
        "convert":      "Extrahieren",
        "cancel":       "Abbrechen",
        "close":        "Schließen",
        "processing":   "Extraktion läuft…",
        "file_done":    "✓ {name}",
        "file_error":   "✗ {name}",
        "all_done":     "Extraktion abgeschlossen — {ok} von {total} erfolgreich.",
        "cancelled":    "Extraktion abgebrochen.",
        "overwrite":    "Datei existiert bereits — wird überschrieben.",
        "dest_folder":  "Ziel",
        "choose":       "Wählen…",
        "same_as_src":  "Gleicher Ordner wie Quelle",
        "no_audio":     "Keine Audiospur, übersprungen",
        "no_audio_all": "Keines der ausgewählten Videos enthält eine Audiospur.",
        "skipped_suffix": "({n} ohne Audiospur übersprungen)",
    }
else:
    T = {
        "menu_label":   "Extract audio",
        "title":        "Audio Extraction",
        "format":       "Format",
        "quality":      "Quality",
        "quality_high": "High (320 kbps)",
        "quality_med":  "Medium (192 kbps)",
        "quality_low":  "Low (128 kbps)",
        "quality_copy": "Copy stream (no re-encoding)",
        "convert":      "Extract",
        "cancel":       "Cancel",
        "close":        "Close",
        "processing":   "Extracting…",
        "file_done":    "✓ {name}",
        "file_error":   "✗ {name}",
        "all_done":     "Extraction complete — {ok} of {total} succeeded.",
        "cancelled":    "Extraction cancelled.",
        "overwrite":    "File already exists — will be overwritten.",
        "dest_folder":  "Destination",
        "choose":       "Choose…",
        "same_as_src":  "Same folder as source",
        "no_audio":     "No audio track, skipped",
        "no_audio_all": "None of the selected videos have an audio track.",
        "skipped_suffix": "({n} skipped, no audio track)",
    }

# Extensions vidéo supportées
VIDEO_EXTS = {".mp4", ".mkv", ".avi", ".mov", ".webm", ".flv", ".wmv",
               ".m4v", ".mpg", ".mpeg", ".3gp", ".3g2", ".ts", ".m2ts",
               ".mts", ".m2t", ".mxf", ".ogv", ".vob", ".rmvb", ".rm",
               ".f4v", ".asf", ".dv", ".divx"}

# Formats audio disponibles (extension, codec ffmpeg)
AUDIO_FORMATS = [
    ("mp3",  "libmp3lame"),
    ("m4a",  "aac"),
    ("ogg",  "libvorbis"),
    ("opus", "libopus"),
    ("flac", "flac"),
    ("wav",  "pcm_s16le"),
]

QUALITIES = ["high", "medium", "low", "copy"]
QUALITY_BITRATES = {"high": "320k", "medium": "192k", "low": "128k"}


def _nautilus_window():
    app = Gtk.Application.get_default()
    return app.get_active_window() if app else None


def _get_duration(path):
    """Retourne la durée en secondes d'un fichier vidéo via ffprobe."""
    try:
        out = subprocess.check_output(
            ["ffprobe", "-v", "error", "-show_entries", "format=duration",
             "-of", "default=noprint_wrappers=1:nokey=1", path],
            stderr=subprocess.DEVNULL).decode().strip()
        return float(out)
    except Exception:
        return 0.0


def _parse_time(time_str):
    """Parse HH:MM:SS.mm en secondes."""
    try:
        h, m, s = time_str.split(":")
        return int(h) * 3600 + int(m) * 60 + float(s)
    except Exception:
        return 0.0


def _has_audio(path):
    """视频是否含音频流（无音轨则 ffmpeg 提取必失败，提前告知）。"""
    try:
        out = subprocess.check_output(
            ["ffprobe", "-v", "error", "-select_streams", "a",
             "-show_entries", "stream=index",
             "-of", "csv=p=0", path],
            stderr=subprocess.DEVNULL).decode().strip()
        return bool(out)
    except Exception:
        return False


# ---------------------------------------------------------------------------
# CSS (option cards) — installé une seule fois
# ---------------------------------------------------------------------------
_CSS_INSTALLED = False

_CSS = b"""
.v2a-card {
    border: 1px solid @borders;
    border-radius: 11px;
    padding: 7px 10px 9px 12px;
    background-color: alpha(@window_fg_color, 0.025);
}
.v2a-card > label {
    font-size: 0.80em;
    opacity: 0.65;
    margin-bottom: 1px;
}
.v2a-card dropdown,
.v2a-card button.v2a-flat {
    background: none;
    background-image: none;
    border: none;
    box-shadow: none;
    outline: none;
    min-height: 30px;
    padding: 2px 4px;
    font-weight: 600;
}
.v2a-card dropdown:hover,
.v2a-card button.v2a-flat:hover {
    background-color: alpha(@window_fg_color, 0.07);
    border-radius: 7px;
}
.v2a-card button.v2a-flat {
    padding-left: 2px;
}
"""

def _install_css():
    global _CSS_INSTALLED
    if _CSS_INSTALLED:
        return
    try:
        provider = Gtk.CssProvider()
        try:
            provider.load_from_data(_CSS)
        except TypeError:
            provider.load_from_data(_CSS.decode("utf-8"), -1)
        Gtk.StyleContext.add_provider_for_display(
            Gdk.Display.get_default(), provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)
        _CSS_INSTALLED = True
    except Exception:
        pass


# ---------------------------------------------------------------------------
# Window
# ---------------------------------------------------------------------------

class VideoToAudioWindow(Adw.Window):
    __gtype_name__ = "VideoToAudioWindow"

    def __init__(self, video_files):
        super().__init__(title=T["title"])
        _install_css()
        self.set_default_size(560, 480)
        self.set_resizable(True)
        self.set_transient_for(_nautilus_window())
        self._videos    = video_files
        self._process   = None
        self._cancelled = False
        self._done      = False

        tv  = Adw.ToolbarView()
        hdr = Adw.HeaderBar()
        hdr.set_decoration_layout(":close")
        hdr.set_title_widget(Gtk.Label(label=T["title"]))
        tv.add_top_bar(hdr)

        main = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)

        # ── Options (3 colonnes alignées) ─────────────────────────────────────
        opts = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        opts.set_margin_start(16); opts.set_margin_end(16)
        opts.set_margin_top(14); opts.set_margin_bottom(10)
        opts.set_homogeneous(True)

        def _opt_col(label_text):
            col = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
            col.set_hexpand(True)
            col.add_css_class("v2a-card")
            lbl = Gtk.Label(label=label_text)
            lbl.set_halign(Gtk.Align.START)
            col.append(lbl)
            return col

        # Format
        self._dest_folder = None  # None = même dossier que la source
        fmt_col = _opt_col(T["format"])
        self._fmt_drop = Gtk.DropDown.new_from_strings(
            [f[0].upper() for f in AUDIO_FORMATS])
        self._fmt_drop.set_selected(0)  # mp3 par défaut
        self._fmt_drop.set_hexpand(True)
        self._fmt_drop.connect("notify::selected", self._on_fmt_changed)
        fmt_col.append(self._fmt_drop)
        opts.append(fmt_col)

        # Qualité
        qual_col = _opt_col(T["quality"])
        self._qual_drop = Gtk.DropDown.new_from_strings([
            T["quality_high"], T["quality_med"], T["quality_low"], T["quality_copy"]
        ])
        self._qual_drop.set_selected(0)
        self._qual_drop.set_hexpand(True)
        qual_col.append(self._qual_drop)
        opts.append(qual_col)

        # Dossier de destination
        dest_col = _opt_col(T["dest_folder"])
        self._dest_btn = Gtk.Button(label=T["same_as_src"])
        self._dest_btn.set_hexpand(True)
        self._dest_btn.add_css_class("v2a-flat")
        self._dest_btn.set_halign(Gtk.Align.FILL)
        child = self._dest_btn.get_child()
        if isinstance(child, Gtk.Label):
            child.set_halign(Gtk.Align.START)
            child.set_ellipsize(Pango.EllipsizeMode.MIDDLE)
            child.set_max_width_chars(14)
        self._dest_btn.connect("clicked", self._on_choose_folder)
        dest_col.append(self._dest_btn)
        opts.append(dest_col)

        main.append(opts)
        main.append(Gtk.Separator())

        # ── Liste des fichiers ────────────────────────────────────────────────
        files_label = Gtk.Label()
        if _lang.startswith("zh"):
            files_label.set_markup(f"<b>{len(video_files)} 个文件</b>")
        elif _lang.startswith("fr"):
            files_label.set_markup(f"<b>{len(video_files)} fichier(s)</b>")
        else:
            files_label.set_markup(f"<b>{len(video_files)} file(s)</b>")
        files_label.set_halign(Gtk.Align.START)
        files_label.set_margin_start(16); files_label.set_margin_end(16)
        files_label.set_margin_top(8)
        main.append(files_label)

        scroll = Gtk.ScrolledWindow()
        scroll.set_vexpand(True)
        scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        scroll.set_margin_start(16); scroll.set_margin_end(16)
        scroll.set_margin_top(4); scroll.set_margin_bottom(8)

        self._files_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
        self._file_labels = []
        for video in video_files:
            row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
            status = Gtk.Label(label="•")
            status.set_size_request(20, -1)
            status.add_css_class("dim-label")
            row.append(status)
            name = Gtk.Label(label=os.path.basename(video))
            name.set_halign(Gtk.Align.START)
            name.set_ellipsize(Pango.EllipsizeMode.MIDDLE)
            name.set_hexpand(True)
            row.append(name)
            self._files_box.append(row)
            self._file_labels.append(status)

        scroll.set_child(self._files_box)
        main.append(scroll)

        # ── Progression ───────────────────────────────────────────────────────
        self._progress = Gtk.ProgressBar()
        self._progress.set_margin_start(16); self._progress.set_margin_end(16)
        self._progress.set_margin_bottom(4)
        self._progress.set_visible(False)
        main.append(self._progress)

        main.append(Gtk.Separator())

        # ── Boutons ───────────────────────────────────────────────────────────
        bottom = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        bottom.set_margin_start(12); bottom.set_margin_end(12)
        bottom.set_margin_top(8); bottom.set_margin_bottom(8)

        self._status = Gtk.Label(label="")
        self._status.set_halign(Gtk.Align.START)
        self._status.set_hexpand(True)
        self._status.set_wrap(True)
        bottom.append(self._status)

        self._btn_cancel = Gtk.Button(label=T["cancel"])
        self._btn_cancel.connect("clicked", self._on_cancel)
        bottom.append(self._btn_cancel)

        self._btn_convert = Gtk.Button(label=T["convert"])
        self._btn_convert.add_css_class("suggested-action")
        self._btn_convert.connect("clicked", self._on_convert)
        bottom.append(self._btn_convert)

        self._btn_close = Gtk.Button(label=T["close"])
        self._btn_close.set_visible(False)
        self._btn_close.connect("clicked", lambda _: self.close())
        bottom.append(self._btn_close)

        main.append(bottom)
        tv.set_content(main)
        self.set_content(tv)

    def _on_fmt_changed(self, drop, _param):
        """FLAC et WAV → forcer 'copy' désactivé car incompatible avec ces codecs."""
        pass

    def _on_choose_folder(self, _btn):
        """Ouvre un sélecteur de dossier."""
        dialog = Gtk.FileDialog()
        dialog.set_title(T["dest_folder"])
        # Dossier par défaut = dossier du premier fichier source
        if self._videos:
            from gi.repository import Gio
            initial = Gio.File.new_for_path(os.path.dirname(self._videos[0]))
            dialog.set_initial_folder(initial)
        dialog.select_folder(self, None, self._on_folder_selected)

    def _on_folder_selected(self, dialog, result):
        try:
            folder = dialog.select_folder_finish(result)
            if folder:
                self._dest_folder = folder.get_path()
                # Afficher le nom du dossier (ou chemin court)
                name = os.path.basename(self._dest_folder) or self._dest_folder
                self._dest_btn.set_label(name)
        except Exception:
            pass

    def _on_convert(self, _):
        self._btn_convert.set_sensitive(False)
        self._fmt_drop.set_sensitive(False)
        self._qual_drop.set_sensitive(False)
        self._progress.set_visible(True)
        self._status.set_text(T["processing"])
        # GTK 控件只能在主线程读：先取值再起工作线程（跨线程读会导致崩溃）
        fmt_idx = self._fmt_drop.get_selected()
        qual_idx = self._qual_drop.get_selected()
        dest_folder = self._dest_folder
        threading.Thread(target=self._run_conversions,
                         args=(fmt_idx, qual_idx, dest_folder),
                         daemon=True).start()

    def _run_conversions(self, fmt_idx, qual_idx, dest_folder):
        try:
            self.__run_conversions(fmt_idx, qual_idx, dest_folder)
        except Exception:
            _log(traceback.format_exc())
            GLib.idle_add(self._on_done, 0, len(self._videos), 0)

    def __run_conversions(self, fmt_idx, qual_idx, dest_folder):
        ext, codec = AUDIO_FORMATS[fmt_idx]
        quality    = QUALITIES[qual_idx]

        total = len(self._videos)
        ok    = 0
        skipped = 0
        time_re = re.compile(r"time=(\d+:\d+:\d+\.\d+)")

        for i, video in enumerate(self._videos):
            if self._cancelled:
                break

            src_dir   = os.path.dirname(video)
            dest_dir  = dest_folder if dest_folder else src_dir
            name      = os.path.splitext(os.path.basename(video))[0]
            output    = os.path.join(dest_dir, f"{name}.{ext}")

            if not _has_audio(video):
                skipped += 1
                GLib.idle_add(self._mark_skipped, i)
                GLib.idle_add(self._update_progress, (i + 1) / total, 1.0)
                continue

            duration  = _get_duration(video)

            cmd = ["ffmpeg", "-y", "-i", video, "-vn", "-progress", "pipe:1",
                   "-nostats"]
            if quality == "copy":
                cmd += ["-acodec", "copy"]
            else:
                cmd += ["-acodec", codec, "-b:a", QUALITY_BITRATES[quality]]
            cmd.append(output)

            try:
                self._process = subprocess.Popen(
                    cmd,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    text=True,
                    bufsize=1,
                    start_new_session=True,
                )
                # Lire la sortie ligne par ligne pour parser la progression
                for line in self._process.stdout:
                    if self._cancelled:
                        break
                    # ffmpeg avec -progress : lignes "out_time=00:00:12.34"
                    if "out_time=" in line:
                        ts = line.split("=", 1)[1].strip()
                        if ts and ts != "N/A":
                            cur = _parse_time(ts)
                            if duration > 0:
                                file_frac = min(cur / duration, 1.0)
                                overall = (i + file_frac) / total
                                GLib.idle_add(self._update_progress, overall, file_frac)
                self._process.wait()
                rc = self._process.returncode
                success = (rc == 0 and not self._cancelled)
            except Exception:
                success = False

            GLib.idle_add(self._update_file_status, i, success)
            if success:
                ok += 1
            GLib.idle_add(self._update_progress, (i + 1) / total, 1.0)

        GLib.idle_add(self._on_done, ok, total, skipped)

    def _mark_skipped(self, idx):
        lbl = self._file_labels[idx]
        lbl.set_text("–")
        lbl.add_css_class("dim-label")
        return False

    def _set_status_text(self, text):
        self._status.set_text(text)
        return False

    def _update_progress(self, overall, file_frac):
        self._progress.set_fraction(overall)
        self._progress.set_text(f"{int(overall * 100)} %")
        self._progress.set_show_text(True)
        return False

    def _update_file_status(self, idx, success):
        lbl = self._file_labels[idx]
        if success:
            lbl.set_text("✓")
            lbl.add_css_class("success")
        else:
            lbl.set_text("✗")
            lbl.add_css_class("error")
        return False

    def _on_done(self, ok, total, skipped=0):
        self._done = True
        self._progress.set_visible(False)
        self._btn_cancel.set_visible(False)
        self._btn_convert.set_visible(False)
        self._btn_close.set_visible(True)
        if self._cancelled:
            self._status.set_text(T["cancelled"])
        elif skipped >= total:
            self._status.set_text(T["no_audio_all"])
        else:
            msg = T["all_done"].format(ok=ok, total=total)
            if skipped:
                msg += T["skipped_suffix"].format(n=skipped)
            self._status.set_text(msg)
        return False

    def _on_cancel(self, _):
        self._cancelled = True
        if self._process and self._process.poll() is None:
            try:
                import signal
                os.killpg(os.getpgid(self._process.pid), signal.SIGKILL)
            except Exception:
                try:
                    self._process.kill()
                except Exception:
                    pass
        if not self._done:
            self.close()


# ---------------------------------------------------------------------------
# Nautilus Extension
# ---------------------------------------------------------------------------

class VideoToAudioExtension(GObject.GObject, Nautilus.MenuProvider):
    __gtype_name__ = "VideoToAudioExtension"

    def __init__(self):
        super().__init__()
        # 保持已打开窗口的引用，防止 Python GC 提前销毁窗口
        self._windows = []

    def _open_window(self, videos):
        try:
            win = VideoToAudioWindow(videos)
        except Exception:
            _log(traceback.format_exc())
            return
        self._windows.append(win)
        win.connect("close-request", lambda w: self._windows.remove(w))
        win.present()

    def get_file_items(self, files):
        if not files:
            return []
        # Filtrer les vidéos
        videos = []
        for f in files:
            if f.get_uri_scheme() != "file":
                return []
            if f.is_directory():
                return []
            path = f.get_location().get_path()
            if not path:
                continue
            ext = os.path.splitext(path)[1].lower()
            if ext not in VIDEO_EXTS:
                return []
            videos.append(path)

        if not videos:
            return []

        item = Nautilus.MenuItem(
            name  = "VideoToAudio::Extract",
            label = T["menu_label"],
            tip   = "Extract audio track from video files",
            icon  = "audio-x-generic-symbolic",
        )
        item.connect("activate", lambda *_: self._open_window(videos))
        return [item]

    def get_background_items(self, folder):
        return []
