import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:dart_modbus/modbus.dart';
import 'lib/slave_base.dart';
import 'lib/port_utils.dart';

/// Modbus TCP 从站模拟器
///
/// 模拟 TCP 从设备（服务器端）
/// Usage: dart run packages/modbus_simulator/bin/tcp_slave.dart [host] [port]
///   host: 默认 127.0.0.1
///   port: 默认 5020
void main(List<String> args) async {
  print('=== Modbus TCP Slave Simulator ===\n');

  final host = args.isNotEmpty ? args[0] : '127.0.0.1';
  final preferredPort = args.length > 1 ? int.parse(args[1]) : 5020;

  // 查找可用端口
  print('Checking port availability...');
  int port;
  try {
    if (await PortUtils.isPortAvailable(host, preferredPort)) {
      port = preferredPort;
      print('✓ Port $preferredPort is available\n');
    } else {
      print('⚠ Port $preferredPort is in use, searching for available port...');
      port = await PortUtils.findAvailablePort(host, preferredPort + 1);
      print('✓ Found available port: $port\n');
    }
  } catch (e) {
    print('✗ Error finding available port: $e');
    exit(1);
  }

  // 创建 TCP 从站
  final slave = TCPSlaveImpl(
    slaveId: 1,
    host: host,
    port: port,
  );

  try {
    // 启动从站
    await slave.start();

    // 预加载测试数据
    slave.preloadTestData();

    print('✓ Slave is running on $host:$port');
    print('\nTest data:');
    print('  - Coil 0 = true');
    print('  - Coil 1 = false');
    print('  - Holding Register 100 = 1234');
    print('  - Holding Register 101 = 5678');
    print('  - Input Register 0 = 111');
    print('\nPress Ctrl+C to stop...\n');

    // 保持运行
    await Future.delayed(Duration(hours: 1));
  } catch (e) {
    print('✗ Error: $e');
  } finally {
    await slave.stop();
    print('Simulator stopped');
  }
}

/// TCP 从站实现
class TCPSlaveImpl extends ModbusSlave {
  final String host;
  final int port;
  ServerSocket? _serverSocket;
  final List<Socket> _clients = [];

  TCPSlaveImpl({
    required super.slaveId,
    required this.host,
    required this.port,
    super.storage,
  });

  @override
  Future<void> onStart() async {
    _serverSocket = await ServerSocket.bind(host, port);
    _serverSocket!.listen(_handleClient);
  }

  @override
  Future<void> onStop() async {
    for (final client in _clients) {
      await client.close();
    }
    _clients.clear();
    await _serverSocket?.close();
  }

  void _handleClient(Socket socket) {
    print(
        '✓ Client connected: ${socket.remoteAddress.address}:${socket.remotePort}');
    _clients.add(socket);

    final List<int> buffer = [];

    socket.listen(
      (data) async {
        buffer.addAll(data);
        await _processBuffer(buffer, socket);
      },
      onDone: () {
        print('✓ Client disconnected');
        _clients.remove(socket);
        socket.close();
      },
      onError: (e) {
        print('✗ Client error: $e');
        _clients.remove(socket);
        socket.close();
      },
    );
  }

  Future<void> _processBuffer(List<int> buffer, Socket socket) async {
    // MBAP 头部长度为 7 字节
    while (buffer.length >= 7) {
      final byteData =
          ByteData.sublistView(Uint8List.fromList(buffer.sublist(0, 7)));
      final mbap = ProtocolTCPHeader(
        transactionId: byteData.getUint16(0, Endian.big),
        protocolId: byteData.getUint16(2, Endian.big),
        length: byteData.getUint16(4, Endian.big),
        slaveId: buffer[6],
      );

      // 检查是否接收完整帧
      final frameLength = 7 + mbap.length - 1;
      if (buffer.length < frameLength) {
        break;
      }

      // 提取完整帧
      final frame = Uint8List.fromList(buffer.sublist(0, frameLength));
      buffer.removeRange(0, frameLength);

      // 解析 PDU
      final receivedSlaveId = frame[6];
      final funcCode = frame[7];
      final data = frame.sublist(8);
      final pdu = ProtocolDataUnit(funcCode, data);

      // 处理请求并发送响应
      final response = await storage.handleRequest(receivedSlaveId, pdu);
      if (response != null) {
        final responseFrame = _buildTCPFrame(mbap, receivedSlaveId, response);
        socket.add(responseFrame);
      }
    }
  }

  Uint8List _buildTCPFrame(
      ProtocolTCPHeader requestMbap, int slaveId, ProtocolDataUnit pdu) {
    final pduLength = 1 + 1 + pdu.data.length; // unitId + funcCode + data
    final mbap = ProtocolTCPHeader(
      transactionId: requestMbap.transactionId,
      protocolId: 0,
      length: pduLength,
      slaveId: slaveId,
    );

    final frame = BytesBuilder();
    // 手动构建 MBAP 头
    final headerBytes = Uint8List(7);
    final byteData = ByteData.sublistView(headerBytes);
    byteData.setUint16(0, mbap.transactionId, Endian.big);
    byteData.setUint16(2, mbap.protocolId, Endian.big);
    byteData.setUint16(4, mbap.length, Endian.big);
    headerBytes[6] = mbap.slaveId;

    frame.add(headerBytes);
    frame.addByte(pdu.funcCode);
    frame.add(pdu.data);

    return frame.toBytes();
  }

  @override
  Future<void> sendResponse(int slaveId, ProtocolDataUnit pdu) async {
    // TCP 响应在 _processBuffer 中直接发送
    // 这个方法在 TCP 实现中不需要单独调用
  }
}
