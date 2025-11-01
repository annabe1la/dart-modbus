import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:dart_modbus/modbus.dart';
import '../bin/lib/storage.dart';

/// 测试专用的TCP客户端，支持持续连接
class TestTCPClient {
  final String host;
  final int port;
  Socket? _socket;
  int _transactionId = 0;
  StreamSubscription? _subscription;
  final _buffer = <int>[];
  final _responseCompleters = <int, Completer<Uint8List>>{};
  Future<void> _writeLock = Future.value(); // 写入互斥锁

  TestTCPClient(this.host, this.port);

  Future<void> connect() async {
    if (_socket != null) return;
    _socket = await Socket.connect(host, port);

    // 启动持续监听
    _subscription = _socket!.listen(
      (data) {
        _buffer.addAll(data);
        _processBuffer();
      },
      onError: (error) {
        for (var completer in _responseCompleters.values) {
          if (!completer.isCompleted) {
            completer.completeError(error);
          }
        }
        _responseCompleters.clear();
      },
      onDone: () {
        for (var completer in _responseCompleters.values) {
          if (!completer.isCompleted) {
            completer.completeError(Exception('Connection closed'));
          }
        }
        _responseCompleters.clear();
      },
    );
  }

  void _processBuffer() {
    while (_buffer.length >= 7) {
      // MBAP header 是 7 字节
      final transactionId = (_buffer[0] << 8) | _buffer[1];
      final length = (_buffer[4] << 8) | _buffer[5];
      final totalLength = 7 + length - 1;

      if (_buffer.length >= totalLength) {
        final response = Uint8List.fromList(_buffer.sublist(0, totalLength));
        _buffer.removeRange(0, totalLength);

        final completer = _responseCompleters.remove(transactionId);
        if (completer != null && !completer.isCompleted) {
          completer.complete(response);
        }
      } else {
        break;
      }
    }
  }

  Future<Uint8List> sendRequest(int slaveId, int funcCode, Uint8List data) async {
    if (_socket == null) {
      await connect();
    }

    // 等待前一个写入操作完成
    final previousLock = _writeLock;
    final currentLock = Completer<void>();
    _writeLock = currentLock.future;

    await previousLock;

    try {
      _transactionId = (_transactionId + 1) & 0xFFFF;
      final completer = Completer<Uint8List>();
      _responseCompleters[_transactionId] = completer;

      // 构建MBAP请求
      final pduLength = data.length + 1; // funcCode + data
      final mbapLength = pduLength + 1; // + slaveId
      final request = Uint8List(7 + pduLength);

      request[0] = (_transactionId >> 8) & 0xFF;
      request[1] = _transactionId & 0xFF;
      request[2] = 0; // Protocol ID
      request[3] = 0;
      request[4] = (mbapLength >> 8) & 0xFF;
      request[5] = mbapLength & 0xFF;
      request[6] = slaveId;
      request[7] = funcCode;
      request.setRange(8, request.length, data);

      _socket!.add(request);

      // 写入完成，释放锁
      currentLock.complete();

      return await completer.future.timeout(
        Duration(seconds: 5),
        onTimeout: () {
          _responseCompleters.remove(_transactionId);
          throw TimeoutException('Request timeout');
        },
      );
    } catch (e) {
      if (!currentLock.isCompleted) {
        currentLock.complete();
      }
      rethrow;
    }
  }

  Future<void> close() async {
    await _subscription?.cancel();
    await _socket?.close();
    _socket = null;
    _buffer.clear();
    _responseCompleters.clear();
  }
}

