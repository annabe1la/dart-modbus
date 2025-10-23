# Frequently Asked Questions (FAQ)

## General Questions

### Q: What Modbus protocols are supported?

**A:** This library supports:
- **Modbus TCP** - Ethernet/IP communication
- **Modbus RTU** - Serial communication with CRC16 checksum
- **Modbus ASCII** - Serial communication with LRC checksum

### Q: Do I need platform-specific dependencies?

**A:** For TCP, no dependencies are needed. For RTU/ASCII (serial), you need to implement the `SerialPort` interface using a platform-specific library:
- Flutter: `flutter_libserialport`
- Dart CLI: `dart_serial_port`

### Q: Can I use this in production?

**A:** Yes! The library is based on the well-tested `go-modbus` implementation and includes comprehensive unit tests.

---

## Connection Issues

### Q: How do I handle connection timeouts?

**A:** Configure timeout when creating the provider:

```dart
final provider = TCPClientProvider(
  '192.168.1.100:502',
  timeout: Duration(seconds: 5),
);
```

### Q: My TCP connection keeps dropping, what should I do?

**A:** Consider:
1. Checking network stability
2. Increasing timeout duration
3. Implementing auto-reconnect logic:

```dart
Future<void> connectWithRetry(ModbusClient client, {int maxRetries = 3}) async {
  for (int i = 0; i < maxRetries; i++) {
    try {
      await client.connect();
      return;
    } catch (e) {
      if (i == maxRetries - 1) rethrow;
      await Future.delayed(Duration(seconds: 2));
    }
  }
}
```

### Q: How do I know if my client is still connected?

**A:**

```dart
if (client.isConnected) {
  // Connection is active
} else {
  await client.connect();
}
```

---

## Data Type Conversion

### Q: How do I read a 32-bit float from two registers?

**A:**

```dart
final bytes = await client.readHoldingRegistersBytes(1, 100, 2);
final value = DataConverter.bytesToFloat32(bytes);
```

### Q: My device uses little-endian byte order, how do I handle this?

**A:** Specify byte order in conversion:

```dart
final value = DataConverter.bytesToFloat32(
  bytes,
  byteOrder: ByteOrder.littleEndian,
);
```

### Q: How do I write a string to holding registers?

**A:**

```dart
final name = 'DEVICE-001';
final bytes = DataConverter.stringToBytes(name, length: 20); // Pad to 20 bytes
await client.writeMultipleRegistersBytes(1, 100, 10, bytes); // 10 registers
```

### Q: How do I read individual bits from a register?

**A:**

```dart
final bytes = await client.readHoldingRegistersBytes(1, 0, 1);
final bit5 = DataConverter.getBit(bytes, 5);
```

---

## Protocol-Specific

### Q: What's the difference between slave ID 0 and broadcast?

**A:** Slave ID 0 is used for broadcast writes (no response expected). Regular reads require slave ID 1-247.

### Q: Can I read more than 125 registers at once?

**A:** No, Modbus specification limits:
- Holding/Input registers: Max 125 (FC 03, 04)
- Coils/Discrete inputs: Max 2000 (FC 01, 02)

To read more, split into multiple requests:

```dart
final part1 = await client.readHoldingRegisters(1, 0, 125);
final part2 = await client.readHoldingRegisters(1, 125, 125);
final all = [...part1, ...part2];
```

### Q: How do I implement custom function codes?

**A:** Use the low-level `send` method:

```dart
final response = await client.send(
  1,
  ProtocolDataUnit(0x2B, [0x0E, 0x01, 0x00]), // Custom FC 0x2B
);
```

---

## Register Maps & Configuration

### Q: How do I create a reusable point table?

**A:** Use `RegisterMap`:

```dart
final map = RegisterMap(
  slaveId: 1,
  registers: [
    RegisterDefinition(
      name: 'temperature',
      address: 100,
      type: RegisterType.inputRegister,
      dataType: DataType.float32,
    ),
  ],
);

final temp = await map.read(client, 'temperature');
```

