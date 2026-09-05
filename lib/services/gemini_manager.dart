import 'package:dio/dio.dart';
import 'proxy_helper.dart';

class GeminiManager {
  final Dio _dio = Dio();
  
  // آدرس کلودفلر ورکر اختصاصی شما
  final String workerUrl = 'https://gentle-bonus-c031.leoamirstar.workers.dev/';

  // ذخیره سابقه چت
  final List<Map<String, dynamic>> _chatHistory = [];

  void clearHistory() {
    _chatHistory.clear();
  }

  Future<String> sendPromptRacing({
    required String prompt,
    String? base64Media,
    String? mimeType,
    required CancelToken cancelToken,
  }) async {
    await ProxyHelper.setupProxy(_dio);

    dynamic userContent;
    if (base64Media != null && base64Media.isNotEmpty) {
      userContent = [
        {"type": "text", "text": prompt},
        {
          "type": "image_url",
          "image_url": {
            "url": "data:${mimeType ?? 'image/jpeg'};base64,$base64Media"
          }
        }
      ];
    } else {
      userContent = prompt;
    }

    _chatHistory.add({
      "role": "user",
      "content": userContent,
    });

    List<Map<String, dynamic>> messagesToSend = _chatHistory;
    if (_chatHistory.length > 20) {
      messagesToSend = _chatHistory.sublist(_chatHistory.length - 20);
    }

    try {
      final response = await _dio.post(
        workerUrl,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
          validateStatus: (status) => true, // اجازه می‌دهد تمام ارورها را خودمان مدیریت کنیم
        ),
        data: {
          "model": "gpt-3.6", // تنظیم روی نسخه 3.6
          "messages": messagesToSend,
        },
        cancelToken: cancelToken,
      );

      // بررسی وضعیت پاسخ
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['choices'] != null && (data['choices'] as List).isNotEmpty) {
          final firstChoice = data['choices'][0];
          if (firstChoice['message'] != null && firstChoice['message']['content'] != null) {
            final replyText = firstChoice['message']['content'].toString();
            _chatHistory.add({
              "role": "assistant",
              "content": replyText,
            });
            return replyText;
          }
        }
        // اگر ساختار پاسخ متفاوت بود، متن خام را برگردان تا ببینیم
        return "⚠️ پاسخ نامعتبر از سرور: ${response.data}";
      } else {
        // حذف آخرین پیام از حافظه به خاطر بروز خطا
        _chatHistory.removeLast();
        // بازگرداندن متن دقیق ارور سرور
        return "❌ خطای سرور (${response.statusCode}):\n${response.data}";
      }
    } on DioException catch (e) {
      if (_chatHistory.isNotEmpty) _chatHistory.removeLast();
      return "❌ خطای شبکه/دیو: ${e.message} \n جزئیات: ${e.response?.data}";
    } catch (e) {
      if (_chatHistory.isNotEmpty) _chatHistory.removeLast();
      return "❌ خطای ناشناخته: $e";
    }
  }

  Future<String> sendMessage(
    String prompt, {
    String? base64Media,
    String? mimeType,
  }) async {
    return await sendPromptRacing(
      prompt: prompt,
      base64Media: base64Media,
      mimeType: mimeType,
      cancelToken: CancelToken(),
    );
  }
}
