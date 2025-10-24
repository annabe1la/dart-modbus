# Modbus Master/Slave Simulator

This directory contains master and slave simulator programs for testing Modbus communication.

## Overview

### TCP Simulators
- **slave_simulator.dart** - TCP slave/server that responds with random data
- **master_simulator.dart** - TCP master/client that polls registers based on point table

### Serial Simulators (RTU/ASCII)
- **rtu_simulator.dart** - RTU protocol simulator with virtual serial port
- **ascii_simulator.dart** - ASCII protocol simulator with virtual serial port

### Configuration Files
- **device_config.yaml** - TCP device configuration
- **serial_config.yaml** - Serial device configuration (RTU/ASCII)

## Quick Start

### TCP Communication

#### 1. Start the TCP Slave Simulator

In one terminal, run:

```bash
dart run packages/modbus_packages/modbus_simulator/config/bin/slave_simulator.dart packages/modbus_packages/modbus_simulator/config/config/device_config.yaml
```

You should see:

```
Loading configuration from: packages/modbus_simulator/config/device_config.yaml
Starting Modbus TCP Slave Simulator
Device: Temperature Controller
Slave ID: 1
Modbus TCP Server started on 127.0.0.1:5020
Slave simulator running. Press Ctrl+C to stop.
Registers:
  - temperature: inputRegister @ 100 (float32)
  - humidity: inputRegister @ 102 (float32)
  - pressure: inputRegister @ 104 (int32)
  ...
```

### 2. Start the Master Simulator

In another terminal, run:

```bash
dart run packages/modbus_simulator/config/master_simulator.dart packages/modbus_simulator/config/device_config.yaml
```

You should see:

```
Loading configuration from: packages/modbus_simulator/config/device_config.yaml
Starting Modbus TCP Master Simulator
Device: Temperature Controller
Slave ID: 1
Poll Interval: 1000ms
Connecting to slave at 127.0.0.1:5020...
Connected successfully!

Master simulator running. Press Ctrl+C to stop.

=== Poll #1 ===
  temperature: 45.23 °C (inputRegister @ 100)
  humidity: 67.8 %RH (inputRegister @ 102)
  pressure: 101.32 kPa (inputRegister @ 104)
  setpoint: 25.0 °C (holdingRegister @ 200)
  ...
```

The master will continuously poll all registers at the configured interval.

## Configuration File Format

The YAML configuration file defines the point table and connection settings:

```yaml
name: "Temperature Controller"
slaveId: 1
protocol: tcp  # Currently only 'tcp' is supported in simulators
address: "127.0.0.1:5020"
pollInterval: 1000  # Milliseconds

registers:
  - name: temperature
    address: 100
    type: inputRegister  # inputRegister, holdingRegister, coil, discreteInput
    dataType: float32    # uint16, int16, uint32, int32, float32, float64, bool, string
    byteOrder: bigEndian # bigEndian or littleEndian
    multiplier: 1.0      # Optional scaling factor
    unit: "°C"           # Optional unit
    description: "Current temperature reading"
    readOnly: true       # Optional (default: false)
```

### Supported Register Types

- **inputRegister** - Read-only input registers (FC 04)
- **holdingRegister** - Read/write holding registers (FC 03, 06, 16)
- **coil** - Read/write coils (FC 01, 05, 15)
- **discreteInput** - Read-only discrete inputs (FC 02)

### Supported Data Types

- **uint16** - 16-bit unsigned integer (1 register)
- **int16** - 16-bit signed integer (1 register)
- **uint32** - 32-bit unsigned integer (2 registers)
- **int32** - 32-bit signed integer (2 registers)
- **float32** - 32-bit floating point (2 registers)
- **float64** - 64-bit floating point (4 registers)
- **bool** - Boolean value (1 bit for coils, 1 register otherwise)
- **string** - ASCII string (specify `quantity` for number of registers)

## How It Works

### Slave Simulator

1. Loads the YAML configuration
2. Initializes all registers with random values based on their data types
3. Starts a TCP server on the configured address
4. Responds to Modbus requests with the stored values
5. Supports read/write operations for all function codes

### Master Simulator

1. Loads the YAML configuration
2. Connects to the slave at the configured address
3. Reads all registers defined in the point table
4. Displays values with units and descriptions
5. Repeats at the configured poll interval

## Advanced Usage

### Custom Configuration

Create your own YAML file with custom register definitions:

```bash
dart run packages/modbus_simulator/config/slave_simulator.dart my_device.yaml
dart run packages/modbus_simulator/config/master_simulator.dart my_device.yaml
```

### Changing Poll Interval

Modify the `pollInterval` value in the YAML file (in milliseconds):

```yaml
pollInterval: 2000  # Poll every 2 seconds
```

### Testing Write Operations

The slave supports write operations. You can write to:
- Holding registers (FC 06, 16)
- Coils (FC 05, 15)

The master simulator currently only reads. To test writes, modify the master code or use a standard Modbus client.

### RTU Communication

RTU simulator uses virtual serial ports for testing:

```bash
# Run RTU simulator (includes both master and slave)
dart run packages/modbus_simulator/bin/rtu_simulator.dart
```

**Features:**
- ✅ Binary format (efficient)
- ✅ CRC16 checksum
- ✅ Virtual serial port communication
- ✅ Demonstrates master-slave communication

**Configuration:**
See `config/serial_config.yaml` for RTU configuration example.

### ASCII Communication

ASCII simulator uses human-readable format:

```bash
# Run ASCII simulator
dart run packages/modbus_simulator/bin/ascii_simulator.dart
```

**Features:**
- ✅ Human-readable format (easy to debug)
- ✅ LRC checksum
- ✅ Virtual serial port communication
- ✅ 7-bit data with even parity (typical)

## Virtual Serial Ports

The RTU and ASCII simulators use an in-memory virtual serial port implementation for testing. This allows you to run master and slave in the same process without actual hardware.

### Using Real Serial Ports

To use real serial hardware, you need to implement the `SerialPort` interface using a platform-specific library:

**For Flutter:**
```yaml
dependencies:
  flutter_libserialport: ^0.3.0
```

**For Dart CLI:**
```yaml
dependencies:
  dart_serial_port: ^0.2.0
```

**Example implementation:**
```dart
import 'package:flutter_libserialport/flutter_libserialport.dart' as sp;

class LibSerialPort implements SerialPort {
  // Implementation details...
}
```

See [FAQ](../../../doc/FAQ.md) for complete implementation examples.

## Protocol Comparison

| Feature | TCP | RTU | ASCII |
|---------|-----|-----|-------|
| **Transport** | Ethernet | Serial | Serial |
| **Format** | Binary | Binary | ASCII |
| **Error Check** | TCP checksum | CRC16 | LRC |
| **Speed** | Fast | Fast | Slow |
| **Debug** | Network tools | Logic analyzer | Terminal |
| **Distance** | Long | Short | Short |

## Limitations

### TCP Simulators
- The slave generates random data on startup and doesn't update it
- The master only performs read operations

### Serial Simulators (RTU/ASCII)
- Uses virtual serial ports (not real hardware)
- Simplified implementation for demonstration
- For production use, implement SerialPort with real hardware

## See Also

- [device_config.yaml](config/device_config.yaml) - TCP configuration example
- [serial_config.yaml](config/serial_config.yaml) - Serial configuration example
- [Main README](../../README.md) - Library documentation
- [FAQ](../../../doc/FAQ.md) - Frequently asked questions
