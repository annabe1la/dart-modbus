import 'dart:typed_data';
import 'package:dart_modbus/modbus.dart';

/// 简单的 Modbus 数据存储
///
/// 存储线圈、离散输入、保持寄存器、输入寄存器
class ModbusStorage {
  final Map<int, bool> _coils = {};
  final Map<int, bool> _discreteInputs = {};
  final Map<int, int> _holdingRegisters = {};
  final Map<int, int> _inputRegisters = {};

  // ==================== Coils ====================

  bool getCoil(int address) => _coils[address] ?? false;

  void setCoil(int address, bool value) {
    _coils[address] = value;
  }

  List<bool> getCoils(int address, int quantity) {
    return List.generate(quantity, (i) => getCoil(address + i));
  }

  void setCoils(int address, List<bool> values) {
    for (int i = 0; i < values.length; i++) {
      setCoil(address + i, values[i]);
    }
  }

  // ==================== Discrete Inputs ====================

  bool getDiscreteInput(int address) => _discreteInputs[address] ?? false;

  void setDiscreteInput(int address, bool value) {
    _discreteInputs[address] = value;
  }

  List<bool> getDiscreteInputs(int address, int quantity) {
    return List.generate(quantity, (i) => getDiscreteInput(address + i));
  }

  // ==================== Holding Registers ====================

  int getHoldingRegister(int address) => _holdingRegisters[address] ?? 0;

  void setHoldingRegister(int address, int value) {
    _holdingRegisters[address] = value & 0xFFFF;
  }

  List<int> getHoldingRegisters(int address, int quantity) {
    return List.generate(quantity, (i) => getHoldingRegister(address + i));
  }

  void setHoldingRegisters(int address, List<int> values) {
    for (int i = 0; i < values.length; i++) {
      setHoldingRegister(address + i, values[i]);
    }
  }

  // ==================== Input Registers ====================

  int getInputRegister(int address) => _inputRegisters[address] ?? 0;

  void setInputRegister(int address, int value) {
    _inputRegisters[address] = value & 0xFFFF;
  }

  List<int> getInputRegisters(int address, int quantity) {
    return List.generate(quantity, (i) => getInputRegister(address + i));
  }

  // ==================== 请求处理 ====================

  /// 处理 Modbus 请求并返回响应
  Future<ProtocolDataUnit?> handleRequest(
      int slaveId, ProtocolDataUnit request) async {
    try {
      switch (request.funcCode) {
        case funcCodeReadCoils:
          return _readCoils(request);
        case funcCodeReadDiscreteInputs:
          return _readDiscreteInputs(request);
        case funcCodeReadHoldingRegisters:
          return _readHoldingRegisters(request);
        case funcCodeReadInputRegisters:
          return _readInputRegisters(request);
        case funcCodeWriteSingleCoil:
          return _writeSingleCoil(request);
        case funcCodeWriteSingleRegister:
          return _writeSingleRegister(request);
        case funcCodeWriteMultipleCoils:
          return _writeMultipleCoils(request);
        case funcCodeWriteMultipleRegisters:
          return _writeMultipleRegisters(request);
        default:
          return _exceptionResponse(
              request.funcCode, exceptionCodeIllegalFunction);
      }
    } catch (e) {
      return _exceptionResponse(
          request.funcCode, exceptionCodeServerDeviceFailure);
    }
  }

  // ==================== 私有方法：读取功能 ====================

  ProtocolDataUnit _readCoils(ProtocolDataUnit request) {
    final data = ByteData.sublistView(Uint8List.fromList(request.data));
    final address = data.getUint16(0, Endian.big);
    final quantity = data.getUint16(2, Endian.big);

    if (quantity < 1 || quantity > 2000) {
      return _exceptionResponse(
          request.funcCode, exceptionCodeIllegalDataValue);
    }

    final coils = getCoils(address, quantity);
    final bytes = _boolListToBytes(coils);

    return ProtocolDataUnit(funcCodeReadCoils, [bytes.length, ...bytes]);
  }

  ProtocolDataUnit _readDiscreteInputs(ProtocolDataUnit request) {
    final data = ByteData.sublistView(Uint8List.fromList(request.data));
    final address = data.getUint16(0, Endian.big);
    final quantity = data.getUint16(2, Endian.big);

    if (quantity < 1 || quantity > 2000) {
      return _exceptionResponse(
          request.funcCode, exceptionCodeIllegalDataValue);
    }

    final inputs = getDiscreteInputs(address, quantity);
    final bytes = _boolListToBytes(inputs);

    return ProtocolDataUnit(
        funcCodeReadDiscreteInputs, [bytes.length, ...bytes]);
  }

  ProtocolDataUnit _readHoldingRegisters(ProtocolDataUnit request) {
    final data = ByteData.sublistView(Uint8List.fromList(request.data));
    final address = data.getUint16(0, Endian.big);
    final quantity = data.getUint16(2, Endian.big);

    if (quantity < 1 || quantity > 125) {
      return _exceptionResponse(
          request.funcCode, exceptionCodeIllegalDataValue);
    }

    final registers = getHoldingRegisters(address, quantity);
    final byteCount = quantity * 2;
    final result = Uint8List(byteCount + 1);
    result[0] = byteCount;

    for (int i = 0; i < quantity; i++) {
      final offset = 1 + i * 2;
      result[offset] = (registers[i] >> 8) & 0xFF;
      result[offset + 1] = registers[i] & 0xFF;
    }

    return ProtocolDataUnit(funcCodeReadHoldingRegisters, result);
  }

