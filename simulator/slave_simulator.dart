import 'dart:typed_data';
import '../lib/modbus.dart';

/// Modbus slave simulator that responds with random data
///
/// Usage: dart run simulator/slave_simulator.dart [config.yaml]
void main(List<String> args) async {
  final configPath = args.isNotEmpty ? args[0] : 'simulator/device_config.yaml';

  print('Loading configuration from: $configPath');
  final config = await PointTableConfig.fromFile(configPath);

  print('Starting Modbus ${config.protocol.toUpperCase()} Slave Simulator');
  print('Device: ${config.name}');
  print('Slave ID: ${config.slaveId}');

  if (config.protocol == 'tcp') {
    await _runTCPSlave(config);
  } else {
    print('Serial protocols (RTU/ASCII) not yet implemented in simulator');
    print('Please use TCP protocol in configuration');
  }
}

/// Run TCP slave simulator
Future<void> _runTCPSlave(PointTableConfig config) async {
  if (config.address == null) {
    print('Error: TCP address not specified in configuration');
    return;
  }

  final parts = config.address!.split(':');
  final host = parts[0];
  final port = int.parse(parts[1]);

  // Create register storage
  final storage = ModbusStorage(config);

  // Create TCP server
  final server = ModbusTCPServer(
    host: host,
    port: port,
    requestHandler: (slaveId, request) async {
      if (slaveId != config.slaveId && slaveId != 0) {
        return null; // Not for this slave
      }

      return storage.handleRequest(request);
    },
  );

  await server.start();

  print('Slave simulator running. Press Ctrl+C to stop.');
  print('Registers:');
  for (final reg in config.registers) {
    print('  - ${reg.name}: ${reg.type.name} @ ${reg.address} (${reg.dataType.name})');
  }
}

/// Storage for simulated Modbus registers
class ModbusStorage {
  final PointTableConfig config;
  final Map<int, bool> coils = {};
  final Map<int, bool> discreteInputs = {};
  final Map<int, int> inputRegisters = {};
  final Map<int, int> holdingRegisters = {};

  ModbusStorage(this.config) {
    _initializeStorage();
  }

  /// Initialize storage with random values
  void _initializeStorage() {
    for (final reg in config.registers) {
      switch (reg.type) {
        case RegisterType.coil:
          coils[reg.address] = RandomValueGenerator.generateValue(DataType.bool) as bool;
          break;

        case RegisterType.discreteInput:
          discreteInputs[reg.address] = RandomValueGenerator.generateValue(DataType.bool) as bool;
          break;

        case RegisterType.inputRegister:
          _generateRegisterValue(inputRegisters, reg);
          break;

        case RegisterType.holdingRegister:
          _generateRegisterValue(holdingRegisters, reg);
          break;
      }
    }
  }

  /// Generate random value for a register
  void _generateRegisterValue(Map<int, int> storage, RegisterDefinition reg) {
    final value = RandomValueGenerator.generateValue(reg.dataType);

    switch (reg.dataType) {
      case DataType.uint16:
      case DataType.int16:
        storage[reg.address] = value as int;
        break;

      case DataType.uint32:
      case DataType.int32:
        final bytes = DataConverter.int32ToBytes(value as int);
        final regs = DataConverter.bytesToUint16(bytes);
        storage[reg.address] = regs[0];
        storage[reg.address + 1] = regs[1];
        break;

      case DataType.float32:
        final bytes = DataConverter.float32ToBytes(value as double);
        final regs = DataConverter.bytesToUint16(bytes);
        storage[reg.address] = regs[0];
        storage[reg.address + 1] = regs[1];
        break;

      case DataType.float64:
        final bytes = DataConverter.float64ToBytes(value as double);
        final regs = DataConverter.bytesToUint16(bytes);
        for (int i = 0; i < 4; i++) {
          storage[reg.address + i] = regs[i];
        }
        break;

      case DataType.string:
        final str = value as String;
        final bytes = DataConverter.stringToBytes(str, length: (reg.quantity ?? 1) * 2);
        final regs = DataConverter.bytesToUint16(bytes);
        for (int i = 0; i < regs.length; i++) {
          storage[reg.address + i] = regs[i];
        }
        break;

      case DataType.bool:
        storage[reg.address] = (value as bool) ? 1 : 0;
        break;
    }
  }

