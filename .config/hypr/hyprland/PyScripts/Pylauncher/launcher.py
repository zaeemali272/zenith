#!/usr/bin/env python3
import gi, os, json, sys, fnmatch
gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, Gio, GdkPixbuf, Gdk, GLib, Pango

# ---------------- SINGLE INSTANCE CHECK ---------------- #
LOCK_FILE = "/tmp/pylauncher.lock"

if os.path.exists(LOCK_FILE):
    try:
        with open(LOCK_FILE) as f:
            pid = int(f.read().strip())
        os.kill(pid, 9)
    except Exception:
        pass
    os.remove(LOCK_FILE)
    sys.exit(0)

with open(LOCK_FILE, "w") as f:
    f.write(str(os.getpid()))

# ---------------- CONFIG ---------------- #
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
CONFIG_FILE = os.path.join(SCRIPT_DIR, "config.json")
HIDE_APPS_FILE = os.path.join(SCRIPT_DIR, "hide_apps.txt")
CSS_FILE = os.path.join(SCRIPT_DIR, "style.css")

if os.path.exists(CONFIG_FILE):
    with open(CONFIG_FILE) as f:
        CONFIG = json.load(f)
else:
    print(f"[WARN] Config not found at {CONFIG_FILE}, using defaults.")
    CONFIG = {}

HIDE_NO_ICON_APPS = CONFIG.get("hide_no_icon_apps", True)
WINDOW_WIDTH = CONFIG.get("window_width", 900)
WINDOW_HEIGHT = CONFIG.get("window_height", 600)

# Read hidden patterns
if os.path.exists(HIDE_APPS_FILE):
    with open(HIDE_APPS_FILE) as f:
        HIDDEN_PATTERNS = [line.strip().lower() for line in f if line.strip()]
else:
    HIDDEN_PATTERNS = []

def is_hidden_app(name):
    """Check if the given app name matches any pattern in hide_apps.txt"""
    lname = name.lower()
    for pattern in HIDDEN_PATTERNS:
        if fnmatch.fnmatch(lname, pattern):
            return True
    return False


