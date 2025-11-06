# Dart Modbus

A pure Dart modbus library supporting RTU, ASCII, and TCP client/server implementations. This library is a Dart port of the [go-modbus](https://github.com/things-go/go-modbus) library.

## Features

- **Modbus TCP Client** - Connect to Modbus TCP servers
- **Modbus TCP Server** - Create Modbus TCP servers
- **Modbus RTU Client** - Connect to Modbus RTU devices over serial
- **Modbus ASCII Client** - Connect to Modbus ASCII devices over serial
- **Pure Dart** - No native dependencies (except for serial port implementation)
- **Type Safe** - Full Dart type safety with generics
- **Fast** - Optimized encoding and decoding
- **Data Conversion** - Built-in utilities for Float32, Int32, strings, and more
- **Register Maps** - Point table configuration with JSON support
- **Well Documented** - Comprehensive dartdoc comments and examples
- **Fully Tested** - Unit tests for all core functionality

## Supported Functions

### A bit Access
- Read Discrete Inputs (FC 02)
- Read Coils (FC 01)
- Write Single Coil (FC 05)
- Write Multiple Coils (FC 15)

### 16-bit Access
- Read Input Registers (FC 04)
- Read Holding Registers (FC 03)
- Write Single Register (FC 06)
- Write Multiple Registers (FC 16)
- Read/Write Multiple Registers (FC 23)
- Mask Write Register (FC 22)
- Read FIFO Queue (FC 24)

## Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  dart_modbus: ^1.0.0
```

## Usage

### Modbus TCP Client

```dart
import 'package:dart_modbus/modbus.dart';

void main() async {
  final provider = TCPClientProvider('192.168.1.100:502');
  final client = ModbusClientImpl(provider);

  try {
    await client.connect();

    // Read coils
    final coils = await client.readCoils(1, 0, 10);
    print('Coils: $coils');

    // Read holding registers
    final registers = await client.readHoldingRegisters(1, 0, 5);
    print('Registers: $registers');

    // Write single register
    await client.writeSingleRegister(1, 0, 1234);

  } finally {
    await client.close();
  }
}
```

### Modbus TCP Server

```dart
import 'package:dart_modbus/modbus.dart';

void main() async {
  // Create a simple server that handles requests
  final server = ModbusTCPServer(
    host: '127.0.0.1',
    port: 502,
    requestHandler: (slaveId, request) async {
      // Handle Modbus requests and return responses
      final funcCode = request.funcCode;

      if (funcCode == mbFuncCodeReadHoldingRegisters) {
        // Parse request
        final address = ByteData.sublistView(request.data).getUint16(0, Endian.big);
        final quantity = ByteData.sublistView(request.data).getUint16(2, Endian.big);

        // Generate response data
        final data = Uint8List(1 + quantity * 2);
        data[0] = quantity * 2; // byte count

        // Fill with example values
        for (var i = 0; i < quantity; i++) {
          ByteData.sublistView(data).setUint16(1 + i * 2, address + i, Endian.big);
        }

        return ProtocolDataUnit(funcCode, data);
      }

      return null; // Return null for unsupported function codes
    },
  );

  await server.start();
  print('Server running on ${server.isRunning}');

  // Keep server running...
}
```

### Modbus RTU Client

For RTU/ASCII clients, you need to implement the `SerialPort` interface using a platform-specific serial library such as:
- [flutter_libserialport](https://pub.dev/packages/flutter_libserialport) for Flutter
- [dart_serial_port](https://pub.dev/packages/dart_serial_port) for Dart

```dart
import 'package:dart_modbus/modbus.dart';

// Implement SerialPort using your chosen serial library
class MySerialPort implements SerialPort {
  // Implementation details...
}

void main() async {
  final config = SerialConfig(
    portName: '/dev/ttyUSB0',
    baudRate: 115200,
    dataBits: 8,
    stopBits: 1,
    parity: 'N',
  );

  final serialPort = MySerialPort(config);
  final provider = RTUClientProvider(serialPort, config);
  final client = ModbusClientImpl(provider);

  try {
    await client.connect();
    final registers = await client.readHoldingRegisters(3, 0, 5);
    print('Registers: $registers');
  } finally {
    await client.close();
  }
}
```

### Modbus ASCII Client

Similar to RTU, but uses ASCII encoding:

```dart
import 'package:dart_modbus/modbus.dart';

void main() async {
  final serialPort = MySerialPort(config);
  final provider = ASCIIClientProvider(serialPort);
  final client = ModbusClientImpl(provider);

  // Use the same API as TCP and RTU clients
}
```

## Architecture

The library follows a provider pattern:

### Client
- `ModbusClient` - High-level client interface with all Modbus functions
- `ClientProvider` - Low-level protocol provider interface
- `TCPClientProvider` - TCP/IP implementation
- `RTUClientProvider` - RTU (serial) implementation with CRC16 checksum
- `ASCIIClientProvider` - ASCII (serial) implementation with LRC checksum

### Server
- `ModbusTCPServer` - TCP server implementation with custom request handler

## Advanced Features

### Data Type Conversion

The library includes utilities for converting between Modbus registers and common data types:

```dart
import 'package:dart_modbus/modbus.dart';

// Read Float32 (2 registers)
final bytes = await client.readHoldingRegistersBytes(1, 100, 2);
final temperature = DataConverter.bytesToFloat32(bytes);

// Write Int32 (2 registers)
final value = 12345;
final data = DataConverter.int32ToBytes(value);
await client.writeMultipleRegistersBytes(1, 200, 2, data);

// String conversion
final name = DataConverter.bytesToString(bytes);
final nameBytes = DataConverter.stringToBytes('Device-001', length: 20);

// Bit operations
final isOn = DataConverter.getBit(bytes, 5);
DataConverter.setBit(bytes, 5, true);
```

Supported data types:
- 16-bit: `int16`, `uint16`
- 32-bit: `int32`, `uint32`, `float32`
- 64-bit: `float64`
- Strings (ASCII)
- Bit operations
- Configurable byte order (big/little endian)

### Register Maps (Point Tables)

Define your device's register layout once and reuse it:

```dart
final registerMap = RegisterMap(
  slaveId: 1,
  registers: [
    RegisterDefinition(
      name: 'temperature',
      address: 100,
      type: RegisterType.inputRegister,
      dataType: DataType.float32,
      multiplier: 0.1,
      unit: '°C',
    ),
    RegisterDefinition(
      name: 'setpoint',
      address: 200,
      type: RegisterType.holdingRegister,
      dataType: DataType.float32,
      unit: '°C',
    ),
  ],
);

// Read by name
final temp = await registerMap.read(client, 'temperature');
print('Temperature: $temp °C');

// Write by name
await registerMap.write(client, 'setpoint', 25.5);

// Read all at once
final values = await registerMap.readAll(client);

// Load from JSON file
final map = RegisterMap.fromJson(jsonString);
```

## Examples

See the [example](example/) directory for complete examples:
- `client_tcp_example.dart` - TCP client example
- `client_rtu_example.dart` - RTU client example
- `data_conversion_example.dart` - Data type conversion examples
- `register_map_example.dart` - Register map and point table examples

## Simulator Tools

This package is part of a monorepo that includes the [modbus_simulator](../modbus_simulator/) package for testing:
- `slave_simulator.dart` - Modbus slave that responds with random data
- `master_simulator.dart` - Modbus master that polls based on point table
- `rtu_simulator.dart` - RTU protocol simulator with virtual serial port
- `ascii_simulator.dart` - ASCII protocol simulator with virtual serial port
- Configuration files for device setup

See the [modbus_simulator README](../modbus_simulator/README.md) for usage instructions.

## Documentation

- [API Documentation](https://pub.dev/documentation/dart_modbus/latest/)
- [Examples](example/) - Complete working examples
- [Simulator Tools](../modbus_simulator/) - Testing tools for Modbus communication

## References

- [Modbus Specifications](http://www.modbus.org/specs.php)
- [go-modbus](https://github.com/things-go/go-modbus) - Original Go implementation

## License

MIT License - see LICENSE file for details

## Note

This library is a port of the archived go-modbus project. The original author has released it without license restrictions.