  /// Handle Modbus request
  Future<ProtocolDataUnit?> handleRequest(ProtocolDataUnit request) async {
    try {
      switch (request.funcCode) {
        case funcCodeReadCoils:
          return _handleReadCoils(request);
        case funcCodeReadDiscreteInputs:
          return _handleReadDiscreteInputs(request);
        case funcCodeReadHoldingRegisters:
          return _handleReadHoldingRegisters(request);
        case funcCodeReadInputRegisters:
          return _handleReadInputRegisters(request);
        case funcCodeWriteSingleCoil:
          return _handleWriteSingleCoil(request);
        case funcCodeWriteSingleRegister:
          return _handleWriteSingleRegister(request);
        case funcCodeWriteMultipleCoils:
          return _handleWriteMultipleCoils(request);
        case funcCodeWriteMultipleRegisters:
          return _handleWriteMultipleRegisters(request);
        default:
          return _createException(exceptionCodeIllegalFunction);
      }
    } catch (e) {
      print('Error handling request: $e');
      return _createException(exceptionCodeServerDeviceFailure);
    }
  }

  /// Read coils (FC 01)
  ProtocolDataUnit _handleReadCoils(ProtocolDataUnit request) {
    final data = ByteData.sublistView(Uint8List.fromList(request.data));
    final address = data.getUint16(0, Endian.big);
    final quantity = data.getUint16(2, Endian.big);

    if (quantity < 1 || quantity > readBitsQuantityMax) {
      return _createException(exceptionCodeIllegalDataValue);
    }

    final byteCount = (quantity + 7) ~/ 8;
    final result = Uint8List(byteCount);

    for (int i = 0; i < quantity; i++) {
      final value = coils[address + i] ?? false;
      if (value) {
        result[i ~/ 8] |= (1 << (i % 8));
      }
    }

    return ProtocolDataUnit(funcCodeReadCoils, [byteCount, ...result]);
  }

  /// Read discrete inputs (FC 02)
  ProtocolDataUnit _handleReadDiscreteInputs(ProtocolDataUnit request) {
    final data = ByteData.sublistView(Uint8List.fromList(request.data));
    final address = data.getUint16(0, Endian.big);
    final quantity = data.getUint16(2, Endian.big);

    if (quantity < 1 || quantity > readBitsQuantityMax) {
      return _createException(exceptionCodeIllegalDataValue);
    }

    final byteCount = (quantity + 7) ~/ 8;
    final result = Uint8List(byteCount);

    for (int i = 0; i < quantity; i++) {
      final value = discreteInputs[address + i] ?? false;
      if (value) {
        result[i ~/ 8] |= (1 << (i % 8));
      }
    }

    return ProtocolDataUnit(funcCodeReadDiscreteInputs, [byteCount, ...result]);
  }

  /// Read holding registers (FC 03)
  ProtocolDataUnit _handleReadHoldingRegisters(ProtocolDataUnit request) {
    final data = ByteData.sublistView(Uint8List.fromList(request.data));
    final address = data.getUint16(0, Endian.big);
    final quantity = data.getUint16(2, Endian.big);

    if (quantity < 1 || quantity > readRegQuantityMax) {
      return _createException(exceptionCodeIllegalDataValue);
    }

    final byteCount = quantity * 2;
    final result = Uint8List(byteCount + 1);
    result[0] = byteCount;

    for (int i = 0; i < quantity; i++) {
      final value = holdingRegisters[address + i] ?? 0;
      final offset = 1 + i * 2;
      result[offset] = (value >> 8) & 0xFF;
      result[offset + 1] = value & 0xFF;
    }

    return ProtocolDataUnit(funcCodeReadHoldingRegisters, result);
  }

