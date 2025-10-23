import 'dart:async';
import '../lib/modbus.dart';

/// Modbus master simulator that polls registers based on point table
///
/// Usage: dart run simulator/master_simulator.dart [config.yaml]
void main(List<String> args) async {
  final configPath = args.isNotEmpty ? args[0] : 'simulator/device_config.yaml';

  print('Loading configuration from: $configPath');
  final config = await PointTableConfig.fromFile(configPath);

  print('Starting Modbus ${config.protocol.toUpperCase()} Master Simulator');
  print('Device: ${config.name}');
  print('Slave ID: ${config.slaveId}');
  print('Poll Interval: ${config.pollInterval ?? 1000}ms');

  if (config.protocol == 'tcp') {
    await _runTCPMaster(config);
  } else {
    print('Serial protocols (RTU/ASCII) not yet implemented in simulator');
    print('Please use TCP protocol in configuration');
  }
}

/// Run TCP master simulator
Future<void> _runTCPMaster(PointTableConfig config) async {
  if (config.address == null) {
    print('Error: TCP address not specified in configuration');
    return;
  }

  // Create TCP client
  final provider = TCPClientProvider(config.address!);
  final client = ModbusClientImpl(provider);

  try {
    print('Connecting to slave at ${config.address}...');
    await client.connect();
    print('Connected successfully!\n');

    // Convert to RegisterMap for easier access
    final registerMap = config.toRegisterMap();

    final pollInterval = Duration(milliseconds: config.pollInterval ?? 1000);
    var iteration = 0;

    // Start polling loop
    Timer.periodic(pollInterval, (timer) async {
      iteration++;
      print('=== Poll #$iteration ===');

      try {
        final values = await registerMap.readAll(client);

        for (final entry in values.entries) {
          final reg = registerMap.registers.firstWhere((r) => r.name == entry.key);
          final value = entry.value;
          final unit = reg.unit != null ? ' ${reg.unit}' : '';

          print('  ${reg.name}: $value$unit (${reg.type.name} @ ${reg.address})');
        }

        print('');
      } catch (e) {
        print('Error reading registers: $e\n');
      }
    });

    print('Master simulator running. Press Ctrl+C to stop.\n');

    // Keep program running
    await Future.delayed(Duration(days: 1));
  } catch (e) {
    print('Error: $e');
  } finally {
    await client.close();
  }
}
