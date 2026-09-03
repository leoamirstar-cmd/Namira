import 'package:dio/dio.dart';

class GeminiManager {
  // اینجا می‌تونی کلید API یا منطق اتصال مستقیم رو بذاری
  final Dio _dio = Dio();

  Future<String> sendPromptRacing({
    required String prompt,
    required CancelToken cancelToken,
  }) async {
    try {
      // شبیه‌سازی درخواست یا اتصال به API اصلی جمنای
      // می‌تونی کد اتصال واقعی خودت رو اینجا قرار بدی
      await Future.delayed(const Duration(seconds: 1));
      return "سلام ناخدا! پیام شما دریافت شد: '$prompt' — همه‌چیز عالی پیش میره! ⚓️";
    } catch (e) {
      throw Exception("خطا در ارتباط با هوش مصنوعی: $e");
    }
  }
}
