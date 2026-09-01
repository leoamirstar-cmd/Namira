import json
import os
import threading
import urllib.request
import urllib.error

from kivy.app import App
from kivy.clock import Clock
from kivy.metrics import dp
from kivy.properties import BooleanProperty, NumericProperty, ListProperty
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.button import Button
from kivy.uix.label import Label
from kivy.uix.scrollview import ScrollView
from kivy.uix.textinput import TextInput
from kivy.uix.screenmanager import ScreenManager, Screen
from kivy.graphics import Color, RoundedRectangle


# ============================================================
# CONFIG
# ============================================================

HISTORY_FILE = "namira_history.json"

API_KEY = "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"

API_URL = "https://api.groq.com/openai/v1/chat/completions"
MODEL_NAME = "llama3-70b-8192"


# ============================================================
# THEME
# ============================================================

THEMES = {
    "light": {
        "background": (0.96, 0.97, 0.99, 1),
        "surface": (1, 1, 1, 1),
        "primary": (0.10, 0.45, 0.90, 1),
        "text": (0.08, 0.10, 0.14, 1),
        "secondary_text": (0.40, 0.44, 0.50, 1),
        "user_bubble": (0.10, 0.45, 0.90, 1),
        "user_text": (1, 1, 1, 1),
        "ai_bubble": (0.90, 0.94, 1.00, 1),
        "ai_text": (0.08, 0.10, 0.14, 1),
        "input": (1, 1, 1, 1),
    },

    "dark": {
        "background": (0.055, 0.065, 0.085, 1),
        "surface": (0.09, 0.105, 0.14, 1),
        "primary": (0.20, 0.55, 1.00, 1),
        "text": (0.94, 0.96, 1, 1),
        "secondary_text": (0.65, 0.68, 0.75, 1),
        "user_bubble": (0.12, 0.45, 0.85, 1),
        "user_text": (1, 1, 1, 1),
        "ai_bubble": (0.15, 0.18, 0.23, 1),
        "ai_text": (0.93, 0.95, 1, 1),
        "input": (0.12, 0.14, 0.18, 1),
    }
}


# ============================================================
# HELPERS
# ============================================================

def rgba(color):
    return tuple(color)


# ============================================================
# CHAT BUBBLE
# ============================================================

class ChatBubble(BoxLayout):

    def __init__(self, text, is_user=True, font_size=14, **kwargs):
        super().__init__(**kwargs)

        self.is_user = is_user
        self.text = text
        self.font_size_value = font_size

        self.orientation = "horizontal"
        self.size_hint_y = None
        self.padding = [dp(8), dp(4)]

        # Bubble container
        self.bubble = BoxLayout(
            orientation="vertical",
            size_hint_x=None,
            size_hint_y=None,
            padding=[dp(12), dp(8)],
        )

        # Text
        self.label = Label(
            text=text,
            font_size=f"{font_size}sp",
            color=(1, 1, 1, 1),
            halign="right" if is_user else "left",
            valign="middle",
            size_hint_y=None,
            text_size=(None, None),
        )

        self.bubble.add_widget(self.label)

        # Spacer
        if is_user:
            self.add_widget(BoxLayout(size_hint_x=1))
            self.add_widget(self.bubble)
        else:
            self.add_widget(self.bubble)
            self.add_widget(BoxLayout(size_hint_x=1))

        # Background
        with self.bubble.canvas.before:
            self.bg_color = Color(1, 1, 1, 1)
            self.bg_rect = RoundedRectangle(
                pos=self.bubble.pos,
                size=self.bubble.size,
                radius=[dp(14)]
            )

        self.bind(size=self.update_layout)
        self.bubble.bind(pos=self.update_background)
        self.bubble.bind(size=self.update_background)

        Clock.schedule_once(lambda dt: self.update_layout(), 0)

        self.apply_theme()

    def update_background(self, *args):
        self.bg_rect.pos = self.bubble.pos
        self.bg_rect.size = self.bubble.size

    def update_layout(self, *args):

        app = App.get_running_app()

        available_width = max(dp(180), self.width * 0.78)

        self.bubble.width = min(
            max(dp(100), self.label.texture_size[0] + dp(28)),
            available_width
        )

        self.label.text_size = (
            self.bubble.width - dp(24),
            None
        )

        self.label.texture_update()

        self.label.height = max(
            dp(24),
            self.label.texture_size[1]
        )

        self.bubble.height = (
            self.label.height + dp(16)
        )

        self.height = self.bubble.height + dp(8)

    def apply_theme(self):

        app = App.get_running_app()

        if not app:
            return

        theme = app.theme

        if self.is_user:
            self.bg_color.rgb = theme["user_bubble"][:3]
            self.label.color = theme["user_text"]
        else:
            self.bg_color.rgb = theme["ai_bubble"][:3]
            self.label.color = theme["ai_text"]

        self.label.font_size = f"{app.font_size}sp"

        Clock.schedule_once(lambda dt: self.update_layout(), 0)


