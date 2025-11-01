# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2025-10-24

### Added

#### Core Features
- Modbus TCP client implementation with full protocol support
- Modbus RTU client implementation with CRC16 checksum
- Modbus ASCII client implementation with LRC checksum
- Support for 11 common Modbus function codes:
  - Read Coils (FC 01)
  - Read Discrete Inputs (FC 02)
  - Read Holding Registers (FC 03)
  - Read Input Registers (FC 04)
  - Write Single Coil (FC 05)
  - Write Single Register (FC 06)
  - Write Multiple Coils (FC 15)
  - Write Multiple Registers (FC 16)
  - Mask Write Register (FC 22)
  - Read/Write Multiple Registers (FC 23)
  - Read FIFO Queue (FC 24)

#### Data Conversion Utilities
- Type-safe data conversion for all common data types
- Support for int16/32, uint16/32, float32/64, strings, booleans
- Configurable byte order (big-endian/little-endian)
- Bit manipulation utilities

#### Point Table Configuration
- RegisterMap class for device register definitions
- JSON serialization support for register configurations
- Automatic data type conversion and scaling (multiplier/offset)
- Support for all register types (coils, discrete inputs, input/holding registers)

#### Server Implementation
- Modbus TCP Server for slave/server simulation
- YAML configuration loader for point tables
- Random data generator for testing

#### Simulator Tools
- Standalone slave simulator with random data generation
- Standalone master simulator with point table polling
- YAML-based device configuration
- Support for TCP protocol (RTU/ASCII coming soon)

#### Documentation
- Comprehensive dartdoc comments for all public APIs
- Complete usage examples for all features
- Detailed README with advanced features section

#### Testing
- Unit tests for CRC16 checksum calculation
- Unit tests for LRC checksum calculation
- Unit tests for all data type conversions
- 29 passing tests with 100% coverage of core utilities

### Technical Details
- Pure Dart implementation (no native dependencies for TCP)
- Type-safe with full Dart null safety support
- Zero external dependencies (except yaml for configuration)
- Efficient byte manipulation with typed data
- Provider pattern for protocol abstraction

[Unreleased]: https://github.com/annabe1la/dart-modbus/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/annabe1la/dart-modbus/releases/tag/v0.1.0
