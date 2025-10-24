import 'dart:async';
import 'package:dart_modbus/modbus.dart';
import 'lib/virtual_serial_port.dart';

/// Modbus ASCII 模拟器
///
/// 使用虚拟串口对模拟 ASCII 通信
/// Usage: dart run packages/modbus_simulator/bin/ascii_simulator.dart
void main() async {
  print('=== Modbus ASCII Simulator ===\n');

  // 创建串口配置
  final config = SerialConfig(
    portName: '/dev/ttyVirtual1',
    baudRate: 9600, // ASCII 通常使用较低的波特率
    dataBits: 7, // ASCII 使用 7 数据位
    stopBits: 1,
    parity: 'E', // ASCII 通常使用偶校验
  );

  // 创建虚拟串口对
  final serialPair = VirtualSerialPair('modbus-ascii', config);

  print('Starting ASCII Master...');
  final masterPort = serialPair.port1;
  final masterProvider = ASCIIClientProvider(masterPort);
  final client = ModbusClientImpl(masterProvider);

  try {
    await client.connect();
    print('✓ ASCII Master connected\n');

    print('--- Testing ASCII Communication ---\n');

    // 1. 写入单个寄存器
    print('1. Writing single register...');
    await client.writeSingleRegister(1, 100, 5678);
    print('✓ Written: Register 100 = 5678\n');

    await Future.delayed(Duration(milliseconds: 100));

    // 2. 读取寄存器
    print('2. Reading holding registers...');
    final result = await client.readHoldingRegisters(1, 100, 1);
    print('✓ Read: Register 100 = ${result[0]}\n');

    // 3. 写入 Coil
    print('3. Writing single coil...');
    await client.writeSingleCoil(1, 0, true);
    print('✓ Written: Coil 0 = true\n');

    await Future.delayed(Duration(milliseconds: 100));

    // 4. 读取 Coil
    print('4. Reading coils...');
    final coils = await client.readCoils(1, 0, 1);
    print('✓ Read: Coil 0 = ${coils[0] == 1}\n');

    // 5. 字符串数据（ASCII 特别适合）
    print('5. Writing string data...');
    final str = 'HELLO';
    final strBytes = DataConverter.stringToBytes(str, length: 10);
    await client.writeMultipleRegistersBytes(1, 200, 5, strBytes);
    print('✓ Written: String = "$str"\n');

    await Future.delayed(Duration(milliseconds: 100));

    print('6. Reading string data...');
    final readBytes = await client.readHoldingRegistersBytes(1, 200, 5);
    final readStr = DataConverter.bytesToString(readBytes).trim();
    print('✓ Read: String = "$readStr"\n');

    print('--- ASCII Communication Test Completed ---\n');
    print('Note: ASCII protocol is human-readable and slower than RTU');
    print('      but easier to debug with serial monitors.\n');
  } catch (e) {
    print('✗ Error: $e');
  } finally {
    await client.close();
    await serialPair.cleanup();
    print('Simulator stopped');
  }
}
