import 'dart:io';

/// 端口工具类
class PortUtils {
  /// 检查端口是否可用
  static Future<bool> isPortAvailable(String host, int port) async {
    try {
      final socket = await ServerSocket.bind(host, port);
      await socket.close();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 查找可用端口
  ///
  /// 从 [preferredPort] 开始，依次尝试后续端口，直到找到可用端口
  /// 最多尝试 [maxAttempts] 次
  static Future<int> findAvailablePort(
    String host,
    int preferredPort, {
    int maxAttempts = 100,
  }) async {
    for (int i = 0; i < maxAttempts; i++) {
      final port = preferredPort + i;
      if (port > 65535) {
        throw Exception('No available port found (exceeded max port number)');
      }

      if (await isPortAvailable(host, port)) {
        return port;
      }
    }

    throw Exception(
        'No available port found after $maxAttempts attempts starting from $preferredPort');
  }

  /// 解析地址字符串为 host 和 port
  ///
  /// 支持格式：
  /// - "host:port" (如 "127.0.0.1:5020")
  /// - "port" (如 "5020"，默认 host 为 "127.0.0.1")
  static (String host, int port) parseAddress(String address,
      {String defaultHost = '127.0.0.1'}) {
    if (address.contains(':')) {
      final parts = address.split(':');
      return (parts[0], int.parse(parts[1]));
    } else {
      return (defaultHost, int.parse(address));
    }
  }
}