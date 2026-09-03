import 'package:dio/dio.dart';

class GeminiManager {
  final Dio _dio = Dio();
  final String apiKey = "AQ.Ab8RN6Idrv65daj1lG6JmVhHXBFErI-W8CJvlUqv7Aj16U_Tfw";

  Future<String> sendPromptRacing({
    required String prompt,
    required CancelToken cancelToken,
  }) async {
    try {
      // استفاده از مسیر پایدار و استاندارد v1 برای جلوگیری از خطای 404
      final response = await _dio.post(
        'https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent?key=$apiKey',
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
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final candidate = data['candidates'];
          if (candidate['content'] != null && candidate['content']['parts'] != null) {
            final parts = candidate['content']['parts'];
            if (parts.isNotEmpty && parts['text'] != null) {
              return parts['text'];
            }
          }
        }
      }
      return "پاسخی از جمنای دریافت نشد.";
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        return "درخواست لغو شد.";
      }
      return "خطا در ارتباط با هوش مصنوعی: $e";
    }
  }

  Future<String> sendMessage(String prompt) async {
    return await sendPromptRacing(prompt: prompt, cancelToken: CancelToken());
  }
}
