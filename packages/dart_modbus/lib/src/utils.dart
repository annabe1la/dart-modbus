import 'dart:typed_data';
import 'modbus.dart';

/// Convert uint16 values to bytes (big endian)
Uint8List uint16ToBytes(List<int> values) {
  final data = Uint8List(values.length * 2);
  final byteData = ByteData.sublistView(data);
  for (int i = 0; i < values.length; i++) {
    byteData.setUint16(i * 2, values[i], Endian.big);
  }
  return data;
}

/// Convert bytes to uint16 values (big endian)
Uint16List bytesToUint16(List<int> bytes) {
  final result = Uint16List(bytes.length ~/ 2);
  final byteData = ByteData.sublistView(Uint8List.fromList(bytes));
  for (int i = 0; i < result.length; i++) {
    result[i] = byteData.getUint16(i * 2, Endian.big);
  }
  return result;
}

/// Create PDU data block with suffix
List<int> pduDataBlockSuffix(List<int> suffix, List<int> values) {
  final data = <int>[];

  for (final v in values) {
    data.add((v >> 8) & 0xFF);
    data.add(v & 0xFF);
  }

  data.add(suffix.length);
  data.addAll(suffix);

  return data;
}

/// Create modbus exception error from response PDU
Exception responseError(ProtocolDataUnit response) {
  if (response.data.isNotEmpty) {
    return ModbusException(response.data[0]);
  }
  return ModbusException(0);
}
