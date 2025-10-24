import 'dart:typed_data';

import 'package:dart_modbus/modbus.dart';

void main() async {
  // Create TCP client
  final provider = TCPClientProvider('192.168.1.100:502');
  final client = ModbusClientImpl(provider);

  try {
    // Connect to the server
    await client.connect();
    print('Connected to Modbus TCP server');

    // Read coils (slave ID 1, starting address 0, quantity 10)
    final coils = await client.readCoils(1, 0, 10);
    print('Coils: $coils');

    // Read holding registers (slave ID 1, starting address 0, quantity 5)
    final registers = await client.readHoldingRegisters(1, 0, 5);
    print('Holding registers: $registers');

    // Write single coil (slave ID 1, address 0, value ON)
    await client.writeSingleCoil(1, 0, true);
    print('Single coil written');

    // Write single register (slave ID 1, address 0, value 1234)
    await client.writeSingleRegister(1, 0, 1234);
    print('Single register written');

    // Write multiple registers
    final values = Uint16List.fromList([100, 200, 300]);
    await client.writeMultipleRegisters(1, 0, 3, values);
    print('Multiple registers written');
  } catch (e) {
    print('Error: $e');
  } finally {
    // Close connection
    await client.close();
    print('Connection closed');
  }
}
