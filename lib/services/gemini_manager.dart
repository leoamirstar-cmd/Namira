import 'package:dio/dio.dart';

class GeminiManager {
  // لیست ۱۰ کلید API شما
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

  // لیست مدل‌های مختلف جمنای برای مسابقه سرعت (Race)
  final List<String> _models = [
    "gemini-2.5-flash",
    "gemini-1.5-flash",
    "gemini-1.5-pro",
  ];

  final Dio _dio = Dio();

  // گرفتن کلید فعلی و جابجایی به کلید بعدی (Round-Robin)
  String _getNextKey() {
    String key = _apiKeys[_currentKeyIndex];
    _currentKeyIndex = (_currentKeyIndex + 1) % _apiKeys.length;
    return key;
  }

  /// متد اصلی برای ارسال پیام با قابلیت مسابقه بین مدل‌ها و لغو درخواست (CancelToken)
  Future<String> sendPromptRacing({
    required String prompt,
    required CancelToken cancelToken,
  }) async {
    // ایجاد یک پادشاه (Completer) برای اولین پاسخی که برسه
    final futures = _models.map((model) async {
      int attempts = 0;
      while (attempts < 3) {
        if (cancelToken.isCancelled) throw DioException(requestOptions: RequestOptions(path: ''), type: DioExceptionType.cancel);
        
        String apiKey = _getNextKey();
        // استفاده از آدرس ورکر کلادفلر شما به عنوان پروکسی
        String url = "https://gentle-bird-f095.leoamirstar.workers.dev/v1/models/$model:generateContent?key=$apiKey";

        try {
          final response = await _dio.post(
            url,
            data: {
              "contents": [{
                "parts": [{"text": prompt}]
              }]
            },
            cancelToken: cancelToken,
          );

          if (response.statusCode == 200) {
            // استخراج متن پاسخ از ساختار جمنای
            var candidates = response.data['candidates'];
            if (candidates != null && candidates.isNotEmpty) {
              return candidates[0]['content']['parts'][0]['text'].toString();
            }
          }
        } on DioException catch (e) {
          if (e.type == DioExceptionType.cancel) rethrow;
          // اگر خطای محدودیت سهمیه (429) یا سرور داد، با کلید بعدی تلاش کن
          attempts++;
        }
      }
      throw Exception("Model $model failed after retries.");
    }).toList();

    // مسابقه بین تمام مدل‌ها؛ اولین مدلی که جواب درست بده برنده است!
    try {
      return await Future.any(futures);
    } catch (e) {
      throw Exception("All models and keys failed or request cancelled.");
    }
  }
}

