import 'dart:io';
import 'package:yaml/yaml.dart';
import 'register_map.dart';
import 'data_converter.dart';

/// Point table configuration loaded from YAML
class PointTableConfig {
  final String name;
  final int slaveId;
  final String protocol; // 'tcp' or 'rtu' or 'ascii'
  final String? address; // For TCP: "host:port", For serial: "/dev/ttyUSB0"
  final Map<String, dynamic>? serialConfig; // For serial: baudRate, parity, etc.
  final List<RegisterDefinition> registers;
  final int? pollInterval; // Milliseconds

  PointTableConfig({
    required this.name,
    required this.slaveId,
    required this.protocol,
    this.address,
    this.serialConfig,
    required this.registers,
    this.pollInterval,
  });

  /// Load from YAML file
  static Future<PointTableConfig> fromFile(String filePath) async {
    final file = File(filePath);
    final yamlString = await file.readAsString();
    final yaml = loadYaml(yamlString);
    return fromYaml(yaml);
  }

  /// Load from YAML object
  static PointTableConfig fromYaml(dynamic yaml) {
    final registers = <RegisterDefinition>[];

    for (final regYaml in yaml['registers'] as YamlList) {
      final reg = regYaml as YamlMap;

      registers.add(RegisterDefinition(
        name: reg['name'] as String,
        address: reg['address'] as int,
        type: RegisterType.values.byName(reg['type'] as String),
        dataType: reg['dataType'] != null
            ? DataType.values.byName(reg['dataType'] as String)
            : DataType.uint16,
        quantity: reg['quantity'] as int?,
        byteOrder: reg['byteOrder'] != null
            ? ByteOrder.values.byName(reg['byteOrder'] as String)
            : ByteOrder.bigEndian,
        multiplier: reg['multiplier'] != null
            ? (reg['multiplier'] as num).toDouble()
            : null,
        offset:
            reg['offset'] != null ? (reg['offset'] as num).toDouble() : null,
        unit: reg['unit'] as String?,
        description: reg['description'] as String?,
        readOnly: reg['readOnly'] as bool? ?? false,
      ));
    }

    return PointTableConfig(
      name: yaml['name'] as String,
      slaveId: yaml['slaveId'] as int,
      protocol: yaml['protocol'] as String,
      address: yaml['address'] as String?,
      serialConfig: yaml['serialConfig'] != null
          ? Map<String, dynamic>.from(yaml['serialConfig'] as YamlMap)
          : null,
      registers: registers,
      pollInterval: yaml['pollInterval'] as int?,
    );
  }

  /// Convert to RegisterMap
  RegisterMap toRegisterMap() {
    return RegisterMap(
      slaveId: slaveId,
      deviceName: name,
      registers: registers,
    );
  }
}

/// Random value generator based on data type
class RandomValueGenerator {
  static final _random = DateTime.now().millisecondsSinceEpoch;
  static int _seed = _random;

  /// Generate random value for a data type
  static dynamic generateValue(DataType dataType) {
    _seed = (_seed * 1103515245 + 12345) & 0x7FFFFFFF;
    final rand = _seed / 0x7FFFFFFF;

    switch (dataType) {
      case DataType.uint16:
        return (_seed & 0xFFFF);
      case DataType.int16:
        return ((_seed & 0xFFFF) - 32768);
      case DataType.uint32:
        return _seed & 0xFFFFFFFF;
      case DataType.int32:
        return (_seed & 0xFFFFFFFF) - 0x7FFFFFFF;
      case DataType.float32:
        return rand * 100.0;
      case DataType.float64:
        return rand * 1000.0;
      case DataType.bool:
        return (_seed & 1) == 1;
      case DataType.string:
        final chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
        final length = 8 + (_seed % 8);
        return List.generate(
                length, (i) => chars[(_seed + i * 17) % chars.length])
            .join();
    }
  }

  /// Generate random value in range
  static double generateInRange(double min, double max) {
    _seed = (_seed * 1103515245 + 12345) & 0x7FFFFFFF;
    final rand = _seed / 0x7FFFFFFF;
    return min + (max - min) * rand;
  }
}
