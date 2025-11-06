import 'dart:typed_data';

import 'package:dart_modbus/dart_modbus.dart';

void main() async {
  final provider = TCPClientProvider('192.168.1.100:502');
  final client = ModbusClientImpl(provider);

  try {
    await client.connect();
    print('Connected to Modbus TCP server\n');

    // Example 1: Read Float32 (temperature sensor)
    print('=== Example 1: Reading Float32 Temperature ===');
    final tempBytes = await client.readInputRegistersBytes(1, 100, 2);
    final temperature = DataConverter.bytesToFloat32(tempBytes);
    print('Temperature: ${temperature.toStringAsFixed(2)} °C\n');

    // Example 2: Write Float32 (setpoint)
    print('=== Example 2: Writing Float32 Setpoint ===');
    final setpoint = 25.5;
    final setpointBytes = DataConverter.float32ToBytes(setpoint);
    await client.writeMultipleRegistersBytes(1, 200, 2, setpointBytes);
    print('Setpoint written: $setpoint °C\n');

    // Example 3: Read Int32 (counter)
    print('=== Example 3: Reading Int32 Counter ===');
    final counterBytes = await client.readHoldingRegistersBytes(1, 300, 2);
    final counter = DataConverter.bytesToInt32(counterBytes);
    print('Counter value: $counter\n');

    // Example 4: Read String (device name)
    print('=== Example 4: Reading ASCII String ===');
    final nameBytes = await client.readHoldingRegistersBytes(1, 400, 10);
    final deviceName = DataConverter.bytesToString(nameBytes);
    print('Device name: "$deviceName"\n');

    // Example 5: Write String (device name)
    print('=== Example 5: Writing ASCII String ===');
    final newName = 'PLC-001';
    final newNameBytes = DataConverter.stringToBytes(newName, length: 20);
    await client.writeMultipleRegistersBytes(1, 400, 10, newNameBytes);
    print('New device name written: "$newName"\n');

    // Example 6: Bit operations (read individual coil states)
    print('=== Example 6: Bit Operations ===');
    final coils = await client.readCoils(1, 0, 16);
    print('Coil states:');
    for (int i = 0; i < 16; i++) {
      final isOn = DataConverter.getBit(coils, i);
      print('  Coil $i: ${isOn ? "ON" : "OFF"}');
    }
    print('');

    // Example 7: Little Endian (some devices use reversed word order)
    print('=== Example 7: Little Endian Float32 ===');
    final leBytes = await client.readHoldingRegistersBytes(1, 500, 2);
    final leValue = DataConverter.bytesToFloat32(
      leBytes,
      byteOrder: ByteOrder.littleEndian,
    );
    print('Little endian value: ${leValue.toStringAsFixed(2)}\n');

    // Example 8: Signed vs Unsigned integers
    print('=== Example 8: Signed vs Unsigned Int16 ===');
    final int16Bytes = await client.readHoldingRegistersBytes(1, 600, 1);
    final signedValue = DataConverter.bytesToInt16(int16Bytes)[0];
    final unsignedValue = DataConverter.bytesToUint16(int16Bytes)[0];
    print('Signed: $signedValue');
    print('Unsigned: $unsignedValue\n');

    // Example 9: Creating bit mask for multiple coils
    print('=== Example 9: Writing Multiple Coils with Bit Mask ===');
    final coilMask = Uint8List(2); // 16 coils
    DataConverter.setBit(coilMask, 0, true); // Coil 0 ON
    DataConverter.setBit(coilMask, 5, true); // Coil 5 ON
    DataConverter.setBit(coilMask, 10, true); // Coil 10 ON
    await client.writeMultipleCoils(1, 0, 16, coilMask);
    print('Coils 0, 5, 10 turned ON\n');

    // Example 10: Double precision (Float64)
    print('=== Example 10: Float64 (Double Precision) ===');
    final doubleValue = 123.456789;
    final doubleBytes = DataConverter.float64ToBytes(doubleValue);
    print('Original: $doubleValue');
    final recovered = DataConverter.bytesToFloat64(doubleBytes);
    print('Recovered: $recovered');

  } finally {
    await client.close();
    print('\nConnection closed');
  }
}
