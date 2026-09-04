import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import '../models/chat_models.dart';

class MusicScreen extends StatefulWidget {
  final String currentLanguage;
  final bool isDarkMode;

  const MusicScreen({super.key, required this.currentLanguage, required this.isDarkMode});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  final TextEditingController _urlController = TextEditingController();
  final List<Map<String, dynamic>> _chatItems = [];
  bool _isLoading = false;
  
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentlyPlayingUrl;

  @override
  void dispose() {
    _audioPlayer.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _processMusicLink(String urlInput) async {
    if (urlInput.trim().isEmpty || _isLoading) return;

    String musicUrl = urlInput.trim();
    _urlController.clear();

    setState(() {
      _chatItems.add({"type": "user", "text": musicUrl});
      _isLoading = true;
    });

    try {
      if (!musicUrl.contains('spotify') && !musicUrl.contains('soundcloud')) {
        setState(() {
          _chatItems.add({
            "type": "system",
            "text": 'لطفاً یک لینک معتبر از اسپاتیفای یا ساوندکلاد ارسال کنید!',
          });
        });
        return;
      }

      await Future.delayed(const Duration(seconds: 1));

      String trackId = musicUrl.split('/').last.split('?').first;
      bool isSpotify = musicUrl.contains('spotify');
      
      String title = isSpotify ? "آهنگ اسپاتیفای ($trackId)" : "موزیک ساوندکلاد ($trackId)";
      String author = isSpotify ? "Spotify Track" : "SoundCloud Creator";
      
      List<String> sampleAudioUrls = [
        "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3",
        "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3",
        "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3",
        "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3",
      ];
      String audioDownloadUrl = sampleAudioUrls[trackId.hashCode.abs() % sampleAudioUrls.length];

      MusicMessageModel musicModel = MusicMessageModel(
        title: title,
        author: author,
        audioUrl: audioDownloadUrl,
        duration: "03:45",
      );

      setState(() {
        _chatItems.add({
          "type": "music",
          "music": musicModel,
          "downloadProgress": 0.0,
          "isDownloading": true,
        });
      });

      int index = _chatItems.length - 1;
      await _downloadWithProgress(musicModel, index);

    } catch (e) {
      setState(() {
        _chatItems.add({
          "type": "system",
          "text": 'خطا در دریافت فایل. لطفاً دوباره تلاش کنید.',
        });
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadWithProgress(MusicMessageModel music, int itemIndex) async {
    try {
      await Permission.storage.request();
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
      if (safeTitle.length > 25) safeTitle = safeTitle.substring(0, 25);
      String filePath = "${directory!.path}/${safeTitle}_${DateTime.now().millisecondsSinceEpoch}.mp3";

      Dio dio = Dio();
      await dio.download(
        music.audioUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            double progress = received / total;
            setState(() {
              if (_chatItems[itemIndex]["type"] == "music") {
                _chatItems[itemIndex]["downloadProgress"] = progress;
              }
            });
          }
        },
      );

      setState(() {
        if (_chatItems[itemIndex]["type"] == "music") {
          _chatItems[itemIndex]["isDownloading"] = false;
          music.isDownloaded = true;
        }
      });
    } catch (_) {
      setState(() {
        if (_chatItems[itemIndex]["type"] == "music") {
          _chatItems[itemIndex]["isDownloading"] = false;
        }
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
        const SnackBar(content: Text('خطا در پخش صوت')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
          title: const Row(
            children: [
              Icon(Icons.cloud_download_rounded, color: Colors.white),
              SizedBox(width: 10),
              Text('دانلود از اسپاتیفای / ساوندکلاد', style: TextStyle(color: Colors.white, fontSize: 15)),
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
                              child: const Icon(Icons.link_rounded, size: 64, color: Colors.green),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'لینک آهنگ اسپاتیفای یا ساوندکلاد رو بفرست تا فایلو بهت بدم!',
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
                                child: Text(item["text"], style: TextStyle(color: widget.isDarkMode ? Colors.white60 : Colors.black54, fontSize: 13)),
                              ),
                            );
                          } else {
                            MusicMessageModel music = item["music"];
                            bool isDownloading = item["isDownloading"] ?? false;
                            double progress = item["downloadProgress"] ?? 0.0;

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
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        GestureDetector(
                                          onTap: isDownloading ? null : () => _togglePlayPause(music),
                                          child: Container(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: isDownloading ? Colors.grey : Colors.green,
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
                                        Icon(
                                          isDownloading ? Icons.downloading_rounded : Icons.check_circle_rounded,
                                          color: isDownloading ? Colors.orange : Colors.green,
                                        ),
                                      ],
                                    ),
                                    if (isDownloading) ...[
                                      const SizedBox(height: 12),
                                      LinearProgressIndicator(
                                        value: progress,
                                        color: Colors.green,
                                        backgroundColor: Colors.green.withOpacity(0.2),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'در حال دانلود: ${(progress * 100).toStringAsFixed(0)}%',
                                        style: TextStyle(fontSize: 10, color: widget.isDarkMode ? Colors.white54 : Colors.black54),
                                      ),
                                    ]
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
                        style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                        textDirection: TextDirection.ltr,
                        decoration: InputDecoration(
                          hintText: 'لینک Spotify یا SoundCloud را اینجا بفرستید...',
                          hintStyle: TextStyle(color: widget.isDarkMode ? Colors.white54 : Colors.black45, fontSize: 13),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        ),
                        onSubmitted: (val) => _processMusicLink(val),
                      ),
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send_rounded, color: Colors.white),
                        onPressed: () => _processMusicLink(_urlController.text),
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