# ============================================================
# CHAT SCREEN
# ============================================================

class ChatScreen(Screen):

    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        self.busy = False

        self.root_layout = BoxLayout(
            orientation="vertical",
            padding=dp(10),
            spacing=dp(8)
        )

        # ---------------- HEADER ----------------

        self.header = BoxLayout(
            size_hint_y=None,
            height=dp(50),
            spacing=dp(8)
        )

        self.title = Label(
            text="دستیار هوشمند نامیرا",
            font_size="18sp",
            bold=True,
            halign="right",
            valign="middle"
        )

        self.settings_btn = Button(
            text="⚙",
            size_hint_x=None,
            width=dp(48),
            background_normal="",
        )

        self.settings_btn.bind(
            on_press=self.go_to_settings
        )

        self.header.add_widget(self.title)
        self.header.add_widget(self.settings_btn)

        self.root_layout.add_widget(self.header)

        # ---------------- CHAT ----------------

        self.scroll = ScrollView(
            size_hint=(1, 1),
            bar_width=dp(4)
        )

        self.chat_layout = BoxLayout(
            orientation="vertical",
            spacing=dp(5),
            size_hint_y=None,
            padding=[0, dp(5)]
        )

        self.chat_layout.bind(
            minimum_height=self.chat_layout.setter("height")
        )

        self.scroll.add_widget(self.chat_layout)

        self.root_layout.add_widget(self.scroll)

        # ---------------- INPUT ----------------

        self.input_box = BoxLayout(
            size_hint_y=None,
            height=dp(52),
            spacing=dp(6)
        )

        self.text_input = TextInput(
            hint_text="پیام خود را بنویسید...",
            multiline=False,
            size_hint_x=1,
            padding=[dp(12), dp(10)],
            font_size="15sp"
        )

        self.text_input.bind(
            on_text_validate=self.send_message
        )

        self.send_btn = Button(
            text="ارسال",
            size_hint_x=None,
            width=dp(80),
            background_normal="",
        )

        self.send_btn.bind(
            on_press=self.send_message
        )

        self.input_box.add_widget(self.text_input)
        self.input_box.add_widget(self.send_btn)

        self.root_layout.add_widget(self.input_box)

        self.add_widget(self.root_layout)

        self.load_history()

        Clock.schedule_once(
            lambda dt: self.apply_theme(),
            0
        )

    def apply_theme(self):

        app = App.get_running_app()

        if not app:
            return

        theme = app.theme

        self.root_layout.canvas.before.clear()

        with self.root_layout.canvas.before:
            Color(*theme["background"])
            self.background_rect = RoundedRectangle(
                pos=self.root_layout.pos,
                size=self.root_layout.size
            )

        self.root_layout.bind(
            pos=self.update_background,
            size=self.update_background
        )

        self.title.color = theme["primary"]

        self.settings_btn.background_color = theme["primary"]

        self.text_input.background_color = theme["input"]
        self.text_input.foreground_color = theme["text"]
        self.text_input.cursor_color = theme["primary"]

        self.send_btn.background_color = theme["primary"]

        for child in self.chat_layout.children:
            if isinstance(child, ChatBubble):
                child.apply_theme()

    def update_background(self, *args):

        if hasattr(self, "background_rect"):
            self.background_rect.pos = self.root_layout.pos
            self.background_rect.size = self.root_layout.size

    def go_to_settings(self, instance):
        self.manager.current = "settings"

    def add_message(self, text, is_user=True):

        bubble = ChatBubble(
            text,
            is_user=is_user,
            font_size=App.get_running_app().font_size
        )

        self.chat_layout.add_widget(bubble)

        Clock.schedule_once(
            lambda dt: setattr(self.scroll, "scroll_y", 0),
            0.05
        )

    def send_message(self, instance=None):

        if self.busy:
            return

        text = self.text_input.text.strip()

        if not text:
            return

        self.add_message(
            text,
            is_user=True
        )

        self.text_input.text = ""

        self.busy = True
        self.send_btn.disabled = True
        self.send_btn.text = "..."

        self.add_message(
            "در حال فکر کردن...",
            is_user=False
        )

        threading.Thread(
            target=self.fetch_ai_response,
            args=(text,),
            daemon=True
        ).start()

    def fetch_ai_response(self, prompt):

        try:

            if not API_KEY:
                raise Exception(
                    "API Key تنظیم نشده است."
                )

            payload = {
                "model": MODEL_NAME,
                "messages": [
                    {
                        "role": "user",
                        "content": prompt
                    }
                ]
            }

            data = json.dumps(
                payload
            ).encode("utf-8")

            request = urllib.request.Request(
                API_URL,
                data=data,
                headers={
                    "Content-Type": "application/json",
                    "Authorization": f"Bearer {API_KEY}"
                },
                method="POST"
            )

            with urllib.request.urlopen(
                request,
                timeout=60
            ) as response:

                raw = response.read().decode(
                    "utf-8"
                )

                result = json.loads(raw)

            answer = (
                result
                .get("choices", [{}])[0]
                .get("message", {})
                .get("content")
            )

            if not answer:
                raise Exception(
                    "پاسخ معتبر از API دریافت نشد."
                )

            Clock.schedule_once(
                lambda dt: self.finish_response(
                    prompt,
                    answer,
                    None
                ),
                0
            )

        except urllib.error.HTTPError as e:

            try:
                error_body = e.read().decode(
                    "utf-8"
                )
            except:
                error_body = str(e)

            Clock.schedule_once(
                lambda dt: self.finish_response(
                    prompt,
                    None,
                    f"خطای API ({e.code}):\n{error_body}"
                ),
                0
            )

        except Exception as e:

            Clock.schedule_once(
                lambda dt: self.finish_response(
                    prompt,
                    None,
                    f"خطا: {str(e)}"
                ),
                0
            )

    def finish_response(
        self,
        prompt,
        answer,
        error
    ):

        if self.chat_layout.children:

            last = self.chat_layout.children[0]

            if (
                isinstance(last, ChatBubble)
                and last.text == "در حال فکر کردن..."
            ):
                self.chat_layout.remove_widget(
                    last
                )

        if error:
            self.add_message(
                error,
                is_user=False
            )
        else:
            self.add_message(
                answer,
                is_user=False
            )

            self.save_history(
                prompt,
                answer
            )

        self.busy = False
        self.send_btn.disabled = False
        self.send_btn.text = "ارسال"

    def save_history(self, user, ai):

        history = []

        try:

            if os.path.exists(HISTORY_FILE):

                with open(
                    HISTORY_FILE,
                    "r",
                    encoding="utf-8"
                ) as f:

                    history = json.load(f)

        except Exception:
            history = []

        history.append({
            "user": user,
            "ai": ai
        })

        history = history[-30:]

        try:

            with open(
                HISTORY_FILE,
                "w",
                encoding="utf-8"
            ) as f:

                json.dump(
                    history,
                    f,
                    ensure_ascii=False,
                    indent=2
                )

        except Exception as e:

            print(
                "History save error:",
                e
            )

    def load_history(self):

        if not os.path.exists(
            HISTORY_FILE
        ):
            return

        try:

            with open(
                HISTORY_FILE,
                "r",
                encoding="utf-8"
            ) as f:

                history = json.load(f)

            for chat in history:

                self.add_message(
                    chat.get("user", ""),
                    is_user=True
                )

                self.add_message(
                    chat.get("ai", ""),
                    is_user=False
                )

        except Exception as e:

            print(
                "History load error:",
                e
            )


