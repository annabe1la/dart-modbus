import 'dart:async';
import 'package:dart_modbus/modbus.dart';
import 'lib/virtual_serial_port.dart';
import 'lib/slave_base.dart';

/// Modbus ASCII 从站模拟器
///
/// 使用虚拟串口模拟 ASCII 从设备
/// Usage: dart run packages/modbus_simulator/bin/ascii_slave.dart
void main() async {
  print('=== Modbus ASCII Slave Simulator ===\n');

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

  // 创建从站 (使用 port2)
  final slave = ASCIISlave(
    slaveId: 1,
    port: serialPair.port2,
  );

  try {
    // 启动从站
    await slave.start();

    // 预加载测试数据
    slave.preloadTestData();

    print('\nSlave is running...');
    print('Listening on virtual port: ${config.portName}');
    print(
        'Config: ${config.baudRate} baud, ${config.dataBits}${config.parity}${config.stopBits}');
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
    await serialPair.cleanup();
    print('Simulator stopped');
  }
}
