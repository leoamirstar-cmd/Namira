import 'package:dio/dio.dart';

class GeminiManager {
  final Dio _dio = Dio();
  
  // کلید جدیدت رو همینجا مستقیم گذاشتم تا توی بیلد گیت‌هاب بدون مشکل کار کنه
  final String apiKey = "AQ.Ab8RN6LxltJX8CgCOTO98r7TwKDKO_jU3t2HZfnS0kOe2_ppRw";

  Future<String> sendPromptRacing({
    required String prompt,
    required CancelToken cancelToken,
  }) async {
    if (apiKey.isEmpty) {
      return "❌ کلید API تنظیم نشده!";
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
          final candidate = data['candidates'][0];
          if (candidate['content'] != null && 
              candidate['content']['parts'] != null) {
            final parts = candidate['content']['parts'] as List;
            if (parts.isNotEmpty && parts[0]['text'] != null) {
              return parts[0]['text'] as String;
            }
          }
        }
        return "پاسخی از جمنای دریافت نشد.";
      }
      return "خطای HTTP: ${response.statusCode}";
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        return "درخواست لغو شد.";
      }
      return "خطا در ارتباط با هوش مصنوعی: ${e.message}";
    } catch (e) {
      return "خطای ناشناخته: $e";
    }
  }

  Future<String> sendMessage(String prompt) async {
    return await sendPromptRacing(
      prompt: prompt, 
      cancelToken: CancelToken(),
    );
  }
}
