import 'package:dio/dio.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'services/gemini_manager.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NamiraApp());
}

class ChatSessionModel {
  String id;
  String title;
  List<Map<String, String>> messages;

  ChatSessionModel({required this.id, required this.title, required this.messages});

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'messages': messages,
      };

  factory ChatSessionModel.fromJson(Map<String, dynamic> json) => ChatSessionModel(
        id: json['id'],
        title: json['title'],
        messages: List<Map<String, String>>.from(json['messages'].map((x) => Map<String, String>.from(x))),
      );
}

class MusicMessageModel {
  String title;
  String author;
  String audioUrl;
  String duration;
  bool isPlaying;
  bool isDownloaded;

  MusicMessageModel({
    required this.title,
    required this.author,
    required this.audioUrl,
    required this.duration,
    this.isPlaying = false,
    this.isDownloaded = false,
  });
}

class NamiraApp extends StatefulWidget {
  const NamiraApp({super.key});

  @override
  State<NamiraApp> createState() => _NamiraAppState();
}

class _NamiraAppState extends State<NamiraApp> {
  ThemeMode _themeMode = ThemeMode.dark;
  String _language = 'fa';
  
  void _toggleTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  void _changeLanguage(String lang) {
    setState(() {
      _language = lang;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Namira Hub',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF2481CC),
        scaffoldBackgroundColor: const Color(0xFFFFFFFF),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2481CC), brightness: Brightness.light),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF2B5278),
        scaffoldBackgroundColor: const Color(0xFF0E1621),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2B5278), brightness: Brightness.dark),
      ),
      home: MainSelectionScreen(
        onToggleTheme: _toggleTheme,
        onChangeLanguage: _changeLanguage,
        currentLanguage: _language,
        isDarkMode: _themeMode == ThemeMode.dark,
      ),
    );
  }
}

class MainSelectionScreen extends StatelessWidget {
  final Function(bool) onToggleTheme;
  final Function(String) onChangeLanguage;
  final String currentLanguage;
  final bool isDarkMode;

