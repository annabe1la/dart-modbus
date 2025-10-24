import 'dart:async';
import 'dart:typed_data';
import 'package:dart_modbus/modbus.dart';
import 'lib/virtual_serial_port.dart';

/// Modbus RTU 主站模拟器
///
/// 使用虚拟串口模拟 RTU 主设备
/// Usage: dart run packages/modbus_simulator/bin/rtu_master.dart
void main() async {
  print('=== Modbus RTU Master Simulator ===\n');

  // 创建串口配置
  final config = SerialConfig(
    portName: '/dev/ttyVirtual0',
    baudRate: 115200,
    dataBits: 8,
    stopBits: 1,
    parity: 'N',
  );

  // 创建虚拟串口对
  final serialPair = VirtualSerialPair('modbus-rtu', config);

  // 创建主站 (使用 port1)
  final masterPort = serialPair.port1;
  final masterProvider = RTUClientProvider(masterPort, config);
  final client = ModbusClientImpl(masterProvider);

  try {
    await client.connect();
    print('✓ RTU Master connected\n');
    print(
        'Config: ${config.baudRate} baud, ${config.dataBits}${config.parity}${config.stopBits}\n');

    print('--- Testing RTU Communication ---\n');

    // 1. 写入单个寄存器
    print('1. Writing single register...');
    await client.writeSingleRegister(1, 100, 1234);
    print('   ✓ Written: Register 100 = 1234\n');

    await Future.delayed(Duration(milliseconds: 100));

    // 2. 读取寄存器
    print('2. Reading holding register...');
    final result1 = await client.readHoldingRegisters(1, 100, 1);
    print('   ✓ Read: Register 100 = ${result1[0]}\n');

    // 3. 写入多个寄存器
    print('3. Writing multiple registers...');
    final values = Uint16List.fromList([100, 200, 300]);
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

    // 7. Float32 数据
    print('7. Writing Float32 data...');
    final temp = 25.5;
    final tempBytes = DataConverter.float32ToBytes(temp);
    await client.writeMultipleRegistersBytes(1, 300, 2, tempBytes);
    print('   ✓ Written: Float32 = $temp°C\n');

    await Future.delayed(Duration(milliseconds: 100));

    print('8. Reading Float32 data...');
    final readBytes = await client.readHoldingRegistersBytes(1, 300, 2);
    final readTemp = DataConverter.bytesToFloat32(readBytes);
    print('   ✓ Read: Float32 = ${readTemp.toStringAsFixed(1)}°C\n');

    // 9. 读取输入寄存器
    print('9. Reading input registers...');
    final inputs = await client.readInputRegisters(1, 0, 3);
    print('   ✓ Read: Input Registers 0-2 = $inputs\n');

    print('--- RTU Communication Test Completed ---\n');
    print('Note: RTU uses CRC16 for error checking and binary encoding.');
  } catch (e) {
    print('✗ Error: $e');
  } finally {
    await client.close();
    await serialPair.cleanup();
    print('Simulator stopped');
  }
}
