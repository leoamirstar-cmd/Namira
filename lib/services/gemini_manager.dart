import 'package:dio/dio.dart';

class GeminiManager {
  final Dio _dio = Dio();
  
  // کلید API جدید
  final String apiKey = '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';

  Future<String> sendPromptRacing({
    required String prompt,
    required CancelToken cancelToken,
  }) async {
    if (apiKey.isEmpty) {
      return "❌ کلید API تنظیم نشده!";
    }
    
    try {
      final response = await _dio.post(
        'https://api.groq.com/openai/v1/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          validateStatus: (status) => status! < 500,
        ),
        data: {
          "model": "llama-3.1-8b-instant",
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
          final firstChoice = data['choices'][0];
          if (firstChoice != null && 
              firstChoice['message'] != null && 
              firstChoice['message']['content'] != null) {
            return firstChoice['message']['content'].toString();
          }
        }
        return "پاسخی دریافت نشد.";
      } else {
        return "خطای سرور (${response.statusCode}): ${response.data}";
      }
    } on DioException catch (e) {
      return "خطای اتصال: ${e.message}";
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
