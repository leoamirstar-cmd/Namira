import 'package:dio/dio.dart';

class GeminiManager {
  // فقط یک کلید ثابت
  final String _apiKey = "AQ.Ab8RN6IU-O-1-BqN3rnntAi2yzynHaZSkPYP6VIt6fIOpiHwMA";

  // فقط روی مدل 3.6
  final String _model = "gemini-3.6-flash";

  final Dio _dio = Dio();

  Future<String> sendPromptRacing({
    required String prompt,
    required CancelToken cancelToken,
  }) async {
    String url = "https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_apiKey";

    try {
      final response = await _dio.post(
        url,
        data: {
          "contents": [{
            "parts": [{"text": prompt}]
          }]
        },
        cancelToken: cancelToken,
        options: Options(receiveTimeout: const Duration(seconds: 20)),
      );

      if (response.statusCode == 200) {
        var candidates = response.data['candidates'];
        if (candidates != null && candidates.isNotEmpty) {
          String text = candidates[0]['content']['parts'][0]['text'].toString();
          if (text.isNotEmpty) return text;
        }
      }
      throw Exception("Invalid response from server.");
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        throw e;
      }
      throw Exception("Connection failed: ${e.message}");
    } catch (e) {
      throw Exception("Error: $e");
    }
  }
}
