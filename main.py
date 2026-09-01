import arabic_reshaper
from bidi.algorithm import get_display

from kivy.app import App
from kivy.graphics import Color, RoundedRectangle
from kivy.metrics import dp
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.button import Button
from kivy.uix.label import Label
from kivy.uix.scrollview import ScrollView
from kivy.uix.textinput import TextInput


# اصلاح متن فارسی
def fix_text(text):
  if not text:
    return ''
  reshaped = arabic_reshaper.reshape(text)
  return get_display(reshaped)


class MessageBubble(BoxLayout):

  def __init__(self, text, is_user=True, **kwargs):
    super().__init__(**kwargs)
    self.size_hint_y = None
    self.padding = [dp(10), dp(5)]

    # حباب پیام
    lbl = Label(
        text=fix_text(text),
        font_name='vazir.ttf',
        font_size='16sp',
        size_hint_x=None,
        color=(1, 1, 1, 1) if is_user else (0, 0, 0, 1),
    )
    lbl.bind(texture_size=lbl.setter('size'))

    # پس‌زمینه رنگی حباب
    with lbl.canvas.before:
      Color(
          *(
              (0.2, 0.5, 0.9, 1) if is_user else (0.9, 0.9, 0.9, 1)
          )  # آبی برای کاربر، خاکستری برای نمیرای
      )
      self.rect = RoundedRectangle(
          pos=lbl.pos, size=lbl.size, radius=[dp(12)]
      )

    def update_rect(instance, value):
      self.rect.pos = instance.pos
      self.rect.size = instance.size

    lbl.bind(pos=update_rect, size=update_rect)

    if is_user:
      self.add_widget(BoxLayout(size_hint_x=0.3))  # هل دادن به راست
      self.add_widget(lbl)
    else:
      self.add_widget(lbl)
      self.add_widget(BoxLayout(size_hint_x=0.3))  # هل دادن به چپ

    self.height = lbl.texture_size[1] + dp(20)


class ChatScreen(BoxLayout):

  def __init__(self, **kwargs):
    super().__init__(**kwargs)
    self.orientation = 'vertical'

    # هدر بالای صفحه
    header = Label(
        text=fix_text('دستیار هوشمند نمیرای'),
        font_name='vazir.ttf',
        font_size='20sp',
        size_hint_y=0.1,
        color=(0.2, 0.6, 1, 1),
    )
    self.add_widget(header)

    # لیست پیام‌ها (اسکرول‌دار)
    self.scroll = ScrollView(size_hint_y=0.8)
    self.chat_logs = BoxLayout(
        orientation='vertical',
        spacing=dp(10),
        size_hint_y=None,
        padding=dp(10),
    )
    self.chat_logs.bind(minimum_height=self.chat_logs.setter('height'))
    self.scroll.add_widget(self.chat_logs)
    self.add_widget(self.scroll)

    # پیام خوش‌آمدگویی
    self.add_message('سلام! من نمیرای هستم. چطور می‌تونم کمکت کنم؟', is_user=False)

    # بخش کادر ورود متن و دکمه ارسال
    input_box = BoxLayout(
        orientation='horizontal', size_hint_y=0.1, padding=dp(5), spacing=dp(5)
    )

    self.entry = TextInput(
        hint_text=fix_text('پیام خود را بنویسید...'),
        font_name='vazir.ttf',
        multiline=False,
        size_hint_x=0.8,
    )

    send_btn = Button(
        text=fix_text('ارسال'),
        font_name='vazir.ttf',
        size_hint_x=0.2,
        background_color=(0.2, 0.6, 1, 1),
    )
    send_btn.bind(on_press=self.send_message)

    input_box.add_widget(self.entry)
    input_box.add_widget(send_btn)
    self.add_widget(input_box)

  def add_message(self, text, is_user=True):
    bubble = MessageBubble(text, is_user=is_user)
    self.chat_logs.add_widget(bubble)
    self.scroll.scroll_y = 0

  def send_message(self, instance):
    text = self.entry.text.strip()
    if text:
      self.add_message(text, is_user=True)
      self.entry.text = ''

      # پاسخی هوشمندانه نمونه
      reply = self.generate_reply(text)
      self.add_message(reply, is_user=False)

  def generate_reply(self, text):
    text_lower = text.lower()
    if 'سلام' in text or 'hi' in text_lower or 'hello' in text_lower:
      return 'سلام رفیق! خوشحالم می‌بینمت.'
    elif 'اسمت چیه' in text or 'who are you' in text_lower:
      return 'من نمیرای هستم، دستیار اختصاصی تو!'
    elif 'چطوری' in text or 'how are you' in text_lower:
      return 'من عالی‌ام! تو در چه حالی؟'
    else:
      return f'پیام شما دریافت شد: "{text}"'


class NamiraApp(App):

  def build(self):
    return ChatScreen()


if __name__ == '__main__':
  NamiraApp().run()
      
