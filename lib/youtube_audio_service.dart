import 'dart:io';
import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:just_audio/just_audio.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

// مدل ساده برای نگهداری اطلاعات آهنگ
class AudioItem {
  final String id;
  final String title;
  final String author;

  AudioItem({required this.id, required this.title, required this.author});
}

class YoutubeAudioService {
  final AudioPlayer _player = AudioPlayer();
  AudioPlayer get player => _player;

  // هدر برای جلوگیری از بلاک شدن توسط یوتیوب
  final Map<String, String> _headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
  };

  // ۱. جستجوی سریع آهنگ‌ها
  Future<List<AudioItem>> searchMusic(String query) async {
    var yt = YoutubeExplode();
    List<AudioItem> results = [];
    try {
      var searchList = await yt.search.getVideos(query);
      for (var video in searchList.take(5)) {
        results.add(AudioItem(
          id: video.id.value,
          title: video.title,
          author: video.author,
        ));
      }
    } catch (e) {
      debugPrint('خطا در جستجو: $e');
    } finally {
      yt.close();
    }
    return results;
  }

  // ۲. گرفتن لینک زنده در ثانیه آخر (برای جلوگیری از انقضا)
  Future<String?> _getFreshStreamUrl(String videoId) async {
    var yt = YoutubeExplode();
    try {
      var manifest = await yt.videos.streamsClient.getManifest(videoId);
      var audioStream = manifest.audioOnly.withHighestBitrate();
      return audioStream.url.toString();
    } catch (e) {
      debugPrint('خطا در گرفتن لینک: $e');
      return null;
    } finally {
      yt.close();
    }
  }

  // ۳. پخش موزیک
  Future<bool> playAudio(String videoId) async {
    try {
      await _player.stop();
      String? freshUrl = await _getFreshStreamUrl(videoId);
      if (freshUrl == null) return false;

      await _player.setUrl(freshUrl, headers: _headers);
      _player.play();
      return true;
    } catch (e) {
      debugPrint('خطا در پخش: $e');
      return false;
    }
  }

  // ۴. دانلود موزیک
  Future<bool> downloadAudio(String videoId, String title) async {
    try {
      if (Platform.isAndroid) {
        await Permission.storage.request();
      }

      String? freshUrl = await _getFreshStreamUrl(videoId);
      if (freshUrl == null) return false;

      final directory = await getApplicationDocumentsDirectory();
      String cleanTitle = title.replaceAll(RegExp(r'[^\w\s\.-]'), '');
      final savePath = "${directory.path}/$cleanTitle.mp3";

      Dio dio = Dio();
      await dio.download(freshUrl, savePath, options: Options(headers: _headers));
      return true;
    } catch (e) {
      debugPrint('خطا در دانلود: $e');
      return false;
    }
  }

  void dispose() {
    _player.dispose();
  }
}
