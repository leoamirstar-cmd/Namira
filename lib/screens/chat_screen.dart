import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../services/gemini_manager.dart';

class ChatScreen extends StatefulWidget {
  final Function(bool)? onToggleTheme;
  final Function(String)? onChangeLanguage;
  final String? currentLanguage;
  final bool? isDarkMode;

  const ChatScreen({
    super.key, 
    this.onToggleTheme,
    this.onChangeLanguage,
    this.currentLanguage,
    this.isDarkMode,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final GeminiManager _geminiManager = GeminiManager();
  final AudioRecorder _audioRecorder = AudioRecorder();

  List<Map<String, String>> _messages = [];
  List<String> _chatHistoryKeys = [];
  String _currentChatKey = '';
  bool _isLoading = false;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _loadChatHistoryKeys();
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadChatHistoryKeys() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getStringList('chat_keys') ?? [];
    setState(() {
      _chatHistoryKeys = keys;
      if (_chatHistoryKeys.isNotEmpty) {
        _currentChatKey = _chatHistoryKeys.last;
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
      if (!_chatHistoryKeys.contains(newKey)) {
        _chatHistoryKeys.add(newKey);
      }
    });
    _saveHistoryKeys();
  }

  Future<void> _saveHistoryKeys() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('chat_keys', _chatHistoryKeys);
  }

  Future<void> _loadMessages(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final rawData = prefs.getString(key);
    if (rawData != null) {
      final List decoded = jsonDecode(rawData);
      setState(() {
        _currentChatKey = key;
        _messages = decoded.map((e) => Map<String, String>.from(e)).toList();
      });
    }
  }

  Future<void> _saveCurrentMessages() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentChatKey, jsonEncode(_messages));
  }

  Future<void> _deleteChat(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
    setState(() {
      _chatHistoryKeys.remove(key);
    });
    await _saveHistoryKeys();
    if (_currentChatKey == key) {
      if (_chatHistoryKeys.isNotEmpty) {
        _loadMessages(_chatHistoryKeys.last);
      } else {
        _startNewChat();
      }
    }
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

        _sendMediaMessage(
          type: isImage ? 'image' : 'file',
          path: platformFile.path!,
          text: platformFile.name,
        );
      }
    } else {
      _showPermissionDialog('دسترسی به فایل‌ها جهت ارسال الزامی است.');
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
      });
      if (path != null) {
        _sendMediaMessage(type: 'audio', path: path, text: '[ویس صوتی]');
      }
    } else {
      PermissionStatus status = await Permission.microphone.request();
      if (status.isGranted) {
        if (await _audioRecorder.hasPermission()) {
          final dir = await getApplicationDocumentsDirectory();
          final filePath = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
          
          await _audioRecorder.start(
            const RecordConfig(),
            path: filePath,
          );
          setState(() {
            _isRecording = true;
          });
        }
      } else {
        _showPermissionDialog('دسترسی به میکروفون جهت ضبط ویس الزامی است.');
      }
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

    try {
      final response = await _geminiManager.sendMessage('فایل ارسال شد: $text');
      if (mounted) {
        setState(() {
          _messages.add({'sender': 'namira', 'text': response, 'type': 'text'});
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
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add({'sender': 'user', 'text': text, 'type': 'text'});
      _isLoading = true;
    });
    _messageController.clear();
    _saveCurrentMessages();

    try {
      final response = await _geminiManager.sendMessage(text);
      if (mounted) {
        setState(() {
          _messages.add({'sender': 'namira', 'text': response, 'type': 'text'});
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
        title: const Text('نیاز به مجوز'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
          TextButton(
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
    final String currentLang = widget.currentLanguage ?? 'fa';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF101820) : const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1A232E) : Colors.white,
        elevation: 1,
        titleSpacing: 0,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: Colors.blueAccent,
              child: Icon(Icons.smart_toy, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAlignment.start,
              children: [
                Text(
                  'دستیار نامیرا',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const Text(
                  'online',
                  style: TextStyle(fontSize: 11, color: Colors.greenAccent),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (widget.onChangeLanguage != null)
            IconButton(
              icon: Icon(Icons.language, color: isDark ? Colors.white70 : Colors.black54),
              onPressed: () => widget.onChangeLanguage!(currentLang == 'fa' ? 'en' : 'fa'),
            ),
          if (widget.onToggleTheme != null)
            IconButton(
              icon: Icon(
                isDark ? Icons.light_mode : Icons.dark_mode,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              onPressed: () => widget.onToggleTheme!(!isDark),
            ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: isDark ? const Color(0xFF1A232E) : Colors.white,
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF253342) : Colors.blueAccent,
              ),
              child: const Center(
                child: Text(
                  'تاریخچه گفتگوها',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add_circle_outline, color: Colors.blueAccent),
              title: Text('گفتگوی جدید', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
              onTap: () {
                _startNewChat();
                Navigator.pop(context);
              },
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: _chatHistoryKeys.length,
                itemBuilder: (context, index) {
                  final key = _chatHistoryKeys[index];
                  final isSelected = key == _currentChatKey;
                  return ListTile(
                    selected: isSelected,
                    selectedTileColor: isDark ? Colors.white10 : Colors.black12,
                    leading: const Icon(Icons.chat_bubble_outline, size: 20),
                    title: Text('گفتگو ${index + 1}', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                      onPressed: () => _deleteChat(key),
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
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                    decoration: BoxDecoration(
                      color: isUser 
                          ? const Color(0xFF2B5278) 
                          : (isDark ? const Color(0xFF182533) : Colors.white),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 2),
                        bottomRight: Radius.circular(isUser ? 2 : 16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (msgType == 'image' && msgPath != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(msgPath),
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          )
                        else if (msgType == 'file')
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.insert_drive_file, color: Colors.white),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  msgText,
                                  style: const TextStyle(color: Colors.white),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          )
                        else if (msgType == 'audio')
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.play_arrow, color: Colors.white),
                              SizedBox(width: 8),
                              Text('پیام صوتی (ویس)', style: TextStyle(color: Colors.white)),
                            ],
                          )
                        else
                          Text(
                            msgText,
                            style: TextStyle(
                              color: isUser ? Colors.white : (isDark ? Colors.white : Colors.black87),
                              fontSize: 14.5,
                              height: 1.4,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (isUser && msgType == 'text')
                              InkWell(
                                onTap: () => _editUserMessage(msgText),
                                child: const Icon(Icons.edit, size: 15, color: Colors.white70),
                              )
                            else if (!isUser)
                              InkWell(
                                onTap: () => _copyToClipboard(msgText),
                                child: Icon(
                                  Icons.copy, 
                                  size: 15, 
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
              padding: EdgeInsets.symmetric(vertical: 4),
              child: LinearProgressIndicator(backgroundColor: Colors.transparent),
            ),
          Container(
            padding: const EdgeInsets.all(10),
            color: isDark ? const Color(0xFF1A232E) : Colors.white,
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.attach_file, color: isDark ? Colors.white70 : Colors.black54),
                  onPressed: _pickFile,
                ),
                IconButton(
                  icon: Icon(
                    _isRecording ? Icons.stop_circle : Icons.mic,
                    color: _isRecording ? Colors.redAccent : (isDark ? Colors.white70 : Colors.black54),
                  ),
                  onPressed: _toggleRecording,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    keyboardType: TextInputType.multiline,
                    maxLines: 4,
                    minLines: 1,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      hintText: _isRecording ? 'در حال ضبط ویس...' : 'پیام خود را بنویسید...',
                      hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF101820) : const Color(0xFFF0F2F5),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.blueAccent,
                  child: IconButton(
                    icon: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