# ---------------- MAIN CLASS ---------------- #
class AppLauncher(Gtk.Window):
    def __init__(self):
        super().__init__(title="Launcher")
        self.set_wmclass("launcher", "launcher")
        self.set_default_size(WINDOW_WIDTH, WINDOW_HEIGHT)
        self.set_border_width(0)
        self.set_focus_on_map(False)
        self.set_name("launcher-window")

        self.connect("focus-out-event", self.on_focus_out)

        self.main_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=0)
        self.add(self.main_box)

        self.content_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=CONFIG.get("apps_spacing", 8))
        for side in ("start", "end", "top", "bottom"):
            getattr(self.content_box, f"set_margin_{side}")(10)
        self.main_box.pack_start(self.content_box, True, True, 0)

        self.fav_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=CONFIG.get("apps_spacing", 8))
        self.content_box.pack_start(self.fav_box, False, False, 0)
        self.load_favorites()

        self.search_visible_setting = CONFIG.get("show_search", True)
        self.search = Gtk.SearchEntry()
        self.search.set_size_request(-1, CONFIG.get("search_height", 36))
        self.search.connect("search-changed", self.on_search)
        self.search.connect("focus-out-event", self.on_search_focus_out)
        self.content_box.pack_start(self.search, False, False, 0)

        self.scrolled = Gtk.ScrolledWindow()
        self.scrolled.set_shadow_type(Gtk.ShadowType.NONE)
        self.scrolled.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        self.content_box.pack_start(self.scrolled, True, True, 0)

        self.flow = Gtk.FlowBox()
        self.flow.set_valign(Gtk.Align.START)
        self.flow.set_halign(Gtk.Align.CENTER)
        self.flow.set_max_children_per_line(100)
        self.flow.set_selection_mode(Gtk.SelectionMode.NONE)
        self.flow.set_homogeneous(True)
        self.flow.set_row_spacing(CONFIG.get("apps_spacing", 12))
        self.flow.set_column_spacing(CONFIG.get("apps_spacing", 12))
        self.flow.set_min_children_per_line(1)
        self.flow.set_activate_on_single_click(True)
        self.scrolled.add(self.flow)

        self.app_buttons = []
        self.first_visible_app = None

        self.load_apps()

        self.flow.set_filter_func(self.filter_func, None)
        self.flow.show_all()

        self.connect("map-event", self.on_window_mapped)
        self.connect("key-press-event", self.on_window_key_press)
        self.connect("destroy", self.cleanup)

        if not self.search_visible_setting:
            GLib.idle_add(self.search.hide)

    def cleanup(self, *args):
        try:
            os.remove(LOCK_FILE)
        except Exception:
            pass

    def on_focus_out(self, *args):
        Gtk.main_quit()
        return True

    def on_window_mapped(self, *args):
        GLib.idle_add(self.force_focus_clear)
        return False

    def force_focus_clear(self):
        self.set_focus(None)
        self.search.set_can_focus(True)
        return False

    # ---------------- LOAD APPS ---------------- #
    def load_apps(self):
        theme = Gtk.IconTheme.get_default()
        seen = set()
        kdeconnect_main = False

        app_dirs = [
            os.path.expanduser("~/.local/share/applications"),
            "/usr/share/applications",
            "/var/lib/flatpak/exports/share/applications",
        ]

        desktop_files = []
        for d in app_dirs:
            if os.path.isdir(d):
                for f in os.listdir(d):
                    if f.endswith(".desktop"):
                        desktop_files.append(os.path.join(d, f))

        for f in desktop_files:
            try:
                app = Gio.DesktopAppInfo.new_from_filename(f)
                if not app:
                    continue
            except Exception:
                continue

            label = app.get_name()
            exe = (app.get_executable() or "").lower()
            if not label:
                continue

            is_hidden = is_hidden_app(label)

            if "kdeconnect" in exe or "kde connect" in label.lower():
                if "sms" in exe or "indicator" in exe:
                    continue
                if kdeconnect_main:
                    continue
                kdeconnect_main = True

            if any(x in f for x in ("/var/lib/flatpak/", "/snap/", "wine/Programs/")):
                continue

            key = (label.lower().strip(), exe.replace("/usr/bin/", "").replace("/bin/", "").strip())
            if key in seen:
                continue
            seen.add(key)

            img = self.get_app_icon(app, theme)
            if HIDE_NO_ICON_APPS and img is None:
                continue

            btn = self.add_app_button(app, label, img)
            btn.is_hidden = is_hidden
            self.app_buttons.append((label.lower(), btn))

    def load_favorites(self):
        theme = Gtk.IconTheme.get_default()
        seen = set()
        for f in CONFIG.get("favorites", []):
            paths = [
                os.path.join("/usr/share/applications", f),
                os.path.join(os.path.expanduser("~/.local/share/applications"), f),
            ]
            app = next((Gio.DesktopAppInfo.new_from_filename(p) for p in paths if os.path.exists(p)), None)
            if not app:
                continue
            label = app.get_name()
            if not label or is_hidden_app(label) or label in seen:
                continue
            seen.add(label)

            img = self.get_app_icon(app, theme)
            if HIDE_NO_ICON_APPS and img is None:
                continue

            btn = self.create_app_button(app, label, img)
            self.fav_box.pack_start(btn, False, False, 0)

    def create_app_button(self, app, label, img):
        btn = Gtk.Button()
        btn.set_relief(Gtk.ReliefStyle.NONE)
        btn.set_halign(Gtk.Align.CENTER)
        btn.set_valign(Gtk.Align.CENTER)
        btn.set_size_request(
            CONFIG.get("icon_size", 72) + CONFIG.get("apps_padding", 10) * 2,
            CONFIG.get("icon_size", 72) + CONFIG.get("apps_padding", 10) * 2 +
            (CONFIG.get("font_size", 12) if CONFIG.get("show_labels", True) else 0)
        )
        btn.connect("clicked", lambda w, a=app: self.launch_and_close(a))
        btn.app_ref = app

        # container inside button
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        box.set_halign(Gtk.Align.CENTER)
        box.set_valign(Gtk.Align.CENTER)
        box.set_hexpand(True)
        box.set_vexpand(True)

        # icon
        if img:
            box.pack_start(img, True, True, 0)

        # label
        if CONFIG.get("show_labels", True):
            lbl = Gtk.Label(label=label)
            lbl.set_justify(Gtk.Justification.CENTER)
            lbl.set_ellipsize(Pango.EllipsizeMode.END)
            lbl.set_max_width_chars(18)
            lbl.set_lines(2)
            lbl.set_line_wrap(True)
            lbl.set_line_wrap_mode(Pango.WrapMode.WORD_CHAR)
            lbl.set_halign(Gtk.Align.CENTER)
            lbl.set_valign(Gtk.Align.CENTER)
            box.pack_start(lbl, False, False, 0)

        btn.add(box)
        return btn

    def launch_and_close(self, app):
        app.launch([], None)
        Gtk.main_quit()

    def add_app_button(self, app, label, img):
        btn = self.create_app_button(app, label, img)
        self.flow.add(btn)
        return btn

    def get_app_icon(self, app, theme):
        icon = app.get_icon()
        if isinstance(icon, Gio.ThemedIcon):
            for name in icon.get_names():
                if theme.has_icon(name):
                    try:
                        pixbuf = theme.load_icon(name, CONFIG.get("icon_size", 64), 0)
                        return Gtk.Image.new_from_pixbuf(pixbuf)
                    except Exception:
                        continue
        elif isinstance(icon, Gio.FileIcon):
            path = icon.get_file().get_path()
            if path and os.path.exists(path):
                try:
                    pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_size(
                        path, CONFIG.get("icon_size", 64), CONFIG.get("icon_size", 64)
                    )
                    return Gtk.Image.new_from_pixbuf(pixbuf)
                except Exception:
                    pass
        return None

    def filter_func(self, child, data):
        btn = child.get_child()
        query = self.search.get_text().lower().strip()

        if hasattr(btn, "is_hidden") and btn.is_hidden and not query:
            return False

        if not query:
            return True

        for label, b in self.app_buttons:
            if b is btn:
                return query in label
        return False

    def on_search(self, widget):
        self.flow.invalidate_filter()
        GLib.idle_add(self._update_first_visible_after_filter)

    def _update_first_visible_after_filter(self):
        self.first_visible_app = None
        for child in self.flow.get_children():
            if child.get_visible():
                self.first_visible_app = child.get_child()
                break
        return False

    def on_search_focus_out(self, widget, event):
        Gtk.main_quit()
        return False

    def on_window_key_press(self, widget, event):
        keyname = Gdk.keyval_name(event.keyval)
        if not keyname:
            return False

        if keyname == "Escape":
            Gtk.main_quit()
            return True

        if keyname == "Return":
            if self.first_visible_app and self.first_visible_app.get_visible():
                self.first_visible_app.app_ref.launch([], None)
                Gtk.main_quit()
                return True

        if len(keyname) == 1 and keyname.isprintable():
            if not self.search_visible_setting and not self.search.get_visible():
                self.search.show()
            if self.search.is_focus():
                return False
            code = Gdk.keyval_to_unicode(event.keyval)
            ch = chr(code) if code and code != 0 else None
            if ch:
                cur = self.search.get_text()
                self.search.set_text(cur + ch)
                self.search.set_position(len(cur) + 1)
                self.on_search(self.search)
            self.search.grab_focus()
            return True

        return False


# ---------------- LOAD CSS ---------------- #
if os.path.exists(CSS_FILE):
    provider = Gtk.CssProvider()
    provider.load_from_path(CSS_FILE)
    Gtk.StyleContext.add_provider_for_screen(Gdk.Screen.get_default(), provider, Gtk.STYLE_PROVIDER_PRIORITY_USER)

# ---------------- RUN ---------------- #
win = AppLauncher()
win.connect("destroy", Gtk.main_quit)
win.show_all()
Gtk.main()

