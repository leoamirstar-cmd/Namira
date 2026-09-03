import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

class ProxyHelper {
  static Future<void> setupProxy(Dio dio) async {
    try {
      // لینک آنلاین فایل JSON که لیست پروکسی‌ها توش قرار داره
      const String proxyListUrl = 'https://raw.githubusercontent.com/your-username/your-repo/main/proxies.json';
      
      final response = await Dio().get(proxyListUrl);
      final List<dynamic> proxies = response.data['proxies'];

      for (var proxy in proxies) {
        String host = proxy['host'];
        int port = proxy['port'];

        try {
          // تست سریع اتصال پروکسی
          final socket = await Socket.connect(host, port, timeout: const Duration(seconds: 2));
          socket.destroy();

          // اگر پروکسی زنده بود، روی دیو ست میشه و از حلقه خارج میشیم
          (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
            final client = HttpClient();
            client.findProxy = (uri) => "SOCKS5 $host:$port;";
            return client;
          };
          break; 
        } catch (_) {
          // این پروکسی خراب بود، میره سراغ بعدی
          continue;
        }
      }
    } catch (_) {
      // اگر کلا دانلود لیست یا اتصال خطا داد، برنامه بدون پروکسی ادامه میده
    }
  }
}
