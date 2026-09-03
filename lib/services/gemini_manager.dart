import 'package:dio/dio.dart';

class GeminiManager {
  final Dio _dio = Dio();
  final String apiKey = "AQ.Ab8RN6LxltJX8CgCOTO98r7TwKDKO_jU3t2HZfnS0kOe2_ppRw";

  Future<String> sendPromptRacing({
    required String prompt,
    required CancelToken cancelToken,
  }) async {
    if (apiKey.isEmpty) {
      return "سلام ناخدا! هوش مصنوعی آماده‌ست، اما کلید تنظیم نشده.";
    }
    
    try {
      final response = await _dio.post(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
        data: {
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ]
        },
        cancelToken: cancelToken,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['candidates'] != null && 
            (data['candidates'] as List).isNotEmpty) {
          final candidate = data['candidates'];
          if (candidate['content'] != null && 
              candidate['content']['parts'] != null) {
            final parts = candidate['content']['parts'] as List;
            if (parts.isNotEmpty && parts['text'] != null) {
              return parts['text'] as String;
            }
          }
        }
        return "پاسخی از جمنای دریافت نشد.";
      }
      return "در خدمتم ناخدا! (خطای ارتباطی)";
    } catch (e) {
      // برای اینکه برنامه به جای ارور دادن، همیشه روان کار کنه
      return "جانم ناخدا؟ پیامت رو دریافت کردم ولی اتصال به سرور محدوده. بریم سراغ بخش موزیک؟ ⚓️🎵";
    }
  }

  Future<String> sendMessage(String prompt) async {
    return await sendPromptRacing(
      prompt: prompt, 
      cancelToken: CancelToken(),
    );
  }
}
