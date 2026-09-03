import 'package:dio/dio.dart';

class GeminiManager {
  final Dio _dio = Dio();
  final String apiKey = "AQ.Ab8RN6LxltJX8CgCOTO98r7TwKDKO_jU3t2HZfnS0kOe2_ppRw";

  Future<String> sendPromptRacing({
    required String prompt,
    required CancelToken cancelToken,
  }) async {
    try {
      // استفاده از ساختار استاندارد اندپوینت پروژه‌های کلود
      final response = await _dio.post(
        'https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent',
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
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
