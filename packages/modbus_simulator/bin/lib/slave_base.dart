import 'dart:async';
import 'dart:typed_data';
import 'package:dart_modbus/modbus.dart';
import 'storage.dart';
import 'virtual_serial_port.dart';

/// Modbus 从站基类
///
/// 提供通用的从站功能，子类只需实现协议相关的方法
abstract class ModbusSlave {
  final int slaveId;
  final ModbusStorage storage;
  bool _isRunning = false;

  ModbusSlave({
    required this.slaveId,
    ModbusStorage? storage,
  }) : storage = storage ?? ModbusStorage();

  bool get isRunning => _isRunning;

  /// 启动从站
  Future<void> start() async {
    if (_isRunning) {
      throw StateError('Slave already running');
    }
    _isRunning = true;
    await onStart();
    print('✓ Slave #$slaveId started');
  }

  /// 停止从站
  Future<void> stop() async {
    if (!_isRunning) return;
    _isRunning = false;
    await onStop();
    print('✓ Slave #$slaveId stopped');
  }

  /// 子类实现：启动时的操作
  Future<void> onStart();

  /// 子类实现：停止时的操作
  Future<void> onStop();

  /// 处理请求（通用逻辑）
  Future<void> handleRequest(int receivedSlaveId, ProtocolDataUnit pdu) async {
    // 检查从站地址
    if (receivedSlaveId != slaveId && receivedSlaveId != 0) {
      // 不是发给我的，忽略
      return;
    }

    // 处理请求
    final response = await storage.handleRequest(slaveId, pdu);
    if (response != null) {
      await sendResponse(slaveId, response);
    }
  }

  /// 子类实现：发送响应
  Future<void> sendResponse(int slaveId, ProtocolDataUnit pdu);

  /// 预设一些测试数据
  void preloadTestData() {
    // Coils
    storage.setCoil(0, true);
    storage.setCoil(1, false);
    storage.setCoil(10, true);

    // Discrete Inputs
    storage.setDiscreteInput(0, true);
    storage.setDiscreteInput(1, false);

    // Holding Registers
    storage.setHoldingRegister(100, 1234);
    storage.setHoldingRegister(101, 5678);
    storage.setHoldingRegister(200, 100);
    storage.setHoldingRegister(201, 200);
    storage.setHoldingRegister(202, 300);

    // Input Registers
    storage.setInputRegister(0, 111);
    storage.setInputRegister(1, 222);
    storage.setInputRegister(2, 333);

    print('✓ Test data preloaded');
  }
}

/// RTU 从站实现
class RTUSlave extends ModbusSlave {
  final VirtualSerialPort port;
  StreamSubscription<Uint8List>? _subscription;
  final List<int> _buffer = [];
  Timer? _frameTimer;

  RTUSlave({
    required super.slaveId,
    required this.port,
    super.storage,
  });

  @override
  Future<void> onStart() async {
    await port.open();

    // 监听串口数据
    _subscription = port.stream.listen((data) {
      _buffer.addAll(data);

      // RTU 使用帧间隔（3.5 字符时间）检测帧结束
      _frameTimer?.cancel();
      _frameTimer = Timer(Duration(milliseconds: 10), _processFrame);
    });
  }

  @override
  Future<void> onStop() async {
    _frameTimer?.cancel();
    await _subscription?.cancel();
    await port.close();
  }

  void _processFrame() async {
    if (_buffer.length < 4) {
      _buffer.clear();
      return;
    }

    final frame = Uint8List.fromList(_buffer);
    _buffer.clear();

    // 解析 RTU 帧
    final receivedSlaveId = frame[0];
    final funcCode = frame[1];
    final dataEnd = frame.length - 2;
    final data = frame.sublist(2, dataEnd);
    final receivedCrc = (frame[dataEnd] << 8) | frame[dataEnd + 1];

    // 验证 CRC
    final calculatedCrc = crc16(frame.sublist(0, dataEnd));
    if (receivedCrc != calculatedCrc) {
      print('✗ CRC error: expected $calculatedCrc, got $receivedCrc');
      return;
    }

    // 处理请求
    final pdu = ProtocolDataUnit(funcCode, data);
    await handleRequest(receivedSlaveId, pdu);
  }

