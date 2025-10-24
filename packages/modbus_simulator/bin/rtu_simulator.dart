import 'dart:async';
import 'dart:typed_data';
import 'package:dart_modbus/modbus.dart';
import 'lib/virtual_serial_port.dart';

/// Modbus RTU 模拟器（Slave + Master）
///
/// 使用虚拟串口对模拟 RTU 通信
/// Usage: dart run packages/modbus_simulator/bin/rtu_simulator.dart
void main() async {
  print('=== Modbus RTU Simulator ===\n');

  // 创建串口配置
  final config = SerialConfig(
    portName: '/dev/ttyVirtual0', // 虚拟串口名称
    baudRate: 115200,
    dataBits: 8,
    stopBits: 1,
    parity: 'N',
  );

  // 创建虚拟串口对
  final serialPair = VirtualSerialPair('modbus-rtu', config);

  // 创建简单的存储
  final storage = SimpleStorage();

  // 启动 Slave
  print('Starting RTU Slave...');
  final slavePort = serialPair.port2;
  final slaveProvider = RTUClientProvider(slavePort, config);

  // 注意：RTU 没有专门的 Server 类，我们使用客户端模式模拟
  // 在实际应用中，slave 会监听串口并响应请求

  // 启动 Master
  print('Starting RTU Master...');
  final masterPort = serialPair.port1;
  final masterProvider = RTUClientProvider(masterPort, config);
  final client = ModbusClientImpl(masterProvider);

  try {
    await client.connect();
    print('✓ RTU Master connected\n');

    // 模拟 Slave 响应
    _setupSlaveResponder(slaveProvider, storage);

    // Master 开始通信
    print('--- Testing RTU Communication ---\n');

    // 1. 写入单个寄存器
    print('1. Writing single register...');
    await client.writeSingleRegister(1, 100, 1234);
    print('✓ Written: Register 100 = 1234\n');

    await Future.delayed(Duration(milliseconds: 100));

    // 2. 读取寄存器
    print('2. Reading holding registers...');
    final result = await client.readHoldingRegisters(1, 100, 1);
    print('✓ Read: Register 100 = ${result[0]}\n');

    // 3. 写入多个寄存器
    print('3. Writing multiple registers...');
    final values = Uint16List.fromList([100, 200, 300]);
    await client.writeMultipleRegisters(1, 200, 3, values);
    print('✓ Written: Registers 200-202 = $values\n');

    await Future.delayed(Duration(milliseconds: 100));

    // 4. 读取多个寄存器
    print('4. Reading multiple registers...');
    final result2 = await client.readHoldingRegisters(1, 200, 3);
    print('✓ Read: Registers 200-202 = $result2\n');

    // 5. Float32 数据
    print('5. Writing Float32 data...');
    final temp = 25.5;
    final tempBytes = DataConverter.float32ToBytes(temp);
    await client.writeMultipleRegistersBytes(1, 300, 2, tempBytes);
    print('✓ Written: Float32 = $temp\n');

    await Future.delayed(Duration(milliseconds: 100));

    print('6. Reading Float32 data...');
    final readBytes = await client.readHoldingRegistersBytes(1, 300, 2);
    final readTemp = DataConverter.bytesToFloat32(readBytes);
    print('✓ Read: Float32 = $readTemp\n');

    print('--- RTU Communication Test Completed ---\n');
  } catch (e) {
    print('✗ Error: $e');
  } finally {
    await client.close();
    await serialPair.cleanup();
    print('Simulator stopped');
  }
}

/// 设置 Slave 响应器（简化版本）
void _setupSlaveResponder(
    RTUClientProvider slaveProvider, SimpleStorage storage) {
  // 在实际应用中，这里应该监听串口并响应请求
  // 由于 RTU 是点对点通信，这里只是示意性的代码
  print('✓ RTU Slave ready to respond\n');
}

/// 简单的存储实现
class SimpleStorage {
  final Map<int, bool> coils = {};
  final Map<int, int> holdingRegisters = {};

  Future<ProtocolDataUnit?> handleRequest(
      int slaveId, ProtocolDataUnit request) async {
    switch (request.funcCode) {
      case funcCodeReadHoldingRegisters:
        return _readHoldingRegisters(request);
      case funcCodeWriteSingleRegister:
        return _writeSingleRegister(request);
      case funcCodeWriteMultipleRegisters:
        return _writeMultipleRegisters(request);
      default:
        return ProtocolDataUnit(
            0x80 | request.funcCode, [exceptionCodeIllegalFunction]);
    }
  }

  ProtocolDataUnit _readHoldingRegisters(ProtocolDataUnit request) {
    final data = ByteData.sublistView(Uint8List.fromList(request.data));
    final address = data.getUint16(0, Endian.big);
    final quantity = data.getUint16(2, Endian.big);

    final byteCount = quantity * 2;
    final result = Uint8List(byteCount + 1);
    result[0] = byteCount;

    for (int i = 0; i < quantity; i++) {
      final value = holdingRegisters[address + i] ?? 0;
      final offset = 1 + i * 2;
      result[offset] = (value >> 8) & 0xFF;
      result[offset + 1] = value & 0xFF;
    }

    return ProtocolDataUnit(funcCodeReadHoldingRegisters, result);
  }

  ProtocolDataUnit _writeSingleRegister(ProtocolDataUnit request) {
    final data = ByteData.sublistView(Uint8List.fromList(request.data));
    final address = data.getUint16(0, Endian.big);
    final value = data.getUint16(2, Endian.big);

    holdingRegisters[address] = value;

    return ProtocolDataUnit(funcCodeWriteSingleRegister, request.data);
  }

  ProtocolDataUnit _writeMultipleRegisters(ProtocolDataUnit request) {
    final data = ByteData.sublistView(Uint8List.fromList(request.data));
    final address = data.getUint16(0, Endian.big);
    final quantity = data.getUint16(2, Endian.big);
    final values = request.data.sublist(5);

    for (int i = 0; i < quantity; i++) {
      final offset = i * 2;
      final value = (values[offset] << 8) | values[offset + 1];
      holdingRegisters[address + i] = value;
    }

    return ProtocolDataUnit(
        funcCodeWriteMultipleRegisters, request.data.sublist(0, 4));
  }
}
