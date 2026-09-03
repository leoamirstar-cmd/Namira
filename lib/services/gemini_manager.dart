import 'package:dio/dio.dart';

class GeminiManager {
  final Dio _dio = Dio();
  
  // کلید گروق شما
  final String apiKey = "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";

  Future<String> sendPromptRacing({
    required String prompt,
    required CancelToken cancelToken,
  }) async {
    if (apiKey.isEmpty) {
      return "❌ کلید API تنظیم نشده!";
    }
    
    try {
      // استفاده از اندپوینت استاندارد OpenAI-compatible شرکت Groq با مدل لاما
      final response = await _dio.post(
        'https://api.groq.com/openai/v1/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          "model": "llama-3.3-70b-versatile",
          "messages": [
            {
              "role": "user",
              "content": prompt
            }
          ]
        },
        cancelToken: cancelToken,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['choices'] != null && (data['choices'] as List).isNotEmpty) {
          final message = data['choices']['message'];
          if (message != null && message['content'] != null) {
            return message['content'] as String;
          }
        }
        return "پاسخی از هوش مصنوعی دریافت نشد.";
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