  @override
  Future<void> sendResponse(int slaveId, ProtocolDataUnit pdu) async {
    // 构建 RTU 帧
    final frame = <int>[slaveId, pdu.funcCode, ...pdu.data];
    final crc = crc16(frame);
    frame.add(crc & 0xFF);
    frame.add((crc >> 8) & 0xFF);

    await port.write(Uint8List.fromList(frame));
  }
}

/// TCP 从站实现
class TCPSlave extends ModbusSlave {
  // TODO: 实现 TCP 从站
  TCPSlave({
    required super.slaveId,
    super.storage,
  });

  @override
  Future<void> onStart() async {
    // TODO: 启动 TCP 服务器
  }

  @override
  Future<void> onStop() async {
    // TODO: 停止 TCP 服务器
  }

  @override
  Future<void> sendResponse(int slaveId, ProtocolDataUnit pdu) async {
    // TODO: 发送 TCP 响应
  }
}

/// ASCII 从站实现
class ASCIISlave extends ModbusSlave {
  final VirtualSerialPort port;
  StreamSubscription<Uint8List>? _subscription;
  final List<int> _buffer = [];

  ASCIISlave({
    required super.slaveId,
    required this.port,
    super.storage,
  });

  @override
  Future<void> onStart() async {
    await port.open();

    // 监听串口数据
    _subscription = port.stream.listen((data) {
      _buffer.addAll(data);
      _processBuffer();
    });
  }

  @override
  Future<void> onStop() async {
    await _subscription?.cancel();
    await port.close();
  }

  void _processBuffer() async {
    // ASCII 帧以 ':' 开始，以 '\r\n' 结束
    while (_buffer.isNotEmpty) {
      final startIndex = _buffer.indexOf(0x3A); // ':'
      if (startIndex == -1) {
        _buffer.clear();
        return;
      }

      // 移除开始前的无效数据
      if (startIndex > 0) {
        _buffer.removeRange(0, startIndex);
      }

      final endIndex = _findLineEnd();
      if (endIndex == -1) {
        // 帧未完整，等待更多数据
        return;
      }

      // 提取帧
      final frame = Uint8List.fromList(_buffer.sublist(0, endIndex + 2));
      _buffer.removeRange(0, endIndex + 2);

      await _processFrame(frame);
    }
  }

  int _findLineEnd() {
    for (int i = 0; i < _buffer.length - 1; i++) {
      if (_buffer[i] == 0x0D && _buffer[i + 1] == 0x0A) {
        return i;
      }
    }
    return -1;
  }

  Future<void> _processFrame(Uint8List frame) async {
    // 解析 ASCII 帧
    try {
      final ascii = String.fromCharCodes(frame.sublist(1, frame.length - 2));
      final bytes = _asciiToBytes(ascii);

      if (bytes.length < 3) return;

      final receivedSlaveId = bytes[0];
      final funcCode = bytes[1];
      final data = bytes.sublist(2, bytes.length - 1);
      final receivedLrc = bytes[bytes.length - 1];

      // 验证 LRC
      final calculatedLrc =
          LRC().push(bytes.sublist(0, bytes.length - 1)).value;
      if (receivedLrc != calculatedLrc) {
        print('✗ LRC error: expected $calculatedLrc, got $receivedLrc');
        return;
      }

      // 处理请求
      final pdu = ProtocolDataUnit(funcCode, data);
      await handleRequest(receivedSlaveId, pdu);
    } catch (e) {
      print('✗ ASCII frame parse error: $e');
    }
  }

  @override
  Future<void> sendResponse(int slaveId, ProtocolDataUnit pdu) async {
    // 构建 ASCII 帧
    final bytes = <int>[slaveId, pdu.funcCode, ...pdu.data];
    final lrc = LRC().push(bytes).value;
    bytes.add(lrc);

    final ascii = _bytesToAscii(Uint8List.fromList(bytes));
    final frame = ':$ascii\r\n';

    await port.write(Uint8List.fromList(frame.codeUnits));
  }

  String _bytesToAscii(Uint8List bytes) {
    return bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join()
        .toUpperCase();
  }

  Uint8List _asciiToBytes(String ascii) {
    final bytes = <int>[];
    for (int i = 0; i < ascii.length; i += 2) {
      final hex = ascii.substring(i, i + 2);
      bytes.add(int.parse(hex, radix: 16));
    }
    return Uint8List.fromList(bytes);
  }
}
