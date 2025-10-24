import 'dart:async';
import 'dart:typed_data';
import 'package:dart_modbus/modbus.dart';

/// 虚拟串口对，使用内存流模拟串口通信
/// 用于测试 RTU 和 ASCII 模拟器
class VirtualSerialPair {
  final String name;
  late final VirtualSerialPort _port1;
  late final VirtualSerialPort _port2;

  VirtualSerialPair(this.name, SerialConfig config) {
    // 创建两个互相连接的虚拟串口
    final controller1 = StreamController<Uint8List>.broadcast();
    final controller2 = StreamController<Uint8List>.broadcast();

    _port1 = VirtualSerialPort('$name-1', config, controller1, controller2);
    _port2 = VirtualSerialPort('$name-2', config, controller2, controller1);
  }

  /// 获取第一个端口（通常用于 master）
  VirtualSerialPort get port1 => _port1;

  /// 获取第二个端口（通常用于 slave）
  VirtualSerialPort get port2 => _port2;

  /// 清理资源
  Future<void> cleanup() async {
    await _port1.close();
    await _port2.close();
  }
}

/// 虚拟串口实现
class VirtualSerialPort implements SerialPort {
  final String _portName;
  final SerialConfig _config;
  final StreamController<Uint8List> _readController;
  final StreamController<Uint8List> _writeController;
  bool _isOpen = false;
  final List<int> _buffer = [];
  StreamSubscription<Uint8List>? _subscription;

  VirtualSerialPort(
    this._portName,
    this._config,
    this._readController,
    this._writeController,
  );

  @override
  Future<void> open() async {
    if (_isOpen) {
      throw StateError('Serial port already opened');
    }
    _isOpen = true;

    // 监听数据并缓存
    _subscription = _readController.stream.listen((data) {
      _buffer.addAll(data);
    });

    print('Virtual serial port opened: $_portName');
  }

  @override
  Future<void> write(Uint8List data) async {
    if (!_isOpen) {
      throw StateError('Serial port not opened');
    }

    // 写入数据到配对端口的读取流
    _writeController.add(data);
  }

  @override
  bool get isOpen => _isOpen;

  @override
  Future<Uint8List> read(int length) async {
    if (!_isOpen) {
      throw StateError('Serial port not opened');
    }

    // 等待缓冲区有足够数据
    final timeout = _config.timeout;
    final startTime = DateTime.now();

    while (_buffer.length < length) {
      if (DateTime.now().difference(startTime) > timeout) {
        throw TimeoutException('Read timeout', timeout);
      }
      await Future.delayed(Duration(milliseconds: 10));
    }

    final data = Uint8List.fromList(_buffer.sublist(0, length));
    _buffer.removeRange(0, length);
    return data;
  }

  @override
  Future<Uint8List> readUntil(List<int> pattern, {int? maxLength}) async {
    if (!_isOpen) {
      throw StateError('Serial port not opened');
    }

    final timeout = _config.timeout;
    final startTime = DateTime.now();

    while (true) {
      if (DateTime.now().difference(startTime) > timeout) {
        throw TimeoutException('Read timeout', timeout);
      }

      // 查找模式
      final index = _findPattern(_buffer, pattern);
      if (index != -1) {
        final endIndex = index + pattern.length;
        final data = Uint8List.fromList(_buffer.sublist(0, endIndex));
        _buffer.removeRange(0, endIndex);
        return data;
      }

      // 检查最大长度
      if (maxLength != null && _buffer.length >= maxLength) {
        throw Exception('Max length exceeded without finding pattern');
      }

      await Future.delayed(Duration(milliseconds: 10));
    }
  }

  int _findPattern(List<int> buffer, List<int> pattern) {
    for (int i = 0; i <= buffer.length - pattern.length; i++) {
      bool found = true;
      for (int j = 0; j < pattern.length; j++) {
        if (buffer[i + j] != pattern[j]) {
          found = false;
          break;
        }
      }
      if (found) return i;
    }
    return -1;
  }

  /// 获取数据流（用于从站实现）
  Stream<Uint8List> get stream {
    if (!_isOpen) {
      throw StateError('Serial port not opened');
    }
    return _readController.stream;
  }

  @override
  Future<void> close() async {
    if (!_isOpen) return;
    _isOpen = false;
    await _subscription?.cancel();
    _buffer.clear();
    print('Virtual serial port closed: $_portName');
  }
}
