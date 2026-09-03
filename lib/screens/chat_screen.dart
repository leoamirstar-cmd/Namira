import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_models.dart';
import '../services/gemini_manager.dart';

class ChatScreen extends StatefulWidget {
  final Function(bool) onToggleTheme;
  final Function(String) onChangeLanguage;
  final String currentLanguage;
  final bool isDarkMode;

  const ChatScreen({
    super.key,
    required this.onToggleTheme,
    required this.onChangeLanguage,
    required this.currentLanguage,
    required this.isDarkMode,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<ChatSessionModel> _sessions = [];
  late ChatSessionModel _currentSession;
  bool _isLoading = false;
  bool _isInitLoaded = false;

  final GeminiManager _geminiManager = GeminiManager();
  CancelToken? _cancelToken;

  static const String _namiraAvatarAsset = "assets/images/namira_avatar.png"; 
  static const String _storageKey = 'namira_chat_sessions_permanent_v1';

  @override
  void initState() {
    super.initState();
    _initSessions();
  }

  Future<void> _initSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedData = prefs.getString(_storageKey);
    if (savedData != null) {
      try {
        List decoded = jsonDecode(savedData);
        setState(() {
          _sessions = decoded.map((e) => ChatSessionModel.fromJson(e)).toList();
        });
      } catch (_) {}
    }

    if (_sessions.isEmpty) {
      _startNewChat(initOnly: true);
    } else {
      _currentSession = _sessions.first;
    }
    setState(() {
      _isInitLoaded = true;
    });
  }

  Future<void> _saveSessions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(_sessions.map((e) => e.toJson()).toList()));
  }

  void _startNewChat({bool initOnly = false}) {
    final newSession = ChatSessionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: widget.currentLanguage == 'fa' ? 'گفتگوی جدید' : 'New Chat',
      messages: [],
    );
    setState(() {
      _sessions.insert(0, newSession);
      _currentSession = newSession;
    });
    _saveSessions();
    if (!initOnly && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  void _selectSession(ChatSessionModel session) {
    setState(() {
      _currentSession = session;
    });
    Navigator.pop(context);
  }

  void _deleteSession(String id) {
    setState(() {
      _sessions.removeWhere((s) => s.id == id);
      if (_sessions.isEmpty) {
        _startNewChat(initOnly: true);
      } else if (_currentSession.id == id) {
        _currentSession = _sessions.first;
      }
    });
    _saveSessions();
  }

  void _clearAllHistory() {
    setState(() {
      _sessions.clear();
      _startNewChat(initOnly: true);
    });
  }

  Future<void> _sendMessage() async {
    String text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    if (_currentSession.messages.isEmpty) {
      _currentSession.title = text.length > 25 ? "${text.substring(0, 25)}..." : text;
    }

    _controller.clear();
    setState(() {
      _currentSession.messages.add({"role": "user", "content": text});
      _isLoading = true;
      _cancelToken = CancelToken();
    });
    _scrollToBottom();

    try {
      String aiResponse = await _geminiManager.sendPromptRacing(
        prompt: text,
        cancelToken: _cancelToken!,
      );

      setState(() {
        _currentSession.messages.add({"role": "ai", "content": aiResponse});
      });
    } catch (e) {
      if (_cancelToken?.isCancelled == true) {
        print("لغو توسط کاربر");
      } else {
        setState(() {
          _currentSession.messages.add({"role": "ai", "content": "خطای ارتباط: لطفاً اینترنت یا فیلترشکن را بررسی کنید."});
        });
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
      _saveSessions();
      _scrollToBottom();
    }
  }

  void _cancelRequest() {
    _cancelToken?.cancel("User cancelled");
    setState(() {
      _isLoading = false;
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: widget.isDarkMode ? const Color(0xFF17212B) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.currentLanguage == 'fa' ? 'تنظیمات نامیرا' : 'Namira Settings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white : Colors.black87),
                  ),
                  const SizedBox(height: 20),
                  SwitchListTile(
                    title: Text(widget.currentLanguage == 'fa' ? 'حالت شب (تاریک)' : 'Dark Mode'),
                    value: widget.isDarkMode,
                    onChanged: (val) {
                      widget.onToggleTheme(val);
                      setModalState(() {});
                    },
                  ),
                  ListTile(
                    title: Text(widget.currentLanguage == 'fa' ? 'تغییر زبان' : 'Language'),
                    trailing: DropdownButton<String>(
                      value: widget.currentLanguage,
                      dropdownColor: widget.isDarkMode ? const Color(0xFF242F3D) : Colors.white,
                      items: const [
                        DropdownMenuItem(value: 'fa', child: Text('فارسی')),
                        DropdownMenuItem(value: 'en', child: Text('English')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          widget.onChangeLanguage(val);
                          setModalState(() {});
                        }
                      },
                    ),
                  ),
                  const Divider(height: 30),
                  ListTile(
                    leading: const Icon(Icons.delete_sweep, color: Colors.redAccent),
                    title: Text(
                      widget.currentLanguage == 'fa' ? 'پاک کردن کل تاریخچه' : 'Clear All History',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                    onTap: () {
                      _clearAllHistory();
                      Navigator.pop(context);
                    },
                  ),
                ],
),
            );
          },
        );
      },
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.pinkAccent.withOpacity(0.5), width: 1.5),
      ),
      child: ClipOval(
        child: Image.asset(
          _namiraAvatarAsset,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Center(
            child: Text('N', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitLoaded) {
      return Scaffold(
        backgroundColor: widget.isDarkMode ? const Color(0xFF0E1621) : Colors.white,
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF2481CC)),
        ),
      );
    }

    return Directionality(
      textDirection: widget.currentLanguage == 'fa' ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: widget.isDarkMode ? const Color(0xFF17212B) : const Color(0xFF2481CC),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              _buildAvatar(),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.currentLanguage == 'fa' ? 'دستیار نامیرا' : 'Namira Assistant',
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  const Text('online', style: TextStyle(fontSize: 11, color: Colors.white70)),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: _openSettings,
            ),
          ],
        ),
        drawer: Drawer(
          backgroundColor: widget.isDarkMode ? const Color(0xFF17212B) : Colors.white,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: widget.isDarkMode ? const Color(0xFF0E1621) : const Color(0xFF2481CC),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          _namiraAvatarAsset,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Center(
                            child: Text('N', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.currentLanguage == 'fa' ? 'هوش مصنوعی نامیرا' : 'Namira AI',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.add, color: Colors.blueAccent),
                title: Text(widget.currentLanguage == 'fa' ? 'چت جدید' : 'New Chat'),
                onTap: () => _startNewChat(),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  widget.currentLanguage == 'fa' ? 'تاریخچه گفتگوها' : 'Recent Chats',
                  style: TextStyle(color: widget.isDarkMode ? Colors.white54 : Colors.black54, fontSize: 12),
                ),
              ),
              ..._sessions.map((session) => ListTile(
                    title: Text(session.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    selected: session.id == _currentSession.id,
                    selectedColor: const Color(0xFF2481CC),
                    onTap: () => _selectSession(session),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                      onPressed: () => _deleteSession(session.id),
                    ),
                  )),
            ],
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            color: widget.isDarkMode ? const Color(0xFF0E1621) : const Color(0xFFEFEFF4),
          ),
          child: Column(
            children: [
              Expanded(
                child: _currentSession.messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.pinkAccent.withOpacity(0.2),
                                    blurRadius: 15,
                                    spreadRadius: 5,
                                  )
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  _namiraAvatarAsset,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Center(
                                    child: Text('N', style: TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),
                            Text(
                              widget.currentLanguage == 'fa' ? 'سلام نفسم! چطور کمکت کنم؟' : 'Hello! How can I help?',
                              style: TextStyle(fontSize: 16, color: widget.isDarkMode ? Colors.white70 : Colors.black54),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                        itemCount: _currentSession.messages.length,
                        itemBuilder: (context, index) {
                          bool isUser = _currentSession.messages[index]["role"] == "user";
                          String content = _currentSession.messages[index]["content"]!;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                            child: GestureDetector(
                              onLongPress: () {
                                Clipboard.setData(ClipboardData(text: content));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(widget.currentLanguage == 'fa' ? 'پیام کپی شد!' : 'Message copied!'),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                                decoration: BoxDecoration(
                                  color: isUser
                                      ? (widget.isDarkMode ? const Color(0xFF2B5278) : const Color(0xFFEEFFDE))
                                      : (widget.isDarkMode ? const Color(0xFF182533) : Colors.white),
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: Radius.circular(isUser ? 16 : 4),
                                    bottomRight: Radius.circular(isUser ? 4 : 16),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  content,
                                  style: TextStyle(
                                    color: widget.isDarkMode ? Colors.white : Colors.black87,
                                    fontSize: 15,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              if (_isLoading) const LinearProgressIndicator(color: Color(0xFF2481CC)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: widget.isDarkMode ? const Color(0xFF17212B) : Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                        decoration: InputDecoration(
                          hintText: widget.currentLanguage == 'fa' ? 'پیام خود را بنویسید...' : 'Write a message...',
                          hintStyle: TextStyle(color: widget.isDarkMode ? Colors.white54 : Colors.black45),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isLoading ? Icons.stop_circle_rounded : Icons.send_rounded,
                        color: _isLoading ? Colors.redAccent : const Color(0xFF2481CC),
                      ),
                      onPressed: _isLoading ? _cancelRequest : _sendMessage,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