  ProtocolDataUnit _readInputRegisters(ProtocolDataUnit request) {
    final data = ByteData.sublistView(Uint8List.fromList(request.data));
    final address = data.getUint16(0, Endian.big);
    final quantity = data.getUint16(2, Endian.big);

    if (quantity < 1 || quantity > 125) {
      return _exceptionResponse(
          request.funcCode, exceptionCodeIllegalDataValue);
    }

    final registers = getInputRegisters(address, quantity);
    final byteCount = quantity * 2;
    final result = Uint8List(byteCount + 1);
    result[0] = byteCount;

    for (int i = 0; i < quantity; i++) {
      final offset = 1 + i * 2;
      result[offset] = (registers[i] >> 8) & 0xFF;
      result[offset + 1] = registers[i] & 0xFF;
    }

    return ProtocolDataUnit(funcCodeReadInputRegisters, result);
  }

  // ==================== 私有方法：写入功能 ====================

  ProtocolDataUnit _writeSingleCoil(ProtocolDataUnit request) {
    final data = ByteData.sublistView(Uint8List.fromList(request.data));
    final address = data.getUint16(0, Endian.big);
    final value = data.getUint16(2, Endian.big);

    if (value != 0x0000 && value != 0xFF00) {
      return _exceptionResponse(
          request.funcCode, exceptionCodeIllegalDataValue);
    }

    setCoil(address, value == 0xFF00);

    return ProtocolDataUnit(funcCodeWriteSingleCoil, request.data);
  }

  ProtocolDataUnit _writeSingleRegister(ProtocolDataUnit request) {
    final data = ByteData.sublistView(Uint8List.fromList(request.data));
    final address = data.getUint16(0, Endian.big);
    final value = data.getUint16(2, Endian.big);

    setHoldingRegister(address, value);

    return ProtocolDataUnit(funcCodeWriteSingleRegister, request.data);
  }

  ProtocolDataUnit _writeMultipleCoils(ProtocolDataUnit request) {
    final data = ByteData.sublistView(Uint8List.fromList(request.data));
    final address = data.getUint16(0, Endian.big);
    final quantity = data.getUint16(2, Endian.big);
    final byteCount = request.data[4];
    final coilBytes = request.data.sublist(5);

    if (quantity < 1 || quantity > 1968 || coilBytes.length != byteCount) {
      return _exceptionResponse(
          request.funcCode, exceptionCodeIllegalDataValue);
    }

    final coils = _bytesToBoolList(coilBytes, quantity);
    setCoils(address, coils);

    return ProtocolDataUnit(
        funcCodeWriteMultipleCoils, request.data.sublist(0, 4));
  }

  ProtocolDataUnit _writeMultipleRegisters(ProtocolDataUnit request) {
    final data = ByteData.sublistView(Uint8List.fromList(request.data));
    final address = data.getUint16(0, Endian.big);
    final quantity = data.getUint16(2, Endian.big);
    final byteCount = request.data[4];
    final registerBytes = request.data.sublist(5);

    if (quantity < 1 ||
        quantity > 123 ||
        byteCount != quantity * 2 ||
        registerBytes.length != byteCount) {
      return _exceptionResponse(
          request.funcCode, exceptionCodeIllegalDataValue);
    }

    final registers = <int>[];
    for (int i = 0; i < quantity; i++) {
      final offset = i * 2;
      final value = (registerBytes[offset] << 8) | registerBytes[offset + 1];
      registers.add(value);
    }

    setHoldingRegisters(address, registers);

    return ProtocolDataUnit(
        funcCodeWriteMultipleRegisters, request.data.sublist(0, 4));
  }

  // ==================== 工具方法 ====================

  ProtocolDataUnit _exceptionResponse(int funcCode, int exceptionCode) {
    return ProtocolDataUnit(0x80 | funcCode, [exceptionCode]);
  }

  List<int> _boolListToBytes(List<bool> bools) {
    final byteCount = (bools.length + 7) ~/ 8;
    final bytes = List<int>.filled(byteCount, 0);

    for (int i = 0; i < bools.length; i++) {
      if (bools[i]) {
        bytes[i ~/ 8] |= (1 << (i % 8));
      }
    }

    return bytes;
  }

  List<bool> _bytesToBoolList(List<int> bytes, int quantity) {
    final bools = <bool>[];

    for (int i = 0; i < quantity; i++) {
      final byteIndex = i ~/ 8;
      final bitIndex = i % 8;
      bools.add((bytes[byteIndex] & (1 << bitIndex)) != 0);
    }

    return bools;
  }

  /// 清空所有数据
  void clear() {
    _coils.clear();
    _discreteInputs.clear();
    _holdingRegisters.clear();
    _inputRegisters.clear();
  }
}
