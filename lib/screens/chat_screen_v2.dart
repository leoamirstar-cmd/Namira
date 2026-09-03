import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ChatScreenV2 extends StatefulWidget {
  const ChatScreenV2({Key? key}) : super(key: key);

  @override
  State<ChatScreenV2> createState() => _ChatScreenV2State();
}

class _ChatScreenV2State extends State<ChatScreenV2> {
  final TextEditingController _textController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final ImagePicker _picker = ImagePicker();
  
  File? _selectedImage;
  bool _isDarkMode = true;
  String _currentLang = 'fa';

  // لیست نمونه برای تاریخچه گفتگوها
  List<Map<String, String>> _chatHistory = [
    {'id': '1', 'title': 'گفتگو ۱'},
    {'id': '2', 'title': 'تحلیل اسکرین‌شات'},
  ];

  // انتخاب تصویر از گالری (بدون ارسال خودکار)
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  // ارسال پیام (متن + تصویر در صورت وجود)
  void _sendMessage() {
    if (_textController.text.trim().isEmpty && _selectedImage == null) return;

    setState(() {
      _messages.add({
        'isUser': true,
        'text': _textController.text.trim(),
        'image': _selectedImage,
      });

      _textController.clear();
      _selectedImage = null; // پاک کردن تصویر انتخابی بعد از ارسال
    });

    // TODO: فراخوانی متد Grok/Gemini API برای دریافت پاسخ
  }

  // دیالوگ ویرایش نام گفتگو
  void _showEditTitleDialog(int index) {
    TextEditingController editController =
        TextEditingController(text: _chatHistory[index]['title']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ویرایش نام گفتگو'),
        content: TextField(
          controller: editController,
          decoration: const InputDecoration(hintText: 'نام جدید را وارد کنید'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: () {
              if (editController.text.trim().isNotEmpty) {
                setState(() {
                  _chatHistory[index]['title'] = editController.text.trim();
                });
                Navigator.pop(context);
              }
            },
            child: const Text('ذخیره'),
          ),
        ],
      ),
    );
  }

  // دیالوگ تنظیمات تم و زبان
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('تنظیمات برنامه'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('حالت تاریک (Dark Mode)'),
                value: _isDarkMode,
                onChanged: (val) {
                  setDialogState(() => _isDarkMode = val);
                  setState(() => _isDarkMode = val);
                },
              ),
              const Divider(),
              ListTile(
                title: const Text('زبان برنامه'),
                trailing: DropdownButton<String>(
                  value: _currentLang,
                  items: const [
                    DropdownMenuItem(value: 'fa', child: Text('فارسی')),
                    DropdownMenuItem(value: 'en', child: Text('English')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => _currentLang = val);
                      setState(() => _currentLang = val);
                    }
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('تایید'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('دستیار نامیرا V2'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _showSettingsDialog,
            ),
          ],
        ),
        drawer: _buildDrawer(),
        body: Column(
          children: [
            Expanded(child: _buildMessageList()),
            if (_selectedImage != null) _buildImagePreview(),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  // کشوی تاریخچه با قابلیت ویرایش و حذف
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text('تاریخچه گفتگوها', style: TextStyle(color: Colors.white, fontSize: 20)),
          ),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('گفتگوی جدید'),
            onTap: () {
              // ساخت چت جدید
            },
          ),
          const Divider(),
          ...List.generate(_chatHistory.length, (index) {
            return ListTile(
              leading: const Icon(Icons.chat_bubble_outline),
              title: Text(_chatHistory[index]['title']!),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                    onPressed: () => _showEditTitleDialog(index),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _chatHistory.removeAt(index);
                      });
                    },
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // لیست پیام‌ها
  Widget _buildMessageList() {
    return ListView.builder(
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        return Align(
          alignment: msg['isUser'] ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: msg['isUser'] ? Colors.blue[700] : Colors.grey[800],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (msg['image'] != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(msg['image'], height: 150, fit: BoxFit.cover),
                  ),
                if (msg['text'].isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(msg['text'], style: const TextStyle(color: Colors.white)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // پیش‌نمایش تصویر قبل از ارسال
  Widget _buildImagePreview() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.black25,
      child: Row(
        children: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(_selectedImage!, width: 70, height: 70, fit: BoxFit.cover),
              ),
              GestureDetector(
                onTap: () => setState(() => _selectedImage = null),
                child: const CircleAvatar(
                  radius: 10,
                  backgroundColor: Colors.red,
                  child: Icon(Icons.close, size: 12, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          const Text('تصویر انتخاب شد. کپشن را بنویسید...'),
        ],
      ),
    );
  }

  // کادر تایپ و دکمه‌ها
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: _pickImage,
          ),
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: const InputDecoration(
                hintText: 'پیام خود را بنویسید...',
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.blue),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}