  const MainSelectionScreen({
    super.key,
    required this.onToggleTheme,
    required this.onChangeLanguage,
    required this.currentLanguage,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: currentLanguage == 'fa' ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: isDarkMode ? const Color(0xFF0E1621) : const Color(0xFFF4F4F6),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDarkMode 
                ? [const Color(0xFF0E1621), const Color(0xFF1F1135), const Color(0xFF111E38)]
                : [const Color(0xFFE0F7FA), const Color(0xFFFCE4EC), const Color(0xFFF3E5F5)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Colors.pinkAccent, Colors.purpleAccent, Colors.blueAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.pinkAccent.withOpacity(0.4),
                          blurRadius: 25,
                          spreadRadius: 8,
                        )
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(3.0),
                      child: ClipOval(
                        child: Image.asset(
                          "assets/images/namira_avatar.png",
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Center(
                            child: Text('N', style: TextStyle(fontSize: 42, color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Colors.pinkAccent, Colors.purpleAccent, Colors.cyanAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: Text(
                      currentLanguage == 'fa' ? 'پلتفرم هوشمند نامیرا' : 'Namira Smart Platform',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentLanguage == 'fa' ? 'یک تجربه پرزرق‌وبرق و مدرن' : 'A vibrant & modern experience',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.white60 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildFancyMenuCard(
                    context,
                    title: currentLanguage == 'fa' ? 'هوش مصنوعی نامیرا' : 'Namira AI Assistant',
                    subtitle: currentLanguage == 'fa' ? 'چت و همراهی با دستیار هوشمند' : 'Chat with smart assistant',
                    icon: Icons.auto_awesome_rounded,
                    gradientColors: [const Color(0xFF2481CC), const Color(0xFF00C6FF)],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            onToggleTheme: onToggleTheme,
                            onChangeLanguage: onChangeLanguage,
                            currentLanguage: currentLanguage,
                            isDarkMode: isDarkMode,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildFancyMenuCard(
                    context,
                    title: currentLanguage == 'fa' ? 'کلاب دانلود موزیک' : 'Music Downloader Club',
                    subtitle: currentLanguage == 'fa' ? 'جستجو، پخش آنلاین و ذخیره موزیک' : 'Search, stream & download music',
                    icon: Icons.headphones_rounded,
                    gradientColors: [const Color(0xFFFF416C), const Color(0xFFFF4B2B)],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MusicScreen(
                            currentLanguage: currentLanguage,
                            isDarkMode: isDarkMode,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFancyMenuCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required List<Color> gradientColors, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.85))),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class MusicScreen extends StatefulWidget {
  final String currentLanguage;
  final bool isDarkMode;

  const MusicScreen({super.key, required this.currentLanguage, required this.isDarkMode});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> _chatItems = [];
  bool _isLoading = false;
  
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentlyPlayingUrl;

  @override
  void dispose() {
    _audioPlayer.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchAndSendMusic(String query) async {
    if (query.trim().isEmpty || _isLoading) return;

    String searchQuery = query.trim();
    _searchController.clear();

    setState(() {
      _chatItems.add({"type": "user", "text": searchQuery});
      _isLoading = true;
    });

    yt.YoutubeExplode? ytInstance;
    try {
      ytInstance = yt.YoutubeExplode();
      var searchResults = await ytInstance.search.search(searchQuery);

      if (searchResults.isNotEmpty) {
        yt.Video? validVideo;
        yt.StreamManifest? manifest;

        for (var video in searchResults.take(5)) {
          try {
            var tempManifest = await ytInstance.videos.streamsClient.getManifest(video.id);
            if (tempManifest.audioOnly.isNotEmpty) {
              validVideo = video;
              manifest = tempManifest;
              break;
            }
          } catch (_) {
            continue;
          }
        }

        if (validVideo != null && manifest != null) {
          var audioStream = manifest.audioOnly.withHighestBitrate();
          String audioUrl = audioStream.url.toString();
          String title = validVideo.title;
          String author = validVideo.author;
          String duration = validVideo.duration != null 
              ? "${validVideo.duration!.inMinutes}:${(validVideo.duration!.inSeconds % 60).toString().padLeft(2, '0')}" 
              : "03:30";

          setState(() {
            _chatItems.add({
              "type": "music",
              "music": MusicMessageModel(
                title: title,
                author: author,
                audioUrl: audioUrl,
                duration: duration,
              ),
            });
          });
        } else {
          throw Exception("موزیک معتبری یافت نشد.");
        }
      } else {
        setState(() {
          _chatItems.add({
            "type": "system",
            "text": widget.currentLanguage == 'fa' ? 'موزیکی با این مشخصات پیدا نشد!' : 'No music found for this query!',
          });
        });
      }
    } catch (e) {
      setState(() {
        _chatItems.add({
          "type": "system",
          "text": widget.currentLanguage == 'fa' ? 'خطا در دریافت موزیک: لطفاً دوباره تلاش کنید.' : 'Error fetching music: Please try again.',
        });
      });
    } finally {
      ytInstance?.close();
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _togglePlayPause(MusicMessageModel music) async {
    try {
      if (_currentlyPlayingUrl == music.audioUrl && _audioPlayer.playing) {
        await _audioPlayer.pause();
        setState(() {
          music.isPlaying = false;
        });
      } else {
        await _audioPlayer.setUrl(music.audioUrl);
        await _audioPlayer.play();
        setState(() {
          for (var item in _chatItems) {
            if (item["type"] == "music") {
              (item["music"] as MusicMessageModel).isPlaying = false;
            }
          }
          _currentlyPlayingUrl = music.audioUrl;
          music.isPlaying = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در پخش صوت: $e')),
      );
    }
  }

  Future<void> _downloadMusic(MusicMessageModel music) async {
    await Permission.storage.request();
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.currentLanguage == 'fa' ? 'در حال دانلود و ذخیره موزیک...' : 'Downloading and saving music...')),
      );

      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!directory.existsSync()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      String safeTitle = music.title.replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(' ', '_');
      String filePath = "${directory!.path}/$safeTitle.mp3";

      Dio dio = Dio();
      await dio.download(music.audioUrl, filePath);

      setState(() {
        music.isDownloaded = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text(widget.currentLanguage == 'fa' ? 'موزیک با موفقیت ذخیره شد!' : 'Music successfully saved!'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.redAccent, content: Text('خطا در دانلود فایل: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: widget.currentLanguage == 'fa' ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          title: Row(
            children: [
              const Icon(Icons.headphones_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Text(widget.currentLanguage == 'fa' ? 'کلاب موزیک نامیرا' : 'Namira Music Club', style: const TextStyle(color: Colors.white)),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            color: widget.isDarkMode ? const Color(0xFF0E1621) : const Color(0xFFF8F9FA),
          ),
          child: Column(
            children: [
              Expanded(
                child: _chatItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [Colors.pinkAccent.withOpacity(0.2), Colors.purpleAccent.withOpacity(0.2)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: const Icon(Icons.music_note_rounded, size: 64, color: Colors.pinkAccent),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              widget.currentLanguage == 'fa' ? 'اسم آهنگ یا خواننده رو بنویس تا برات پیدا کنم!' : 'Type song name or artist to find!',
                              style: TextStyle(fontSize: 15, color: widget.isDarkMode ? Colors.white70 : Colors.black54),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _chatItems.length,
                        itemBuilder: (context, index) {
                          var item = _chatItems[index];
                          if (item["type"] == "user") {
                            return Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(item["text"], style: const TextStyle(color: Colors.white, fontSize: 15)),
                              ),
                            );
                          } else if (item["type"] == "system") {
                            return Center(
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(item["text"], style: TextStyle(color: widget.isDarkMode ? Colors.white60 : Colors.black54, fontSize: 13)),
                              ),
                            );
                          } else {
                            MusicMessageModel music = item["music"];
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                width: MediaQuery.of(context).size.width * 0.8,
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: widget.isDarkMode ? const Color(0xFF182533) : Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 3)),
                                  ],
                                  border: Border.all(color: Colors.pinkAccent.withOpacity(0.3), width: 1),
                                ),
                                child: Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () => _togglePlayPause(music),
                                      child: Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          boxShadow: [
                                            BoxShadow(color: Colors.pinkAccent.withOpacity(0.4), blurRadius: 8, spreadRadius: 2),
                                          ],
                                        ),
                                        child: Icon(
                                          music.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            music.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: widget.isDarkMode ? Colors.white : Colors.black87),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            music.author,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(fontSize: 12, color: widget.isDarkMode ? Colors.white60 : Colors.black54),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(music.duration, style: const TextStyle(fontSize: 11, color: Colors.pinkAccent)),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        music.isDownloaded ? Icons.check_circle_rounded : Icons.download_rounded,
                                        color: music.isDownloaded ? Colors.green : Colors.pinkAccent,
                                      ),
                                      onPressed: music.isDownloaded ? null : () => _downloadMusic(music),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                        },
                      ),
              ),
              if (_isLoading) const LinearProgressIndicator(color: Colors.pinkAccent),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                color: widget.isDarkMode ? const Color(0xFF17212B) : Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                        decoration: InputDecoration(
                          hintText: widget.currentLanguage == 'fa' ? 'نام آهنگ یا خواننده را جستجو کنید...' : 'Search song or artist...',
                          hintStyle: TextStyle(color: widget.isDarkMode ? Colors.white54 : Colors.black45),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        ),
                        onSubmitted: (val) => _searchAndSendMusic(val),
                      ),
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.search_rounded, color: Colors.white),
                        onPressed: () => _searchAndSendMusic(_searchController.text),
                      ),
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