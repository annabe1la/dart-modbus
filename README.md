# Dart Modbus Monorepo

A pure Dart modbus library supporting RTU, ASCII, and TCP client/server implementations. This library is a Dart port of the [go-modbus](https://github.com/things-go/go-modbus) library.

📚 **[快速开始 Quick Start](QUICK_START.md)** | 📖 **[Melos 指南](doc/MELOS_GUIDE.md)** | ❓ **[FAQ](doc/FAQ.md)**

## 📦 Packages

This monorepo contains two packages:

### [dart_modbus](packages/dart_modbus/)

The core Modbus library supporting TCP, RTU, and ASCII protocols.

- **Modbus TCP Client** - Connect to Modbus TCP servers
- **Modbus RTU Client** - Connect to Modbus RTU devices over serial
- **Modbus ASCII Client** - Connect to Modbus ASCII devices over serial
- **Modbus TCP Server** - Implement Modbus TCP slaves
- **Data Conversion** - Built-in utilities for Float32, Int32, strings, and more
- **Register Maps** - Point table configuration with YAML support
- **Pure Dart** - No native dependencies (except for serial port implementation)

[📖 View dart_modbus Documentation](packages/dart_modbus/README.md)

### [modbus_simulator](packages/modbus_simulator/)

Master/Slave simulator tools for testing and development.

- **Slave Simulator** - Responds with random data based on point table
- **Master Simulator** - Polls registers based on point table configuration
- **YAML Configuration** - Easy device configuration
- **TCP Support** - Currently supports TCP protocol

[📖 View modbus_simulator Documentation](packages/modbus_simulator/README.md)

## 🚀 Quick Start

```bash
# Install Melos
dart pub global activate melos

# Bootstrap the monorepo
melos bootstrap

# Run tests
melos run test

# Start simulators
make slave   # or: melos run simulator:slave
make master  # or: melos run simulator:master
```

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
