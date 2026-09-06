import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
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
  
  final Map<String, double> _downloadProgress = {};

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
      final String? historyString = prefs.getString('music_chat_history_v6');
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
                  author: item['author'] ?? 'یوتیوب موزیک',
                  audioUrl: item['audioUrl'] ?? '',
                  duration: item['duration'] ?? '00:00',
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
      await prefs.setString('music_chat_history_v6', jsonEncode(listToSave));
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

  // متد قدرتمند استخراج مستقیم موزیک از یوتیوب بدون نیاز به سرور
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

    final yt = YoutubeExplode();

    try {
      // ۱. جستجوی عنوان موزیک در یوتیوب
      var searchResult = await yt.search.search(query);
      if (searchResult.isEmpty) {
        setState(() {
          _chatItems.add({"type": "system", "text": 'موزیک مورد نظر در یوتیوب پیدا نشد!'});
        });
        _saveHistory();
        return;
      }

      var video = searchResult.first;

      // ۲. دریافت لینک مستقیم فایل صوتی با بالاترین بیت‌ریت
      var manifest = await yt.videos.streamsClient.getManifest(video.id);
      var audioStreamInfo = manifest.audioOnly.withHighestBitrate();
      String audioUrl = audioStreamInfo.url.toString();

      String durationFormatted = video.duration != null
          ? "${video.duration!.inMinutes.remainder(60).toString().padLeft(2, '0')}:${video.duration!.inSeconds.remainder(60).toString().padLeft(2, '0')}"
          : "03:30";

      MusicMessageModel musicModel = MusicMessageModel(
        title: video.title,
        author: video.author,
        audioUrl: audioUrl,
        duration: durationFormatted,
        isDownloaded: false,
      );

      setState(() {
        _chatItems.add({
          "type": "music",
          "music": musicModel,
        });
      });
      _saveHistory();

    } catch (e) {
      setState(() {
        _chatItems.add({
          "type": "system",
          "text": 'خطا در دریافت موزیک. مطمئن شوید فیلترشکن شما متصل است.',
        });
      });
      _saveHistory();
    } finally {
      yt.close(); // بستن اتصال برای حفظ منابع حافظه
      setState(() {
        _isLoading = false;
      });
    }
  }

  // متد پخش و توقف موزیک
  Future<void> _togglePlayPause(MusicMessageModel music) async {
    try {
      if (_currentlyPlayingUrl == music.audioUrl && _audioPlayer.playing) {
        await _audioPlayer.pause();
        setState(() {
          music.isPlaying = false;
        });
      } else {
        // تنظیم منبع صوتی همراه با هدرهای استاندارد برای عبور از پروتکل‌های یوتیوب
        final AudioSource audioSource = AudioSource.uri(
          Uri.parse(music.audioUrl),
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          },
        );

        await _audioPlayer.setAudioSource(audioSource);
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خطا در پخش موزیک. فیلترشکن را بررسی کنید.')),
        );
      }
    }
  }

  // متد دانلود مستقیم روی کارت موزیک
  Future<void> _downloadMusic(MusicMessageModel music) async {
    try {
      Directory? downloadsDir = await getExternalStorageDirectory();
      
      // پاکسازی نام فایل از کاراکترهای غیرمجاز
      String safeTitle = music.title.replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]+'), '_');
      String savePath = "${downloadsDir?.path}/$safeTitle.mp3";

      Dio dio = Dio();
      await dio.download(
        music.audioUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _downloadProgress[music.audioUrl] = received / total;
            });
          }
        },
      );

      setState(() {
        music.isDownloaded = true;
        _downloadProgress.remove(music.audioUrl);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('آهنگ با موفقیت ذخیره شد: $safeTitle'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خطا در دانلود موزیک'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List<MusicMessageModel> recentTracks = _chatItems
        .where((item) => item["type"] == "music")
        .map((item) => item["music"] as MusicMessageModel)
        .toList()
        .reversed
        .toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xFF0F172A),
          title: const Row(
            children: [
              Icon(Icons.music_note_rounded, color: Colors.greenAccent),
              SizedBox(width: 8),
              Text('استریم و جستجوی موزیک', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.history_rounded, color: Colors.greenAccent),
              tooltip: 'تاریخچه موزیک‌ها',
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        drawer: Drawer(
          backgroundColor: const Color(0xFF1E293B),
          child: Column(
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.green, Color(0xFF0F172A)]),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.library_music_rounded, size: 48, color: Colors.white),
                      SizedBox(height: 8),
                      Text('آخرین موزیک‌های دریافتی', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: recentTracks.isEmpty
                    ? const Center(child: Text('تاریخچه‌ای وجود ندارد', style: TextStyle(color: Colors.white54)))
                    : ListView.builder(
                        itemCount: recentTracks.length,
                        itemBuilder: (context, index) {
                          final track = recentTracks[index];
                          return ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.green,
                              child: Icon(Icons.play_arrow_rounded, color: Colors.white),
                            ),
                            title: Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13)),
                            subtitle: Text(track.author, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                            onTap: () {
                              Navigator.pop(context);
                              _togglePlayPause(track);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0F172A), Color(0xFF020617)],
            ),
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
                              padding: const EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.green.withOpacity(0.1),
                                border: Border.all(color: Colors.green.withOpacity(0.3), width: 2),
                              ),
                              child: const Icon(Icons.headphones_rounded, size: 64, color: Colors.greenAccent),
                            ),
                            const SizedBox(height: 20),
                            const Text('اسم موزیک یا خواننده را بنویسید', style: TextStyle(fontSize: 15, color: Colors.white70)),
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
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade800,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(item["text"], style: const TextStyle(color: Colors.white, fontSize: 13)),
                              ),
                            );
                          } else if (item["type"] == "system") {
                            return Center(
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white10,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(item["text"], style: const TextStyle(color: Colors.white70, fontSize: 12), textAlign: TextAlign.center),
                              ),
                            );
                          } else {
                            MusicMessageModel music = item["music"];
                            double? progress = _downloadProgress[music.audioUrl];

                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                width: MediaQuery.of(context).size.width * 0.88,
                                margin: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
                                ),
                                child: Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(14.0),
                                      child: Row(
                                        children: [
                                          GestureDetector(
                                            onTap: () => _togglePlayPause(music),
                                            child: Container(
                                              width: 52,
                                              height: 52,
                                              decoration: const BoxDecoration(
                                                shape: BoxShape.circle,
                                                gradient: LinearGradient(colors: [Colors.green, Colors.teal]),
                                              ),
                                              child: Icon(
                                                music.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                                color: Colors.white,
                                                size: 32,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(music.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                                                const SizedBox(height: 4),
                                                Text(music.author, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.white60)),
                                              ],
                                            ),
                                          ),
                                          Text(music.duration, style: const TextStyle(fontSize: 11, color: Colors.greenAccent)),
                                        ],
                                      ),
                                    ),
                                    // نوار پایینی جهت دانلود اختصاصی موزیک
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF0F172A),
                                        borderRadius: BorderRadius.only(
                                          bottomLeft: Radius.circular(20),
                                          bottomRight: Radius.circular(20),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          if (progress != null)
                                            Expanded(
                                              child: LinearProgressIndicator(value: progress, color: Colors.greenAccent, backgroundColor: Colors.white10),
                                            )
                                          else
                                            Text(
                                              music.isDownloaded ? 'ذخیره شده در حافظه' : 'ذخیره در حافظه گوشی',
                                              style: TextStyle(fontSize: 11, color: music.isDownloaded ? Colors.greenAccent : Colors.white54),
                                            ),
                                          IconButton(
                                            icon: Icon(
                                              music.isDownloaded ? Icons.check_circle_rounded : Icons.download_rounded,
                                              color: music.isDownloaded ? Colors.greenAccent : Colors.white70,
                                              size: 20,
                                            ),
                                            onPressed: music.isDownloaded || progress != null ? null : () => _downloadMusic(music),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                        },
                      ),
              ),
              if (_isLoading) const LinearProgressIndicator(color: Colors.greenAccent, backgroundColor: Colors.transparent),
              Container(
                padding: const EdgeInsets.all(12),
                color: const Color(0xFF1E293B),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _urlController,
                        onChanged: (val) => _onTextChanged(),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'نام آهنگ یا خواننده...',
                          hintStyle: const TextStyle(color: Colors.white38),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        ),
                        onSubmitted: (val) => _processMusicSearch(val),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: Colors.green,
                      radius: 22,
                      child: IconButton(
                        icon: const Icon(Icons.search_rounded, color: Colors.white),
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