### Q: Can I load register configuration from a file?

**A:** Yes, use JSON:

```dart
final jsonString = await File('register_map.json').readAsString();
final map = RegisterMap.fromJson(jsonString);
```

### Q: How do I handle scaling (multiplier/offset)?

**A:** `RegisterDefinition` handles it automatically:

```dart
RegisterDefinition(
  name: 'temperature',
  address: 100,
  type: RegisterType.inputRegister,
  dataType: DataType.int16,
  multiplier: 0.1,  // Raw value × 0.1
  offset: -50.0,    // Then add -50
)
```

---

## Error Handling

### Q: What exceptions can be thrown?

**A:**
- `ModbusException` - Modbus protocol errors (illegal function, illegal address, etc.)
- `TimeoutException` - Connection or read timeout
- `ArgumentError` - Invalid parameters
- `StateError` - Invalid operation (e.g., writing to read-only register)

### Q: How do I handle Modbus exceptions?

**A:**

```dart
try {
  final result = await client.readHoldingRegisters(1, 0, 10);
} on ModbusException catch (e) {
  switch (e.exceptionCode) {
    case exceptionCodeIllegalDataAddress:
      print('Invalid address');
      break;
    case exceptionCodeIllegalFunction:
      print('Unsupported function');
      break;
    default:
      print('Modbus error: $e');
  }
} on TimeoutException {
  print('Request timed out');
}
```

---

## Performance

### Q: How can I optimize reading many registers?

**A:**
1. Use batch reads (up to 125 registers)
2. Use `RegisterMap.readAll()` to read all at once
3. Reuse client connections
4. Consider connection pooling for multiple devices

### Q: Is it safe to use one client from multiple isolates?

**A:** No, each isolate should have its own client instance. TCP sockets are not thread-safe.

---

## Serial (RTU/ASCII)

### Q: How do I implement SerialPort for my platform?

**A:** Example using `flutter_libserialport`:

```dart
import 'package:flutter_libserialport/flutter_libserialport.dart' as sp;

class LibSerialPort implements SerialPort {
  final SerialConfig config;
  sp.SerialPort? _port;

  @override
  Future<void> open() async {
    _port = sp.SerialPort(config.portName);
    _port!.openReadWrite();
  }

  @override
  Future<Uint8List> read(int length) async {
    final reader = sp.SerialPortReader(_port!);
    final data = await reader.stream.first;
    return Uint8List.fromList(data.take(length).toList());
  }

  // Implement other methods...
}
```

### Q: What baud rates are supported?

**A:** Any baud rate supported by your serial library. Common values:
- 9600, 19200, 38400, 57600, 115200

### Q: RTU vs ASCII - which should I use?

**A:**
- **RTU**: More efficient, binary format, CRC16 checksum
- **ASCII**: Human-readable (for debugging), LRC checksum, slower

Most industrial devices use RTU.

---

## Debugging

### Q: How can I see raw Modbus frames?

**A:** Use `sendRawFrame` or implement logging in your provider.

### Q: How do I validate CRC/LRC checksums manually?

**A:**

```dart
// RTU CRC16
final data = Uint8List.fromList([0x01, 0x03, 0x00, 0x00, 0x00, 0x0A]);
final checksum = crc16(data);
print('CRC: 0x${checksum.toRadixString(16)}');

// ASCII LRC
final lrc = LRC()..reset()..push(data);
print('LRC: 0x${lrc.value.toRadixString(16)}');
```

---

## Contributing

### Q: How can I contribute?

**A:** Contributions are welcome!
1. Fork the repository
2. Create a feature branch
3. Add tests for new features
4. Submit a pull request

### Q: Where do I report bugs?

**A:** Please open an issue on GitHub with:
- Dart/Flutter version
- Library version
- Minimal reproduction code
- Expected vs actual behavior
