import 'dart:async';
import 'dart:typed_data';
import 'package:dart_modbus/modbus.dart';

/// Modbus TCP 主站模拟器
///
/// 模拟 TCP 主设备（客户端）
/// Usage: dart run packages/modbus_simulator/bin/tcp_master.dart [host] [port]
void main(List<String> args) async {
  print('=== Modbus TCP Master Simulator ===\n');

  final host = args.isNotEmpty ? args[0] : '127.0.0.1';
  final port = args.length > 1 ? int.parse(args[1]) : 502;

  // 创建 TCP 客户端
  final provider = TCPClientProvider('$host:$port');
  final client = ModbusClientImpl(provider);

  try {
    print('Connecting to $host:$port...');
    await client.connect();
    print('✓ TCP Master connected\n');

    print('--- Testing TCP Communication ---\n');

    // 1. 写入单个寄存器
    print('1. Writing single register...');
    await client.writeSingleRegister(1, 100, 1234);
    print('   ✓ Written: Register 100 = 1234\n');

    await Future.delayed(Duration(milliseconds: 50));

    // 2. 读取寄存器
    print('2. Reading holding register...');
    final result1 = await client.readHoldingRegisters(1, 100, 1);
    print('   ✓ Read: Register 100 = ${result1[0]}\n');

    // 3. 写入多个寄存器
    print('3. Writing multiple registers...');
    final values = Uint16List.fromList([100, 200, 300, 400, 500]);
    await client.writeMultipleRegisters(1, 200, 5, values);
    print('   ✓ Written: Registers 200-204 = $values\n');

    await Future.delayed(Duration(milliseconds: 50));

    // 4. 读取多个寄存器
    print('4. Reading multiple registers...');
    final result2 = await client.readHoldingRegisters(1, 200, 5);
    print('   ✓ Read: Registers 200-204 = $result2\n');

    // 5. 写入 Coils
    print('5. Writing multiple coils...');
    final coilValues = [true, false, true, true, false];
    final coilBytes =
        Uint8List.fromList(coilValues.map((b) => b ? 1 : 0).toList());
    await client.writeMultipleCoils(1, 10, 5, coilBytes);
    print('   ✓ Written: Coils 10-14 = $coilValues\n');

    await Future.delayed(Duration(milliseconds: 50));

    // 6. 读取 Coils
    print('6. Reading coils...');
    final coils = await client.readCoils(1, 10, 5);
    final coilBools = coils.map((c) => c == 1).toList();
    print('   ✓ Read: Coils 10-14 = $coilBools\n');

    // 7. Float32 数据
    print('7. Writing Float32 data...');
    final temp = 25.5;
    final humidity = 65.8;
    final tempBytes = DataConverter.float32ToBytes(temp);
    final humidityBytes = DataConverter.float32ToBytes(humidity);
    final combinedBytes = Uint8List.fromList([...tempBytes, ...humidityBytes]);
    await client.writeMultipleRegistersBytes(1, 300, 4, combinedBytes);
    print('   ✓ Written: Temp = $temp°C, Humidity = $humidity%\n');

    await Future.delayed(Duration(milliseconds: 50));

    print('8. Reading Float32 data...');
    final readBytes = await client.readHoldingRegistersBytes(1, 300, 4);
    final readTemp = DataConverter.bytesToFloat32(readBytes.sublist(0, 4));
    final readHumidity = DataConverter.bytesToFloat32(readBytes.sublist(4, 8));
    print('   ✓ Read: Temp = ${readTemp.toStringAsFixed(1)}°C, '
        'Humidity = ${readHumidity.toStringAsFixed(1)}%\n');

    // 9. 读取输入寄存器
    print('9. Reading input registers...');
    final inputs = await client.readInputRegisters(1, 0, 3);
    print('   ✓ Read: Input Registers 0-2 = $inputs\n');

    // 10. 字符串数据
    print('10. Writing string data...');
    final str = 'MODBUS TCP';
    final strBytes = DataConverter.stringToBytes(str, length: 20);
    await client.writeMultipleRegistersBytes(1, 400, 10, strBytes);
    print('   ✓ Written: String = "$str"\n');

    await Future.delayed(Duration(milliseconds: 50));

    print('11. Reading string data...');
    final readStrBytes = await client.readHoldingRegistersBytes(1, 400, 10);
    final readStr = DataConverter.bytesToString(readStrBytes).trim();
    print('   ✓ Read: String = "$readStr"\n');

    print('--- TCP Communication Test Completed ---\n');
    print('Note: TCP uses MBAP header and does not need CRC.');
  } catch (e) {
    print('✗ Error: $e');
  } finally {
    await client.close();
    print('Simulator stopped');
  }
}
