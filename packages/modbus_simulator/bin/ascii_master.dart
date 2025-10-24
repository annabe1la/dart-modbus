import 'dart:async';
import 'dart:typed_data';
import 'package:dart_modbus/modbus.dart';
import 'lib/virtual_serial_port.dart';

/// Modbus ASCII 主站模拟器
///
/// 使用虚拟串口模拟 ASCII 主设备
/// Usage: dart run packages/modbus_simulator/bin/ascii_master.dart
void main() async {
  print('=== Modbus ASCII Master Simulator ===\n');

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

  // 创建主站 (使用 port1)
  final masterPort = serialPair.port1;
  final masterProvider = ASCIIClientProvider(masterPort);
  final client = ModbusClientImpl(masterProvider);

  try {
    await client.connect();
    print('✓ ASCII Master connected\n');
    print(
        'Config: ${config.baudRate} baud, ${config.dataBits}${config.parity}${config.stopBits}\n');

    print('--- Testing ASCII Communication ---\n');

    // 1. 写入单个寄存器
    print('1. Writing single register...');
    await client.writeSingleRegister(1, 100, 5678);
    print('   ✓ Written: Register 100 = 5678\n');

    await Future.delayed(Duration(milliseconds: 100));

    // 2. 读取寄存器
    print('2. Reading holding register...');
    final result1 = await client.readHoldingRegisters(1, 100, 1);
    print('   ✓ Read: Register 100 = ${result1[0]}\n');

    // 3. 写入多个寄存器
    print('3. Writing multiple registers...');
    final values = Uint16List.fromList([111, 222, 333]);
    await client.writeMultipleRegisters(1, 200, 3, values);
    print('   ✓ Written: Registers 200-202 = $values\n');

    await Future.delayed(Duration(milliseconds: 100));

    // 4. 读取多个寄存器
    print('4. Reading multiple registers...');
    final result2 = await client.readHoldingRegisters(1, 200, 3);
    print('   ✓ Read: Registers 200-202 = $result2\n');

    // 5. 写入 Coil
    print('5. Writing single coil...');
    await client.writeSingleCoil(1, 0, true);
    print('   ✓ Written: Coil 0 = true\n');

    await Future.delayed(Duration(milliseconds: 100));

    // 6. 读取 Coil
    print('6. Reading coil...');
    final coils = await client.readCoils(1, 0, 1);
    print('   ✓ Read: Coil 0 = ${coils[0] == 1}\n');

    // 7. 字符串数据（ASCII 特别适合）
    print('7. Writing string data...');
    final str = 'HELLO ASCII';
    final strBytes = DataConverter.stringToBytes(str, length: 20);
    await client.writeMultipleRegistersBytes(1, 300, 10, strBytes);
    print('   ✓ Written: String = "$str"\n');

    await Future.delayed(Duration(milliseconds: 100));

    print('8. Reading string data...');
    final readStrBytes = await client.readHoldingRegistersBytes(1, 300, 10);
    final readStr = DataConverter.bytesToString(readStrBytes).trim();
    print('   ✓ Read: String = "$readStr"\n');

    // 9. 读取输入寄存器
    print('9. Reading input registers...');
    final inputs = await client.readInputRegisters(1, 0, 3);
    print('   ✓ Read: Input Registers 0-2 = $inputs\n');

    // 10. Float32 数据
    print('10. Writing Float32 data...');
    final voltage = 220.5;
    final voltageBytes = DataConverter.float32ToBytes(voltage);
    await client.writeMultipleRegistersBytes(1, 400, 2, voltageBytes);
    print('   ✓ Written: Voltage = ${voltage}V\n');

    await Future.delayed(Duration(milliseconds: 100));

    print('11. Reading Float32 data...');
    final readBytes = await client.readHoldingRegistersBytes(1, 400, 2);
    final readVoltage = DataConverter.bytesToFloat32(readBytes);
    print('   ✓ Read: Voltage = ${readVoltage.toStringAsFixed(1)}V\n');

    print('--- ASCII Communication Test Completed ---\n');
    print('Note: ASCII protocol is human-readable and slower than RTU,');
    print('      but easier to debug with serial monitors.');
  } catch (e) {
    print('✗ Error: $e');
  } finally {
    await client.close();
    await serialPair.cleanup();
    print('Simulator stopped');
  }
}
