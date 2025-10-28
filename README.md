# Dart Modbus Monorepo

A pure Dart modbus library supporting RTU, ASCII, and TCP client/server implementations. This library is a Dart port of the [go-modbus](https://github.com/things-go/go-modbus) library.

📚 **[快速开始 Quick Start](QUICK_START.md)** | 📖 **[Melos 指南](doc/MELOS_GUIDE.md)** | ❓ **[FAQ](doc/FAQ.md)**

## 📦 Packages

This monorepo contains two packages:

### [dart_modbus](packages/dart_modbus/)

The core Modbus library supporting TCP, RTU, and ASCII protocols.

- **Modbus TCP Client/Server** - Full TCP client and server implementation
- **Modbus RTU Client** - Connect to Modbus RTU devices over serial
- **Modbus ASCII Client** - Connect to Modbus ASCII devices over serial
- **Data Conversion** - Built-in utilities for Float32, Int32, strings, and more
- **Register Maps** - Point table configuration with JSON support
- **Pure Dart** - No native dependencies (except for serial port implementation)
- **Type Safe** - Full Dart type safety with comprehensive error handling
- **Well Tested** - Unit tests for all core functionality

[📖 View dart_modbus Documentation](packages/dart_modbus/README.md)

### [modbus_simulator](packages/modbus_simulator/)

Master/Slave simulator tools for testing and development.

- **Multi-Protocol Support** - TCP, RTU, and ASCII protocols
- **Slave Simulator** - Responds with random data based on point table
- **Master Simulator** - Polls registers based on point table configuration
- **YAML Configuration** - Easy device configuration
- **Virtual Serial Port** - Built-in virtual serial port for RTU/ASCII testing

[📖 View modbus_simulator Documentation](packages/modbus_simulator/README.md)

## ✨ Features

### Protocols
- ✅ **Modbus TCP** - Full client and server implementation
- ✅ **Modbus RTU** - Serial communication with CRC16 checksum
- ✅ **Modbus ASCII** - Human-readable serial protocol with LRC checksum

### Function Codes
- **Bit Access**: Read Coils (01), Read Discrete Inputs (02), Write Single Coil (05), Write Multiple Coils (15)
- **Register Access**: Read Holding Registers (03), Read Input Registers (04), Write Single Register (06), Write Multiple Registers (16)
- **Advanced**: Read/Write Multiple Registers (23), Mask Write Register (22), Read FIFO Queue (24)

### Data Types
- 16-bit: `int16`, `uint16`
- 32-bit: `int32`, `uint32`, `float32`
- 64-bit: `float64`
- Strings (ASCII encoding)
- Bit operations with configurable byte order

## 🚀 Quick Start

```bash
# Install Melos
dart pub global activate melos

# Bootstrap the monorepo
melos bootstrap

# Run tests
melos run test

# Start simulators (choose protocol)
# TCP protocol
melos run simulator:tcp:slave    # Start TCP slave
melos run simulator:tcp:master   # Start TCP master

# RTU protocol (with virtual serial port)
melos run simulator:rtu:slave    # Start RTU slave
melos run simulator:rtu:master   # Start RTU master

# ASCII protocol (with virtual serial port)
melos run simulator:ascii:slave  # Start ASCII slave
melos run simulator:ascii:master # Start ASCII master
```

## 🎮 Simulators

The project includes comprehensive simulator tools for all three protocols:

### TCP Simulators
```bash
# Terminal 1: Start TCP slave on 127.0.0.1:5020
melos run simulator:tcp:slave

# Terminal 2: Start TCP master to poll the slave
melos run simulator:tcp:master
```

### RTU Simulators (Virtual Serial Port)
```bash
# Runs both master and slave in one process using virtual serial port
melos run simulator:rtu:slave   # Slave with virtual port
melos run simulator:rtu:master  # Master connecting to slave
```

### ASCII Simulators (Virtual Serial Port)
```bash
# Similar to RTU but uses ASCII encoding
melos run simulator:ascii:slave   # Slave with virtual port
melos run simulator:ascii:master  # Master connecting to slave
```

All simulators use YAML configuration files in `packages/modbus_simulator/config/`:
- `device_config.yaml` - TCP device configuration
- `serial_config.yaml` - RTU/ASCII configuration

See [modbus_simulator README](packages/modbus_simulator/README.md) for detailed usage.

## 📖 Documentation

- [Quick Start Guide](QUICK_START.md) - Get started quickly
- [Melos Guide](doc/MELOS_GUIDE.md) - Complete Melos usage guide
- [CHANGELOG Guide](doc/CHANGELOG_GUIDE.md) - How to manage CHANGELOG
- [FAQ](doc/FAQ.md) - Frequently asked questions

## 🛠️ Development

```bash
# Format code
make format

# Run analysis
make analyze

# Run tests
make test

# Complete CI check
make ci
```

## 📝 Project Structure

```
dart-modbus/
├── packages/
│   ├── dart_modbus/        # Core Modbus library
│   │   ├── lib/            # Library source code
│   │   ├── test/           # Unit tests
│   │   └── example/        # Usage examples
│   └── modbus_simulator/   # Simulator tools
│       ├── bin/            # Executable simulators
│       └── config/         # Configuration files
├── doc/                    # Documentation
├── melos.yaml              # Melos configuration
├── Makefile                # Convenient commands
└── CHANGELOG.md            # Change log
```

## 🔖 Version Management

We use [Melos](https://melos.invertase.dev/) for monorepo management and [Cider](https://pub.dev/packages/cider) for CHANGELOG automation.

```bash
# Add changes to CHANGELOG
melos run changelog:add "New feature description"
melos run changelog:fix "Bug fix description"

# Release new version
melos run version:minor  # 1.0.0 -> 1.1.0
melos run version:patch  # 1.0.0 -> 1.0.1
```

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details

## 🙏 Acknowledgments

This library is a port of the archived [go-modbus](https://github.com/things-go/go-modbus) project. The original author has released it without license restrictions.

## 📚 References

- [Modbus Specifications](http://www.modbus.org/specs.php)
- [go-modbus](https://github.com/things-go/go-modbus) - Original Go implementation
- [Melos](https://melos.invertase.dev/) - Monorepo management
- [Cider](https://pub.dev/packages/cider) - CHANGELOG automation
