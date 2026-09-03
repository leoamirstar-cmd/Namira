import 'dart:io';
import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;
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
