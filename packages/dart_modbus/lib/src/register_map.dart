import 'dart:convert';
import 'dart:typed_data';
import 'client.dart';
import 'data_converter.dart';

/// Register type enumeration.
enum RegisterType {
  /// Coils (read/write bits) - FC 01, 05, 15
  coil,

  /// Discrete inputs (read-only bits) - FC 02
  discreteInput,

  /// Input registers (read-only 16-bit) - FC 04
  inputRegister,

  /// Holding registers (read/write 16-bit) - FC 03, 06, 16
  holdingRegister,
}

/// Data type for register values.
enum DataType {
  /// 16-bit unsigned integer (1 register)
  uint16,

  /// 16-bit signed integer (1 register)
  int16,

  /// 32-bit unsigned integer (2 registers)
  uint32,

  /// 32-bit signed integer (2 registers)
  int32,

  /// 32-bit float (2 registers)
  float32,

  /// 64-bit double (4 registers)
  float64,

  /// Boolean (bit value)
  bool,

  /// ASCII string (variable registers)
  string,
}

/// Register definition in a point table.
///
/// Example:
/// ```dart
/// final tempReg = RegisterDefinition(
///   name: 'temperature',
///   address: 100,
///   type: RegisterType.inputRegister,
///   dataType: DataType.float32,
///   multiplier: 0.1,
///   unit: '°C',
/// );
/// ```
class RegisterDefinition {
  /// Register name/identifier
  final String name;

  /// Register address
  final int address;

  /// Register type (coil, discrete input, input register, holding register)
  final RegisterType type;

  /// Data type (uint16, int32, float32, etc.)
  final DataType dataType;

  /// Number of registers (auto-calculated if null)
  final int? quantity;

  /// Byte order for multi-register types
  final ByteOrder byteOrder;

  /// Multiplier for scaling (applied after reading)
  final double? multiplier;

  /// Offset for scaling (applied after multiplier)
  final double? offset;

  /// Unit of measurement (for documentation)
  final String? unit;

  /// Description (for documentation)
  final String? description;

  /// Read-only flag
  final bool readOnly;

  const RegisterDefinition({
    required this.name,
    required this.address,
    required this.type,
    this.dataType = DataType.uint16,
    this.quantity,
    this.byteOrder = ByteOrder.bigEndian,
    this.multiplier,
    this.offset,
    this.unit,
    this.description,
    this.readOnly = false,
  });

  /// Get the number of registers required for this data type.
  int get registerCount {
    if (quantity != null) return quantity!;

    switch (dataType) {
      case DataType.uint16:
      case DataType.int16:
        return 1;
      case DataType.uint32:
      case DataType.int32:
      case DataType.float32:
        return 2;
      case DataType.float64:
        return 4;
      case DataType.bool:
        return 1;
      case DataType.string:
        return quantity ?? 1;
    }
  }

  /// Decode raw bytes to value based on data type.
  dynamic decode(Uint8List bytes) {
    dynamic value;

    switch (dataType) {
      case DataType.uint16:
        value = DataConverter.bytesToUint16(bytes)[0];
        break;
      case DataType.int16:
        value = DataConverter.bytesToInt16(bytes)[0];
        break;
      case DataType.uint32:
        value = DataConverter.bytesToUint32(bytes, byteOrder: byteOrder);
        break;
      case DataType.int32:
        value = DataConverter.bytesToInt32(bytes, byteOrder: byteOrder);
        break;
      case DataType.float32:
        value = DataConverter.bytesToFloat32(bytes, byteOrder: byteOrder);
        break;
      case DataType.float64:
        value = DataConverter.bytesToFloat64(bytes, byteOrder: byteOrder);
        break;
      case DataType.bool:
        value = DataConverter.getBit(bytes, 0);
        break;
      case DataType.string:
        value = DataConverter.bytesToString(bytes);
        break;
    }

    // Apply scaling
    if (value is num && (multiplier != null || offset != null)) {
      value = value * (multiplier ?? 1.0) + (offset ?? 0.0);
    }

    return value;
  }

  /// Encode value to bytes based on data type.
  Uint8List encode(dynamic value) {
    // Remove scaling
    if (value is num && (multiplier != null || offset != null)) {
      value = (value - (offset ?? 0.0)) / (multiplier ?? 1.0);
    }

    switch (dataType) {
      case DataType.uint16:
        return DataConverter.uint16ToBytes([value as int]);
        break;
      case DataType.int16:
        return DataConverter.int16ToBytes([value as int]);
        break;
      case DataType.uint32:
        return DataConverter.uint32ToBytes(value as int, byteOrder: byteOrder);
        break;
      case DataType.int32:
        return DataConverter.int32ToBytes(value as int, byteOrder: byteOrder);
        break;
      case DataType.float32:
        return DataConverter.float32ToBytes(value as double, byteOrder: byteOrder);
        break;
      case DataType.float64:
        return DataConverter.float64ToBytes(value as double, byteOrder: byteOrder);
        break;
      case DataType.bool:
        final bytes = Uint8List(1);
        DataConverter.setBit(bytes, 0, value as bool);
        return bytes;
        break;
      case DataType.string:
        return DataConverter.stringToBytes(value as String, length: registerCount * 2);
        break;
    }
  }