void main() {
  group('TCP Master-Slave Communication Tests', () {
    late ServerSocket serverSocket;
    late ModbusStorage storage;
    late String serverHost;
    late int serverPort;
    late TestTCPClient client;

    setUpAll(() async {
      // 创建存储
      storage = ModbusStorage();

      // 初始化测试数据
      storage.setHoldingRegisters(0, [100, 200, 300, 400, 500]);
      storage.setInputRegisters(0, [1000, 2000, 3000]);
      storage.setCoils(0, [true, false, true, false, true]);
      storage.setDiscreteInput(0, true);
      storage.setDiscreteInput(1, false);

      // 启动 TCP 服务器
      serverSocket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      serverPort = serverSocket.port;
      serverHost = '127.0.0.1';

      // 处理客户端连接（支持粘包处理）
      serverSocket.listen((socket) async {
        try {
          final buffer = <int>[];

          await for (final data in socket) {
            buffer.addAll(data);

            // 处理缓冲区中的所有完整帧
            while (buffer.length >= 8) {
              // 读取MBAP length字段
              final mbapLength = (buffer[4] << 8) | buffer[5];
              final totalLength = 6 + mbapLength; // MBAP header前6字节 + length字段值

              if (buffer.length < totalLength) {
                // 数据不完整，等待更多数据
                break;
              }

              // 提取完整的请求帧
              final frame = buffer.sublist(0, totalLength);
              buffer.removeRange(0, totalLength);

              final transactionId = (frame[0] << 8) | frame[1];
              final protocolId = (frame[2] << 8) | frame[3];
              final slaveId = frame[6];
              final pduData = frame.sublist(7);
              final funcCode = pduData[0];
              final pdu = ProtocolDataUnit(funcCode, pduData.sublist(1));

              // 处理请求
              final response = await storage.handleRequest(slaveId, pdu);
              if (response == null) continue;

              // 构建响应
              final responseBytes = Uint8List(7 + response.data.length + 1);
              responseBytes[0] = transactionId >> 8;
              responseBytes[1] = transactionId & 0xFF;
              responseBytes[2] = protocolId >> 8;
              responseBytes[3] = protocolId & 0xFF;
              final respLength = response.data.length + 2;
              responseBytes[4] = respLength >> 8;
              responseBytes[5] = respLength & 0xFF;
              responseBytes[6] = slaveId;
              responseBytes[7] = response.funcCode;
              responseBytes.setRange(8, responseBytes.length, response.data);

              socket.add(responseBytes);
            }
          }
        } catch (e) {
          // Connection closed
        }
      });
    });

    setUp(() async {
      // 为每个测试创建新的客户端
      client = TestTCPClient(serverHost, serverPort);
      await client.connect();
    });

    tearDown(() async {
      await client.close();
    });

    tearDownAll(() async {
      await serverSocket.close();
      storage.clear();
    });

    test('Read Holding Registers', () async {
      final request = Uint8List(4);
      request[0] = 0; // address high
      request[1] = 0; // address low
      request[2] = 0; // quantity high
      request[3] = 5; // quantity low

      final response = await client.sendRequest(1, funcCodeReadHoldingRegisters, request);

      // 解析响应
      final byteCount = response[8];
      final values = <int>[];
      for (int i = 0; i < byteCount ~/ 2; i++) {
        final value = (response[9 + i * 2] << 8) | response[10 + i * 2];
        values.add(value);
      }

      expect(values, [100, 200, 300, 400, 500]);
    });

    test('Read Input Registers', () async {
      final request = Uint8List(4);
      request[0] = 0;
      request[1] = 0;
      request[2] = 0;
      request[3] = 3;

      final response = await client.sendRequest(1, funcCodeReadInputRegisters, request);

      final byteCount = response[8];
      final values = <int>[];
      for (int i = 0; i < byteCount ~/ 2; i++) {
        final value = (response[9 + i * 2] << 8) | response[10 + i * 2];
        values.add(value);
      }

      expect(values, [1000, 2000, 3000]);
    });

    test('Write Single Register', () async {
      final request = Uint8List(4);
      request[0] = 0;
      request[1] = 10; // address = 10
      request[2] = 0x30; // value high = 0x30
      request[3] = 0x39; // value low = 0x39 (12345)

      await client.sendRequest(1, funcCodeWriteSingleRegister, request);

      // 验证写入
      final readRequest = Uint8List(4);
      readRequest[0] = 0;
      readRequest[1] = 10;
      readRequest[2] = 0;
      readRequest[3] = 1;

      final response = await client.sendRequest(1, funcCodeReadHoldingRegisters, readRequest);
      final value = (response[9] << 8) | response[10];
      expect(value, 12345);
    });

    test('Write Multiple Registers', () async {
      final registers = [111, 222, 333, 444, 555];
      final request = Uint8List(5 + registers.length * 2);
      request[0] = 0;
      request[1] = 20; // address
      request[2] = 0;
      request[3] = registers.length; // quantity
      request[4] = registers.length * 2; // byte count

      for (int i = 0; i < registers.length; i++) {
        request[5 + i * 2] = (registers[i] >> 8) & 0xFF;
        request[6 + i * 2] = registers[i] & 0xFF;
      }

      await client.sendRequest(1, funcCodeWriteMultipleRegisters, request);

      // 验证写入
      final readRequest = Uint8List(4);
      readRequest[0] = 0;
      readRequest[1] = 20;
      readRequest[2] = 0;
      readRequest[3] = registers.length;

      final response = await client.sendRequest(1, funcCodeReadHoldingRegisters, readRequest);

      final values = <int>[];
      for (int i = 0; i < registers.length; i++) {
        final value = (response[9 + i * 2] << 8) | response[10 + i * 2];
        values.add(value);
      }

      expect(values, registers);
    });

    test('Concurrent Requests', () async {
      // 同一个连接发送多个并发请求（通过写入锁序列化）
      final futures = <Future>[];

      for (int i = 0; i < 3; i++) {
        final request = Uint8List(4);
        request[0] = 0;
        request[1] = 0;
        request[2] = 0;
        request[3] = 5;

        futures.add(() async {
          final response = await client.sendRequest(1, funcCodeReadHoldingRegisters, request);
          final byteCount = response[8];
          final values = <int>[];
          for (int j = 0; j < byteCount ~/ 2; j++) {
            final value = (response[9 + j * 2] << 8) | response[10 + j * 2];
            values.add(value);
          }
          return values;
        }());
      }

      final results = await Future.wait(futures);

      // 所有请求都应该返回相同的结果
      for (final result in results) {
        expect(result, [100, 200, 300, 400, 500]);
      }
    });

    test('Connection Status', () {
      expect(client._socket != null, true);
    });

    test('Sequential Requests', () async {
      // 测试连续多次请求
      for (int i = 0; i < 10; i++) {
        final request = Uint8List(4);
        request[0] = 0;
        request[1] = 0;
        request[2] = 0;
        request[3] = 5;

        final response = await client.sendRequest(1, funcCodeReadHoldingRegisters, request);

        final byteCount = response[8];
        final values = <int>[];
        for (int j = 0; j < byteCount ~/ 2; j++) {
          final value = (response[9 + j * 2] << 8) | response[10 + j * 2];
          values.add(value);
        }

        expect(values, [100, 200, 300, 400, 500]);
      }
    });
  });
}