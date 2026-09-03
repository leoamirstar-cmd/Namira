import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

class ProxyHelper {
  static Future<bool> setupProxy(Dio dio) async {
    try {
      const String proxyListUrl = 'https://raw.githubusercontent.com/your-username/your-repo/main/proxies.json';
      
      final response = await Dio().get(proxyListUrl);
      final List<dynamic> proxies = response.data['proxies'];

      for (var proxy in proxies) {
        String host = proxy['host'];
        int port = proxy['port'];

        try {
          final socket = await Socket.connect(host, port, timeout: const Duration(seconds: 2));
          socket.destroy();

          (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
            final client = HttpClient();
            client.findProxy = (uri) => "SOCKS5 $host:$port;";
            return client;
          };
          
          return true; // اتصال موفق
        } catch (_) {
          continue;
        }
      }
      return false; // هیچ پروکسی فعالی پیدا نشد
    } catch (_) {
      return false; // خطا در دانلود لیست
    }
  }
}