# ============================================================
# SETTINGS SCREEN
# ============================================================

class SettingsScreen(Screen):

    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        self.layout = BoxLayout(
            orientation="vertical",
            padding=dp(20),
            spacing=dp(15)
        )

        self.title = Label(
            text="تنظیمات برنامه",
            font_size="22sp",
            bold=True,
            size_hint_y=None,
            height=dp(50)
        )

        self.layout.add_widget(
            self.title
        )

        self.theme_btn = Button(
            text="",
            size_hint_y=None,
            height=dp(50),
            background_normal=""
        )

        self.theme_btn.bind(
            on_press=self.toggle_theme
        )

        self.layout.add_widget(
            self.theme_btn
        )

        self.font_btn = Button(
            text="",
            size_hint_y=None,
            height=dp(50),
            background_normal=""
        )

        self.font_btn.bind(
            on_press=self.change_font
        )

        self.layout.add_widget(
            self.font_btn
        )

        self.clear_btn = Button(
            text="پاک کردن تاریخچه",
            size_hint_y=None,
            height=dp(50),
            background_normal=""
        )

        self.clear_btn.bind(
            on_press=self.clear_history
        )

        self.layout.add_widget(
            self.clear_btn
        )

        self.layout.add_widget(
            BoxLayout()
        )

        self.back_btn = Button(
            text="بازگشت به چت",
            size_hint_y=None,
            height=dp(55),
            background_normal=""
        )

        self.back_btn.bind(
            on_press=self.back_to_chat
        )

        self.layout.add_widget(
            self.back_btn
        )

        self.add_widget(
            self.layout
        )

        Clock.schedule_once(
            lambda dt: self.apply_theme(),
            0
        )

    def apply_theme(self):

        app = App.get_running_app()

        if not app:
            return

        theme = app.theme

        self.layout.canvas.before.clear()

        with self.layout.canvas.before:

            Color(*theme["background"])

            self.bg_rect = RoundedRectangle(
                pos=self.layout.pos,
                size=self.layout.size
            )

        self.layout.bind(
            pos=self.update_bg,
            size=self.update_bg
        )

        self.title.color = theme["primary"]

        self.theme_btn.background_color = (
            theme["primary"]
        )

        self.font_btn.background_color = (
            theme["primary"]
        )

        self.clear_btn.background_color = (
            (0.75, 0.18, 0.18, 1)
        )

        self.back_btn.background_color = (
            theme["primary"]
        )

        self.update_texts()

    def update_bg(self, *args):

        if hasattr(self, "bg_rect"):
            self.bg_rect.pos = self.layout.pos
            self.bg_rect.size = self.layout.size

    def update_texts(self):

        app = App.get_running_app()

        if app.theme_name == "dark":
            theme_text = "☀️ حالت روشن"
        else:
            theme_text = "🌙 حالت تاریک"

        self.theme_btn.text = theme_text

        self.font_btn.text = (
            f"اندازه فونت: {app.font_size}sp"
        )

    def toggle_theme(self, instance):

        app = App.get_running_app()

        if app.theme_name == "light":
            app.set_theme("dark")
        else:
            app.set_theme("light")

        self.update_texts()

    def change_font(self, instance):

        app = App.get_running_app()

        if app.font_size == 14:
            app.font_size = 16

        elif app.font_size == 16:
            app.font_size = 18

        else:
            app.font_size = 14

        app.refresh_ui()

        self.update_texts()

    def clear_history(self, instance):

        try:

            if os.path.exists(
                HISTORY_FILE
            ):
                os.remove(
                    HISTORY_FILE
                )

            chat = self.manager.get_screen(
                "chat"
            )

            chat.chat_layout.clear_widgets()

        except Exception as e:

            print(
                "Clear history error:",
                e
            )

    def back_to_chat(self, instance):

        self.manager.current = "chat"


# ============================================================
# MAIN APP
# ============================================================

class NamiraApp(App):

    theme_name = "light"

    font_size = NumericProperty(14)

    theme = THEMES["light"]

    def build(self):

        self.title = "Namira AI"

        self.sm = ScreenManager()

        self.chat_screen = ChatScreen(
            name="chat"
        )

        self.settings_screen = SettingsScreen(
            name="settings"
        )

        self.sm.add_widget(
            self.chat_screen
        )

        self.sm.add_widget(
            self.settings_screen
        )

        return self.sm

    def set_theme(self, name):

        if name not in THEMES:
            return

        self.theme_name = name

        self.theme = THEMES[name]

        self.refresh_ui()

    def refresh_ui(self):

        if hasattr(
            self,
            "chat_screen"
        ):
            self.chat_screen.apply_theme()

        if hasattr(
            self,
            "settings_screen"
        ):
            self.settings_screen.apply_theme()


# ============================================================
# RUN
# ============================================================

if __name__ == "__main__":
    NamiraApp().run()