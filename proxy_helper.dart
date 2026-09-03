import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

class ProxyHelper {
  static Future<void> setupProxy(Dio dio) async {
    try {
      // فعلا روی پورت و آی‌پی تستی (می‌تونی بعداً تغییرش بدی)
      String host = "127.0.0.1";
      int port = 1080;

      final socket = await Socket.connect(host, port, timeout: const Duration(seconds: 2));
      socket.destroy();

      (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.findProxy = (uri) => "SOCKS5 $host:$port;";
        return client;
      };
    } catch (_) {
      // اگر پروکسی وصل نشد، بدون پروکسی رد میشه
    }
  }
}
