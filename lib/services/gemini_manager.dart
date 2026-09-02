import 'package:dio/dio.dart';

class GeminiManager {
  final List<String> _apiKeys = [
    "AQ.Ab8RN6IU-O-1-BqN3rnntAi2yzynHaZSkPYP6VIt6fIOpiHwMA",
    "AQ.Ab8RN6KpVDYUUHM8lApCdcRSp5DJnk5dmYTH1igAq-P2bUCtfA",
    "AQ.Ab8RN6L0eB7oXhi5CQ3RvYMaQtXWmwbPV69bquwrwGhWLGb7Ew",
    "AQ.Ab8RN6L-S3GxhhT8FRkueXH9nlzll_4NsOeyze9PaZSY5MYbpg",
    "AQ.Ab8RN6Lp0HZpn_XXLnPoDx9eM2e2vbNkYuD5vkcuamA7SefvMg",
    "AQ.Ab8RN6KHpl2xN3nd1IgB3LflBqw866UKci0qRZysJdj0EHKPxw",
    "AQ.Ab8RN6L76p2TyJFA0cqkGqSnLctRWlknCebkWX9CBrlJVfdYSw",
    "AQ.Ab8RN6Kmh-p2JWzgu_RHzJ7JU9aM-AbjRSEdCsw-1Btg0TOj9g",
    "AQ.Ab8RN6KwsMCfWayWjPZzmmMCwu6xhAwCsoALFASbZltLkh2IXQ",
    "AQ.Ab8RN6Idrv65daj1lG6JmVhHXBFErI-W8CJvlUqv7Aj16U_Tfw",
  ];

  int _currentKeyIndex = 0;

  final List<String> _models = [
    "gemini-2.5-flash",
    "gemini-1.5-flash",
    "gemini-1.5-pro",
  ];

  final Dio _dio = Dio();

  String _getNextKey() {
    String key = _apiKeys[_currentKeyIndex];
    _currentKeyIndex = (_currentKeyIndex + 1) % _apiKeys.length;
    return key;
  }

  Future<String> sendPromptRacing({
    required String prompt,
    required CancelToken cancelToken,
  }) async {
    // برای جلوگیری از فشردگی بیش از حد روی گوگل، مدل‌ها رو یکی یکی یا با مدیریت بهتری صدا می‌زنیم
    for (String model in _models) {
      int attempts = 0;
      while (attempts < 2) {
        if (cancelToken.isCancelled) {
          throw DioException(requestOptions: RequestOptions(path: ''), type: DioExceptionType.cancel);
        }
        
        String apiKey = _getNextKey();
        String url = "https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey";

        try {
          final response = await _dio.post(
            url,
            data: {
              "contents": [{
                "parts": [{"text": prompt}]
              }]
            },
            cancelToken: cancelToken,
            options: Options(receiveTimeout: const Duration(seconds: 10)),
          );

          if (response.statusCode == 200) {
            var candidates = response.data['candidates'];
            if (candidates != null && candidates.isNotEmpty) {
              String text = candidates[0]['content']['parts'][0]['text'].toString();
              if (text.isNotEmpty) return text;
            }
          }
        } on DioException catch (e) {
          if (e.type == DioExceptionType.cancel) rethrow;
          // اگر ارور 429 (Too Many Requests) یا خطای لیمیت بود، سریعتر کلید بعدی رو تست میکنیم
        } catch (_) {}
        
        attempts++;
      }
    }

    throw Exception("All models and keys failed or request cancelled.");
  }
}
