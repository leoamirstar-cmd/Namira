import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
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
  
  List<Map<String, String>> _messages = [];
  List<String> _chatHistoryKeys = [];
  String _currentChatKey = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadChatHistoryKeys();
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

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add({'sender': 'user', 'text': text});
      _isLoading = true;
    });
    _messageController.clear();
    _saveCurrentMessages();

    final response = await _geminiManager.sendMessage(text);

    setState(() {
      _messages.add({'sender': 'namira', 'text': response});
      _isLoading = false;
    });
    _saveCurrentMessages();
  }

  @override
  Widget build(BuildContext context) {
    final bool currentTheme = widget.isDarkMode ?? false;
    final String currentLang = widget.currentLanguage ?? 'fa';

    return Scaffold(
      appBar: AppBar(
        title: const Text('دستیار نامیرا'),
        actions: [
          if (widget.onChangeLanguage != null)
            IconButton(
              icon: const Icon(Icons.language),
              onPressed: () => widget.onChangeLanguage!(currentLang == 'fa' ? 'en' : 'fa'),
            ),
          if (widget.onToggleTheme != null)
            IconButton(
              icon: Icon(currentTheme ? Icons.light_mode : Icons.dark_mode),
              onPressed: () => widget.onToggleTheme!(!currentTheme),
            ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blueGrey),
              child: Center(
                child: Text(
                  'تاریخچه گفتگوها',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('گفتگوی جدید'),
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
                  return ListTile(
                    selected: key == _currentChatKey,
                    leading: const Icon(Icons.chat_bubble_outline),
                    title: Text('گفتگو ${index + 1}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
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
              padding: const EdgeInsets.all(8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['sender'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      msg['text'] ?? '',
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(
                      hintText: 'پیام خود را بنویسید...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