  /// Read input registers (FC 04)
  ProtocolDataUnit _handleReadInputRegisters(ProtocolDataUnit request) {
    final data = ByteData.sublistView(Uint8List.fromList(request.data));
    final address = data.getUint16(0, Endian.big);
    final quantity = data.getUint16(2, Endian.big);

    if (quantity < 1 || quantity > readRegQuantityMax) {
      return _createException(exceptionCodeIllegalDataValue);
    }

    final byteCount = quantity * 2;
    final result = Uint8List(byteCount + 1);
    result[0] = byteCount;

    for (int i = 0; i < quantity; i++) {
      final value = inputRegisters[address + i] ?? 0;
      final offset = 1 + i * 2;
      result[offset] = (value >> 8) & 0xFF;
      result[offset + 1] = value & 0xFF;
    }

    return ProtocolDataUnit(funcCodeReadInputRegisters, result);
  }

  /// Write single coil (FC 05)
  ProtocolDataUnit _handleWriteSingleCoil(ProtocolDataUnit request) {
    final data = ByteData.sublistView(Uint8List.fromList(request.data));
    final address = data.getUint16(0, Endian.big);
    final value = data.getUint16(2, Endian.big);

    if (value != 0x0000 && value != 0xFF00) {
      return _createException(exceptionCodeIllegalDataValue);
    }

    coils[address] = value == 0xFF00;

    return ProtocolDataUnit(funcCodeWriteSingleCoil, request.data);
  }

  /// Write single register (FC 06)
  ProtocolDataUnit _handleWriteSingleRegister(ProtocolDataUnit request) {
    final data = ByteData.sublistView(Uint8List.fromList(request.data));
    final address = data.getUint16(0, Endian.big);
    final value = data.getUint16(2, Endian.big);

    holdingRegisters[address] = value;

    return ProtocolDataUnit(funcCodeWriteSingleRegister, request.data);
  }

  /// Write multiple coils (FC 15)
  ProtocolDataUnit _handleWriteMultipleCoils(ProtocolDataUnit request) {
    final data = ByteData.sublistView(Uint8List.fromList(request.data));
    final address = data.getUint16(0, Endian.big);
    final quantity = data.getUint16(2, Endian.big);
    final values = request.data.sublist(5);

    if (quantity < 1 || quantity > writeBitsQuantityMax) {
      return _createException(exceptionCodeIllegalDataValue);
    }

    for (int i = 0; i < quantity; i++) {
      final byteIndex = i ~/ 8;
      final bitIndex = i % 8;
      final value = (values[byteIndex] & (1 << bitIndex)) != 0;
      coils[address + i] = value;
    }

    return ProtocolDataUnit(funcCodeWriteMultipleCoils, request.data.sublist(0, 4));
  }

  /// Write multiple registers (FC 16)
  ProtocolDataUnit _handleWriteMultipleRegisters(ProtocolDataUnit request) {
    final data = ByteData.sublistView(Uint8List.fromList(request.data));
    final address = data.getUint16(0, Endian.big);
    final quantity = data.getUint16(2, Endian.big);
    final values = request.data.sublist(5);

    if (quantity < 1 || quantity > writeRegQuantityMax) {
      return _createException(exceptionCodeIllegalDataValue);
    }

    for (int i = 0; i < quantity; i++) {
      final offset = i * 2;
      final value = (values[offset] << 8) | values[offset + 1];
      holdingRegisters[address + i] = value;
    }

    return ProtocolDataUnit(funcCodeWriteMultipleRegisters, request.data.sublist(0, 4));
  }

  /// Create exception response
  ProtocolDataUnit _createException(int exceptionCode) {
    return ProtocolDataUnit(0x80, [exceptionCode]);
  }
}
