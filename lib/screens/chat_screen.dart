import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/gemini_manager.dart';

class ChatScreen extends StatefulWidget {
  final bool? isDarkMode;

  const ChatScreen({
    super.key, 
    this.isDarkMode,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final GeminiManager _geminiManager = GeminiManager();

  List<Map<String, dynamic>> _messages = [];
  List<Map<String, String>> _chatHistoryKeys = [];
  String _currentChatKey = '';
  bool _isLoading = false;
  CancelToken? _cancelToken;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _loadChatHistoryKeys();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadChatHistoryKeys() async {
    final prefs = await SharedPreferences.getInstance();
    final rawKeys = prefs.getStringList('chat_keys') ?? [];
    setState(() {
      _chatHistoryKeys = rawKeys.map((k) => {'id': k, 'title': prefs.getString('title_$k') ?? 'گفتگو'}).toList();
      if (_chatHistoryKeys.isNotEmpty) {
        _currentChatKey = _chatHistoryKeys.last['id']!;
        _loadMessages(_currentChatKey);
      } else {
        _startNewChat();
      }
    });
  }

  void _startNewChat() {
    final newKey = 'chat_${DateTime.now().millisecondsSinceEpoch}';
    setState(() {
      _currentChatKey = newKey;
      _messages = [];
      _chatHistoryKeys.add({'id': newKey, 'title': 'گفتگوی جدید'});
    });
    _saveHistoryKeys();
  }

  Future<void> _saveHistoryKeys() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('chat_keys', _chatHistoryKeys.map((e) => e['id']!).toList());
    for (var chat in _chatHistoryKeys) {
      await prefs.setString('title_${chat['id']}', chat['title']!);
    }
  }

  Future<void> _loadMessages(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final rawData = prefs.getString(key);
    if (rawData != null) {
      final List decoded = jsonDecode(rawData);
      setState(() {
        _currentChatKey = key;
        _messages = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      });
    } else {
      setState(() {
        _currentChatKey = key;
        _messages = [];
      });
    }
  }

  Future<void> _saveCurrentMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final serializableMessages = _messages.map((m) {
      return {
        'sender': m['sender'],
        'text': m['text'],
        'type': m['type'],
        'path': m['path'],
      };
    }).toList();
    await prefs.setString(_currentChatKey, jsonEncode(serializableMessages));
  }

  Future<void> _deleteChat(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
    await prefs.remove('title_$key');
    setState(() {
      _chatHistoryKeys.removeWhere((element) => element['id'] == key);
    });
    await _saveHistoryKeys();
    if (_currentChatKey == key) {
      if (_chatHistoryKeys.isNotEmpty) {
        _loadMessages(_chatHistoryKeys.last['id']!);
      } else {
        _startNewChat();
      }
    }
  }

