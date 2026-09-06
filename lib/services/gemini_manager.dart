import 'dart:convert';
import 'dart:io';
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
    File? imageFile,
    required CancelToken cancelToken,
  }) async {
    await ProxyHelper.setupProxy(_dio);

    // پردازش اتوماتیک فایل تصویر در صورت ارسال شدن File
    if (imageFile != null && imageFile.existsSync()) {
      try {
        List<int> imageBytes = await imageFile.readAsBytes();
        base64Media = base64Encode(imageBytes);
        
        // تشخیص نوع فرمت عکس از روی پسوند فایل
        String extension = imageFile.path.split('.').last.toLowerCase();
        if (extension == 'png') {
          mimeType = 'image/png';
        } else if (extension == 'webp') {
          mimeType = 'image/webp';
        } else {
          mimeType = 'image/jpeg';
        }
      } catch (_) {}
    }

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

    List<Map<String, dynamic>> messagesToSend = List.from(_chatHistory);
    if (messagesToSend.length > 20) {
      messagesToSend = messagesToSend.sublist(messagesToSend.length - 20);
    }

    try {
      final response = await _dio.post(
        workerUrl,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
          validateStatus: (status) => true,
        ),
        data: {
          "model": "gpt-3.6",
          "messages": messagesToSend,
        },
        cancelToken: cancelToken,
      );

      // تبدیل امن پاسخ به Map اگر به صورت String خام برگشته باشد
      dynamic rawData = response.data;
      if (rawData is String) {
        try {
          rawData = jsonDecode(rawData);
        } catch (_) {
          // اگر متن ساده بود همان استرینگ می‌ماند
        }
      }

      if (response.statusCode == 200) {
        if (rawData is Map && rawData['choices'] != null && (rawData['choices'] as List).isNotEmpty) {
          final firstChoice = rawData['choices'][0];
          if (firstChoice['message'] != null && firstChoice['message']['content'] != null) {
            final replyText = firstChoice['message']['content'].toString();
            _chatHistory.add({
              "role": "assistant",
              "content": replyText,
            });
            return replyText;
          }
        }
        return "⚠️ پاسخ نامعتبر از سرور: $rawData";
      } else {
        if (_chatHistory.isNotEmpty) _chatHistory.removeLast();
        return "❌ خطای سرور (${response.statusCode}):\n$rawData";
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
    File? imageFile,
  }) async {
    return await sendPromptRacing(
      prompt: prompt,
      base64Media: base64Media,
      mimeType: mimeType,
      imageFile: imageFile,
      cancelToken: CancelToken(),
    );
  }
}
