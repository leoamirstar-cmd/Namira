import 'package:dio/dio.dart';

class GeminiManager {
  final Dio _dio = Dio();
  final String apiKey = "AQ.Ab8RN6Idrv65daj1lG6JmVhHXBFErI-W8CJvlUqv7Aj16U_Tfw"; // کلید API خودت رو اینجا بذار

  // استفاده از مدل جدید و به‌روز جمنای
  Future<String> sendPromptRacing({
    required String prompt,
    required CancelToken cancelToken,
  }) async {
    try {
      final response = await _dio.post(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey',
        data: {
          "contents": [
            {
              "parts": [{"text": prompt}]
            }
          ]
        },
        cancelToken: cancelToken,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          return data['candidates']['content']['parts']['text'];
        }
      }
      return "پاسخی از جمنای دریافت نشد.";
    } catch (e) {
      if (CancelToken.isCancel(e)) {
        return "درخواست لغو شد.";
      }
      return "خطا در ارتباط با هوش مصنوعی: $e";
    }
  }

  Future<String> sendMessage(String prompt) async {
    return await sendPromptRacing(prompt: prompt, cancelToken: CancelToken());
  }
}
