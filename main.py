from kivy.app import App
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.label import Label
from kivy.uix.textinput import TextInput
from kivy.uix.button import Button
from kivy.core.window import Window

class NamiraApp(App):
    def build(self):
        Window.clearcolor = (0.1, 0.1, 0.1, 1)
        layout = BoxLayout(orientation='vertical', padding=15, spacing=10)
        
        self.chat_logs = Label(
            text="سلام امیرجان! من نامیرا هستم.\nبرنامه با موفقیت روی اندروید اجرا شد!\n\n",
            size_hint_y=0.85,
            color=(1, 1, 1, 1),
            halign="right",
            valign="top"
        )
        self.chat_logs.bind(size=self.chat_logs.setter('text_size'))
        layout.add_widget(self.chat_logs)
        
        input_layout = BoxLayout(orientation='horizontal', size_hint_y=0.15, spacing=10)
        self.user_input = TextInput(hint_text="پیام...", multiline=False, size_hint_x=0.75)
        send_btn = Button(text="ارسال", size_hint_x=0.25, background_color=(0.4, 0.2, 0.8, 1))
        send_btn.bind(on_release=self.send_message)
        
        input_layout.add_widget(self.user_input)
        input_layout.add_widget(send_btn)
        layout.add_widget(input_layout)
        
        return layout

    def send_message(self, instance):
        msg = self.user_input.text.strip()
        if msg:
            self.chat_logs.text += f"شما: {msg}\n"
            self.user_input.text = ""
            self.chat_logs.text += "نامیرا: پیام دریافت شد!\n\n"

if __name__ == '__main__':
    NamiraApp().run()
  
