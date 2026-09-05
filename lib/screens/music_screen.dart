import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_models.dart';

class MusicScreen extends StatefulWidget {
  final String currentLanguage;
  final bool isDarkMode;

  const MusicScreen({super.key, required this.currentLanguage, required this.isDarkMode});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  late final TextEditingController _urlController;
  final List<Map<String, dynamic>> _chatItems = [];
  bool _isLoading = false;
  
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentlyPlayingUrl;
  
  final String _serverBaseUrl = 'https://namira-music-api.leoamirstar.workers.dev';

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: 'پخش موزیک ');
    _loadHistory();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? historyString = prefs.getString('music_chat_history_v5');
      if (historyString != null) {
        List<dynamic> decoded = jsonDecode(historyString);
        setState(() {
          _chatItems.clear();
          for (var item in decoded) {
            if (item['type'] == 'user') {
              _chatItems.add({"type": "user", "text": item['text']});
            } else if (item['type'] == 'system') {
              _chatItems.add({"type": "system", "text": item['text']});
            } else if (item['type'] == 'music') {
              _chatItems.add({
                "type": "music",
                "music": MusicMessageModel(
                  title: item['title'] ?? 'موزیک',
                  author: item['author'] ?? 'نامیرا موزیک',
                  audioUrl: item['audioUrl'] ?? '',
                  duration: item['duration'] ?? '00:30',
                  isDownloaded: false,
                ),
              });
            }
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<Map<String, dynamic>> listToSave = [];
      for (var item in _chatItems) {
        if (item['type'] == 'user') {
          listToSave.add({"type": "user", "text": item['text']});
        } else if (item['type'] == 'system') {
          listToSave.add({"type": "system", "text": item['text']});
        } else if (item['type'] == 'music') {
          MusicMessageModel m = item['music'];
          listToSave.add({
            "type": "music",
            "title": m.title,
            "author": m.author,
            "audioUrl": m.audioUrl,
            "duration": m.duration,
          });
        }
      }
      await prefs.setString('music_chat_history_v5', jsonEncode(listToSave));
    } catch (_) {}
  }

  void _onTextChanged() {
    const prefix = 'پخش موزیک ';
    if (!_urlController.text.startsWith(prefix)) {
      _urlController.text = prefix;
      _urlController.selection = TextSelection.fromPosition(
        TextPosition(offset: _urlController.text.length),
      );
    }
  }

  Future<void> _processMusicSearch(String fullInput) async {
    const prefix = 'پخش موزیک ';
    String query = fullInput.replaceFirst(prefix, '').trim();

    if (query.isEmpty || _isLoading) return;

    _urlController.text = prefix;
    setState(() {
      _chatItems.add({"type": "user", "text": fullInput});
      _isLoading = true;
    });
    _saveHistory();

    try {
      Dio dio = Dio();
      var response = await dio.get(
        '$_serverBaseUrl/search',
        queryParameters: {'q': query},
        options: Options(
          receiveTimeout: const Duration(minutes: 1),
          sendTimeout: const Duration(minutes: 1),
        ),
      );

      String audioUrl = '';
      String trackTitle = query;
      String trackAuthor = 'نامیرا موزیک';
      String trackDuration = '00:30';
      
      if (response.statusCode == 200 && response.data != null) {
        audioUrl = response.data['url'] ?? '';
        trackTitle = response.data['title'] ?? query;
        trackAuthor = response.data['author'] ?? 'نامیرا موزیک';
        trackDuration = response.data['duration'] ?? '00:30';
      }

      if (audioUrl.isEmpty) {
        setState(() {
          _chatItems.add({
            "type": "system",
            "text": 'موزیک مورد نظر پیدا نشد!',
          });
        });
        _saveHistory();
        return;
      }

      MusicMessageModel musicModel = MusicMessageModel(
        title: trackTitle,
        author: trackAuthor,
        audioUrl: audioUrl,
        duration: trackDuration,
        isDownloaded: false,
      );

      setState(() {
        _chatItems.add({
          "type": "music",
          "music": musicModel,
        });
      });
      _saveHistory();

    } on DioException catch (e) {
      String errorMessage = 'خطا در ارتباط با سرور موزیک';
      if (e.response?.statusCode == 404) {
        errorMessage = 'موزیک مورد نظر یافت نشد.';
      } else if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'سرور در حال بیدار شدن است، لطفاً دوباره تلاش کنید.';
      }
      setState(() {
        _chatItems.add({"type": "system", "text": errorMessage});
      });
      _saveHistory();
    } catch (_) {
      setState(() {
        _chatItems.add({"type": "system", "text": 'خطای غیرمنتظره‌ای رخ داد.'});
      });
      _saveHistory();
    } finally {
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
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('خطا در پخش صوت')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> searchHistory = _chatItems
        .where((item) => item["type"] == "user")
        .map((item) => item["text"].toString().replaceFirst('پخش موزیک ', ''))
        .toSet()
        .toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1DB954), Color(0xFF191414)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          title: Row(
            children: [
              const Icon(Icons.headphones_rounded, color: Colors.white),
              const SizedBox(width: 10),
              const Text('رادیو و استریم موزیک', style: TextStyle(color: Colors.white, fontSize: 15)),
              const Spacer(),
              if (searchHistory.isNotEmpty)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.history_rounded, color: Colors.white),
                  tooltip: 'تاریخچه جستجوها',
                  onSelected: (String selectedQuery) {
                    _processMusicSearch('پخش موزیک $selectedQuery');
                  },
                  itemBuilder: (BuildContext context) {
                    return searchHistory.map((String query) {
                      return PopupMenuItem<String>(
                        value: query,
                        child: Row(
                          children: [
                            const Icon(Icons.search, size: 16, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                query,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList();
                  },
                ),
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
                                  colors: [Colors.green.withOpacity(0.2), Colors.black.withOpacity(0.2)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: const Icon(Icons.radio_rounded, size: 64, color: Colors.green),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'تاریخچه خالی است. نام موزیک را جستجو کنید!',
                              style: TextStyle(fontSize: 14, color: widget.isDarkMode ? Colors.white70 : Colors.black54),
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
                                  color: Colors.green.shade700,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(item["text"], style: const TextStyle(color: Colors.white, fontSize: 13), textDirection: TextDirection.ltr),
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
                                child: Text(item["text"], style: TextStyle(color: widget.isDarkMode ? Colors.white60 : Colors.black54, fontSize: 13), textAlign: TextAlign.center),
                              ),
                            );
                          } else {
                            MusicMessageModel music = item["music"];

                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                width: MediaQuery.of(context).size.width * 0.85,
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: widget.isDarkMode ? const Color(0xFF182533) : Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 3)),
                                  ],
                                  border: Border.all(color: Colors.green.withOpacity(0.3), width: 1),
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
                                          color: Colors.green,
                                          boxShadow: [
                                            BoxShadow(color: Colors.green.withOpacity(0.4), blurRadius: 8, spreadRadius: 2),
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
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: widget.isDarkMode ? Colors.white : Colors.black87),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            music.author,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(fontSize: 11, color: widget.isDarkMode ? Colors.white60 : Colors.black54),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(music.duration, style: const TextStyle(fontSize: 11, color: Colors.green)),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.stream_rounded, color: Colors.green, size: 24),
                                  ],
                                ),
                              ),
                            );
                          }
                        },
                      ),
              ),
              if (_isLoading) const LinearProgressIndicator(color: Colors.green),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                color: widget.isDarkMode ? const Color(0xFF17212B) : Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _urlController,
                        onChanged: (val) => _onTextChanged(),
                        style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                        textDirection: TextDirection.ltr,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        ),
                        onSubmitted: (val) => _processMusicSearch(val),
                      ),
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send_rounded, color: Colors.white),
                        onPressed: () => _processMusicSearch(_urlController.text),
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
