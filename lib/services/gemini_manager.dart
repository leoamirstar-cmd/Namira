import 'package:dio/dio.dart';

class GeminiManager {
  final Dio _dio = Dio();
  // کلید API جمنای خودت رو اینجا قرار بده
  final String apiKey = "YOUR_GEMINI_API_KEY";

  Future<String> sendMessage(String prompt) async {
    try {
      final response = await _dio.post(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
        data: {
          "contents": [
            {
              "parts": [{"text": prompt}]
            }
          ]
        },
      );

      if (response.statusCode == 200) {
        final candidate = response.data['candidates'];
        if (candidate != null && candidate.isNotEmpty) {
          return candidate['content']['parts']['text'];
        }
      }
      return "پاسخی دریافت نشد!";
    } catch (e) {
      return "خطا در ارتباط با هوش مصنوعی: $e";
    }
  }
}