  /// Create from JSON map.
  factory RegisterDefinition.fromJson(Map<String, dynamic> json) {
    return RegisterDefinition(
      name: json['name'] as String,
      address: json['address'] as int,
      type: RegisterType.values.byName(json['type'] as String),
      dataType: json['dataType'] != null
          ? DataType.values.byName(json['dataType'] as String)
          : DataType.uint16,
      quantity: json['quantity'] as int?,
      byteOrder: json['byteOrder'] != null
          ? ByteOrder.values.byName(json['byteOrder'] as String)
          : ByteOrder.bigEndian,
      multiplier: json['multiplier'] != null ? (json['multiplier'] as num).toDouble() : null,
      offset: json['offset'] != null ? (json['offset'] as num).toDouble() : null,
      unit: json['unit'] as String?,
      description: json['description'] as String?,
      readOnly: json['readOnly'] as bool? ?? false,
    );
  }

  /// Convert to JSON map.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'type': type.name,
      'dataType': dataType.name,
      if (quantity != null) 'quantity': quantity,
      'byteOrder': byteOrder.name,
      if (multiplier != null) 'multiplier': multiplier,
      if (offset != null) 'offset': offset,
      if (unit != null) 'unit': unit,
      if (description != null) 'description': description,
      'readOnly': readOnly,
    };
  }
}

/// Point table (register map) for a Modbus device.
///
/// Example:
/// ```dart
/// final registerMap = RegisterMap(
///   slaveId: 1,
///   registers: [
///     RegisterDefinition(name: 'temp', address: 100, type: RegisterType.inputRegister, dataType: DataType.float32),
///     RegisterDefinition(name: 'setpoint', address: 200, type: RegisterType.holdingRegister, dataType: DataType.float32),
///   ],
/// );
///
/// // Read all registers
/// final values = await registerMap.readAll(client);
/// print('Temperature: ${values['temp']} °C');
///
/// // Write a value
/// await registerMap.write(client, 'setpoint', 25.5);
/// ```
class RegisterMap {
  /// Slave ID for this device
  final int slaveId;

  /// List of register definitions
  final List<RegisterDefinition> registers;

  /// Device name (optional)
  final String? deviceName;

  RegisterMap({
    required this.slaveId,
    required this.registers,
    this.deviceName,
  });

  /// Read a single register value.
  ///
  /// Parameters:
  /// - [client]: Modbus client
  /// - [name]: Register name
  ///
  /// Returns: Decoded value
  Future<dynamic> read(ModbusClient client, String name) async {
    final reg = registers.firstWhere((r) => r.name == name,
        orElse: () => throw ArgumentError('Register "$name" not found'));

    Uint8List bytes;

    switch (reg.type) {
      case RegisterType.coil:
        bytes = await client.readCoils(slaveId, reg.address, reg.registerCount);
        break;
      case RegisterType.discreteInput:
        bytes = await client.readDiscreteInputs(slaveId, reg.address, reg.registerCount);
        break;
      case RegisterType.inputRegister:
        bytes = await client.readInputRegistersBytes(slaveId, reg.address, reg.registerCount);
        break;
      case RegisterType.holdingRegister:
        bytes = await client.readHoldingRegistersBytes(slaveId, reg.address, reg.registerCount);
        break;
    }

    return reg.decode(bytes);
  }

  /// Write a single register value.
  ///
  /// Parameters:
  /// - [client]: Modbus client
  /// - [name]: Register name
  /// - [value]: Value to write
  Future<void> write(ModbusClient client, String name, dynamic value) async {
    final reg = registers.firstWhere((r) => r.name == name,
        orElse: () => throw ArgumentError('Register "$name" not found'));

    if (reg.readOnly) {
      throw StateError('Register "$name" is read-only');
    }

    final bytes = reg.encode(value);

    switch (reg.type) {
      case RegisterType.coil:
        if (reg.registerCount == 1) {
          await client.writeSingleCoil(slaveId, reg.address, value as bool);
        } else {
          await client.writeMultipleCoils(slaveId, reg.address, reg.registerCount, bytes);
        }
        break;
      case RegisterType.holdingRegister:
        if (reg.registerCount == 1 && reg.dataType == DataType.uint16) {
          await client.writeSingleRegister(slaveId, reg.address, value as int);
        } else {
          await client.writeMultipleRegistersBytes(
              slaveId, reg.address, reg.registerCount, bytes);
        }
        break;
      default:
        throw StateError('Cannot write to ${reg.type}');
    }
  }

  /// Read all registers in the map.
  ///
  /// Returns: Map of register name to value
  Future<Map<String, dynamic>> readAll(ModbusClient client) async {
    final result = <String, dynamic>{};

    for (final reg in registers) {
      try {
        result[reg.name] = await read(client, reg.name);
      } catch (e) {
        result[reg.name] = null; // or rethrow based on your error handling strategy
      }
    }

    return result;
  }

  /// Load register map from JSON string.
  ///
  /// Example JSON format:
  /// ```json
  /// {
  ///   "slaveId": 1,
  ///   "deviceName": "PLC-001",
  ///   "registers": [
  ///     {
  ///       "name": "temperature",
  ///       "address": 100,
  ///       "type": "inputRegister",
  ///       "dataType": "float32",
  ///       "multiplier": 0.1,
  ///       "unit": "°C"
  ///     }
  ///   ]
  /// }
  /// ```
  factory RegisterMap.fromJson(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return RegisterMap(
      slaveId: json['slaveId'] as int,
      deviceName: json['deviceName'] as String?,
      registers: (json['registers'] as List)
          .map((r) => RegisterDefinition.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Convert to JSON string.
  String toJson() {
    return jsonEncode({
      'slaveId': slaveId,
      if (deviceName != null) 'deviceName': deviceName,
      'registers': registers.map((r) => r.toJson()).toList(),
    });
  }
}