  void _showEditTitleDialog(int index) {
    TextEditingController editController = TextEditingController(text: _chatHistoryKeys[index]['title']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('ویرایش نام گفتگو', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: editController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'نام جدید را وارد کنید',
            hintStyle: TextStyle(color: Colors.white54),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
            onPressed: () {
              if (editController.text.trim().isNotEmpty) {
                setState(() {
                  _chatHistoryKeys[index]['title'] = editController.text.trim();
                });
                _saveHistoryKeys();
                Navigator.pop(context);
              }
            },
            child: const Text('ذخیره'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFile() async {
    PermissionStatus status = await Permission.storage.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      status = await Permission.photos.request();
    }

    if (status.isGranted || status.isLimited) {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.any,
      );

      if (result != null && result.files.single.path != null) {
        final platformFile = result.files.single;
        final extension = platformFile.extension?.toLowerCase() ?? '';
        final isImage = ['jpg', 'jpeg', 'png', 'webp'].contains(extension);

        if (isImage) {
          setState(() {
            _selectedImage = File(platformFile.path!);
          });
        } else {
          _sendMediaMessage(
            type: 'file',
            path: platformFile.path!,
            text: platformFile.name,
          );
        }
      }
    } else {
      _showPermissionDialog('دسترسی به فایل‌ها جهت ارسال الزامی است.');
    }
  }

  void _sendMediaMessage({required String type, required String path, required String text}) async {
    setState(() {
      _messages.add({
        'sender': 'user',
        'text': text,
        'type': type,
        'path': path,
      });
      _isLoading = true;
    });
    _saveCurrentMessages();

    _cancelToken = CancelToken();
    try {
      final response = await _geminiManager.sendMessage('فایل ارسال شد: $text');
      if (mounted) {
        setState(() {
          _messages.add({'sender': 'namira', 'text': response, 'type': 'text', 'path': null});
          _isLoading = false;
        });
        _saveCurrentMessages();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if ((text.isEmpty && _selectedImage == null) || _isLoading) return;

    _cancelToken = CancelToken();

    final imagePath = _selectedImage?.path;
    setState(() {
      _messages.add({
        'sender': 'user',
        'text': text,
        'type': imagePath != null ? 'image' : 'text',
        'path': imagePath,
      });
      _isLoading = true;
      _selectedImage = null;
    });
    _messageController.clear();
    _saveCurrentMessages();

    try {
      final response = await _geminiManager.sendMessage(text.isEmpty ? 'تصویر ارسال شد' : text);
      if (mounted) {
        setState(() {
          _messages.add({'sender': 'namira', 'text': response, 'type': 'text', 'path': null});
          _isLoading = false;
        });
        _saveCurrentMessages();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showPermissionDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('نیاز به مجوز', style: TextStyle(color: Colors.white)),
        content: Text(message, style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('تنظیمات'),
          ),
        ],
      ),
    );
  }

  void _cancelSending() {
    if (_cancelToken != null && !_cancelToken!.isCancelled) {
      _cancelToken!.cancel("ارسال لغو شد.");
    }
    setState(() {
      _isLoading = false;
    });
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('کپی شد'), duration: Duration(seconds: 2)),
    );
  }

  void _editUserMessage(String text) {
    _messageController.text = text;
    _messageController.selection = TextSelection.fromPosition(
      TextPosition(offset: _messageController.text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = widget.isDarkMode ?? true;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Colors.pinkAccent, Colors.blueAccent],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.pinkAccent.withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Padding(
                padding: EdgeInsets.all(2.0),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Color(0xFF1E293B),
                  child: Icon(Icons.smart_toy, color: Colors.pinkAccent, size: 18),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'دستیار نامیرا',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'آماده به خدمت',
                      style: TextStyle(fontSize: 11, color: Colors.greenAccent),
                    ),
                    ],
                ),
              ],
            ),
          ],
        ),
      ),
      drawer: Drawer(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blueAccent.withOpacity(0.8), Colors.pinkAccent.withOpacity(0.8)],
                ),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history_rounded, size: 40, color: Colors.white),
                    SizedBox(height: 8),
                    Text(
                      'تاریخچه گفتگوها',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add_circle_outline, color: Colors.pinkAccent),
              title: Text('گفتگوی جدید', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600)),
              onTap: () {
                _startNewChat();
                Navigator.pop(context);
              },
            ),
            Divider(color: isDark ? Colors.white24 : Colors.black12),
            Expanded(
              child: ListView.builder(
                itemCount: _chatHistoryKeys.length,
                itemBuilder: (context, index) {
                  final chat = _chatHistoryKeys[index];
                  final key = chat['id']!;
                  final title = chat['title']!;
                  final isSelected = key == _currentChatKey;
                  return ListTile(
                    selected: isSelected,
                    selectedTileColor: isDark ? Colors.pinkAccent.withOpacity(0.15) : Colors.blue.withOpacity(0.1),
                    leading: Icon(Icons.chat_bubble_outline, size: 20, color: isSelected ? Colors.pinkAccent : Colors.blueAccent),
                    title: Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent, size: 18),
                          onPressed: () => _showEditTitleDialog(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                          onPressed: () => _deleteChat(key),
                        ),
                      ],
                    ),
                    onTap: () {
                      _loadMessages(key);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark 
                ? [const Color(0xFF0F172A), const Color(0xFF1E1B4B)]
                : [const Color(0xFFF8FAFC), const Color(0xFFEEF2F6)],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg['sender'] == 'user';
                  final msgText = msg['text'] ?? '';
                  final msgType = msg['type'] ?? 'text';
                  final msgPath = msg['path'];

                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                      decoration: BoxDecoration(
                        gradient: isUser 
                            ? const LinearGradient(colors: [Colors.blueAccent, Colors.indigoAccent])
                            : null,
                        color: isUser 
                            ? null 
                            : (isDark ? const Color(0xFF1E293B) : Colors.white),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(20),
                          topRight: const Radius.circular(20),
                          bottomLeft: Radius.circular(isUser ? 20 : 4),
                          bottomRight: Radius.circular(isUser ? 4 : 20),
                        ),
                        border: !isUser && isDark ? Border.all(color: Colors.white10) : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (msgType == 'image' && msgPath != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(msgPath),
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          if (msgText.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(top: (msgType == 'image' && msgPath != null) ? 8.0 : 0),
                              child: Text(
                                msgText,
                                style: TextStyle(
                                  color: isUser ? Colors.white : (isDark ? Colors.white : Colors.black87),
                                  fontSize: 15,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (isUser)
                                InkWell(
                                  onTap: () => _editUserMessage(msgText),
                                  child: const Icon(Icons.edit, size: 14, color: Colors.white70),
                                )
                              else
                                InkWell(
                                  onTap: () => _copyToClipboard(msgText),
                                  child: Icon(
                                    Icons.copy, 
                                    size: 14, 
                                    color: isDark ? Colors.white54 : Colors.black54,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.pinkAccent),
                ),
              ),
            if (_selectedImage != null)
              Container(
                padding: const EdgeInsets.all(10.0),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                child: Row(
                  children: [
                    Stack(
                      alignment: Alignment.topRight,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(_selectedImage!, width: 60, height: 60, fit: BoxFit.cover),
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
                    const SizedBox(width: 12),
                    const Text('تصویر آماده ارسال...', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file_rounded, color: Colors.pinkAccent),
                    onPressed: _pickFile,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      keyboardType: TextInputType.multiline,
                      maxLines: 4,
                      minLines: 1,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        hintText: 'پیام خود را بنویسید...',
                        hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: _isLoading 
                            ? [Colors.redAccent, Colors.red] 
                            : [Colors.pinkAccent, Colors.blueAccent],
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.transparent,
                      child: IconButton(
                        icon: Icon(
                          _isLoading ? Icons.stop : Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: _isLoading ? _cancelSending : _sendMessage,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
