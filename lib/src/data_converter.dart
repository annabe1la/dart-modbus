import 'dart:typed_data';

/// Data type conversion utilities for Modbus registers.
///
/// Modbus registers are 16-bit (2 bytes), but often represent larger data types
/// like 32-bit integers, floats, or strings. This class provides utilities for
/// converting between register arrays and various data types.
///
/// Example:
/// ```dart
/// // Read temperature as Float32
/// final bytes = await client.readHoldingRegistersBytes(1, 100, 2);
/// final temp = DataConverter.bytesToFloat32(bytes);
///
/// // Write setpoint as Float32
/// final setpoint = 25.5;
/// final data = DataConverter.float32ToBytes(setpoint);
/// await client.writeMultipleRegistersBytes(1, 200, 2, data);
/// ```
class DataConverter {
  // 16-bit Integer Conversions

  /// Convert bytes to unsigned 16-bit integers.
  ///
  /// Parameters:
  /// - [bytes]: Byte array (must be even length)
  ///
  /// Returns: List of 16-bit unsigned integers
  static Uint16List bytesToUint16(Uint8List bytes) {
    final result = Uint16List(bytes.length ~/ 2);
    final byteData = ByteData.sublistView(bytes);
    for (int i = 0; i < result.length; i++) {
      result[i] = byteData.getUint16(i * 2, Endian.big);
    }
    return result;
  }

  /// Convert unsigned 16-bit integers to bytes.
  ///
  /// Parameters:
  /// - [values]: List of 16-bit unsigned integers
  ///
  /// Returns: Byte array (big-endian)
  static Uint8List uint16ToBytes(List<int> values) {
    final data = Uint8List(values.length * 2);
    final byteData = ByteData.sublistView(data);
    for (int i = 0; i < values.length; i++) {
      byteData.setUint16(i * 2, values[i], Endian.big);
    }
    return data;
  }

  /// Convert bytes to signed 16-bit integers.
  ///
  /// Parameters:
  /// - [bytes]: Byte array (must be even length)
  ///
  /// Returns: List of 16-bit signed integers
  static Int16List bytesToInt16(Uint8List bytes) {
    final result = Int16List(bytes.length ~/ 2);
    final byteData = ByteData.sublistView(bytes);
    for (int i = 0; i < result.length; i++) {
      result[i] = byteData.getInt16(i * 2, Endian.big);
    }
    return result;
  }

  /// Convert signed 16-bit integers to bytes.
  ///
  /// Parameters:
  /// - [values]: List of 16-bit signed integers
  ///
  /// Returns: Byte array (big-endian)
  static Uint8List int16ToBytes(List<int> values) {
    final data = Uint8List(values.length * 2);
    final byteData = ByteData.sublistView(data);
    for (int i = 0; i < values.length; i++) {
      byteData.setInt16(i * 2, values[i], Endian.big);
    }
    return data;
  }

  // 32-bit Integer Conversions

  /// Convert bytes to signed 32-bit integer (Int32).
  ///
  /// Parameters:
  /// - [bytes]: 4 bytes in big-endian format
  /// - [byteOrder]: Word order (default: [ByteOrder.bigEndian])
  ///
  /// Returns: Signed 32-bit integer (-2147483648 to 2147483647)
  ///
  /// Example:
  /// ```dart
  /// final bytes = Uint8List.fromList([0x00, 0x00, 0x04, 0xD2]); // 1234
  /// final value = DataConverter.bytesToInt32(bytes); // 1234
  /// ```
  static int bytesToInt32(Uint8List bytes, {ByteOrder byteOrder = ByteOrder.bigEndian}) {
    if (bytes.length < 4) {
      throw ArgumentError('Requires at least 4 bytes for Int32');
    }
    final data = ByteData.sublistView(bytes);
    if (byteOrder == ByteOrder.bigEndian) {
      return data.getInt32(0, Endian.big);
    } else {
      // Little endian (swap words)
      final high = data.getUint16(2, Endian.big);
      final low = data.getUint16(0, Endian.big);
      final result = ByteData(4);
      result.setUint16(0, high, Endian.big);
      result.setUint16(2, low, Endian.big);
      return result.getInt32(0, Endian.big);
    }
  }

  /// Convert signed 32-bit integer to bytes.
  ///
  /// Parameters:
  /// - [value]: Signed 32-bit integer
  /// - [byteOrder]: Word order (default: [ByteOrder.bigEndian])
  ///
  /// Returns: 4 bytes in big-endian format
  ///
  /// Example:
  /// ```dart
  /// final bytes = DataConverter.int32ToBytes(1234);
  /// // [0x00, 0x00, 0x04, 0xD2]
  /// ```
  static Uint8List int32ToBytes(int value, {ByteOrder byteOrder = ByteOrder.bigEndian}) {
    final data = ByteData(4);
    if (byteOrder == ByteOrder.bigEndian) {
      data.setInt32(0, value, Endian.big);
    } else {
      // Little endian (swap words)
      data.setInt32(0, value, Endian.big);
      final high = data.getUint16(0, Endian.big);
      final low = data.getUint16(2, Endian.big);
      data.setUint16(0, low, Endian.big);
      data.setUint16(2, high, Endian.big);
    }
    return data.buffer.asUint8List();
  }

  /// Convert bytes to unsigned 32-bit integer (UInt32).
  ///
  /// Parameters:
  /// - [bytes]: 4 bytes in big-endian format
  /// - [byteOrder]: Word order (default: [ByteOrder.bigEndian])
  ///
  /// Returns: Unsigned 32-bit integer (0 to 4294967295)
  static int bytesToUint32(Uint8List bytes, {ByteOrder byteOrder = ByteOrder.bigEndian}) {
    if (bytes.length < 4) {
      throw ArgumentError('Requires at least 4 bytes for UInt32');
    }
    final data = ByteData.sublistView(bytes);
    if (byteOrder == ByteOrder.bigEndian) {
      return data.getUint32(0, Endian.big);
    } else {
      final high = data.getUint16(2, Endian.big);
      final low = data.getUint16(0, Endian.big);
      final result = ByteData(4);
      result.setUint16(0, high, Endian.big);
      result.setUint16(2, low, Endian.big);
      return result.getUint32(0, Endian.big);
    }
  }

  /// Convert unsigned 32-bit integer to bytes.
  ///
  /// Parameters:
  /// - [value]: Unsigned 32-bit integer
  /// - [byteOrder]: Word order (default: [ByteOrder.bigEndian])
  ///
  /// Returns: 4 bytes in big-endian format
  static Uint8List uint32ToBytes(int value, {ByteOrder byteOrder = ByteOrder.bigEndian}) {
    final data = ByteData(4);
    if (byteOrder == ByteOrder.bigEndian) {
      data.setUint32(0, value, Endian.big);
    } else {
      data.setUint32(0, value, Endian.big);
      final high = data.getUint16(0, Endian.big);
      final low = data.getUint16(2, Endian.big);
      data.setUint16(0, low, Endian.big);
      data.setUint16(2, high, Endian.big);
    }
    return data.buffer.asUint8List();
  }

  // Floating Point Conversions

  /// Convert bytes to 32-bit float (Float32/Single).
  ///
  /// Parameters:
  /// - [bytes]: 4 bytes in big-endian format
  /// - [byteOrder]: Word order (default: [ByteOrder.bigEndian])
  ///
  /// Returns: 32-bit floating point number
  ///
  /// Example:
  /// ```dart
  /// final bytes = await client.readHoldingRegistersBytes(1, 100, 2);
  /// final temperature = DataConverter.bytesToFloat32(bytes);
  /// print('Temperature: $temperature °C');
  /// ```
  static double bytesToFloat32(Uint8List bytes, {ByteOrder byteOrder = ByteOrder.bigEndian}) {
    if (bytes.length < 4) {
      throw ArgumentError('Requires at least 4 bytes for Float32');
    }
    final data = ByteData.sublistView(bytes);
    if (byteOrder == ByteOrder.bigEndian) {
      return data.getFloat32(0, Endian.big);
    } else {
      final high = data.getUint16(2, Endian.big);
      final low = data.getUint16(0, Endian.big);
      final result = ByteData(4);
      result.setUint16(0, high, Endian.big);
      result.setUint16(2, low, Endian.big);
      return result.getFloat32(0, Endian.big);
    }
  }

  /// Convert 32-bit float to bytes.
  ///
  /// Parameters:
  /// - [value]: 32-bit floating point number
  /// - [byteOrder]: Word order (default: [ByteOrder.bigEndian])
  ///
  /// Returns: 4 bytes in big-endian format
  ///
  /// Example:
  /// ```dart
  /// final setpoint = 25.5;
  /// final bytes = DataConverter.float32ToBytes(setpoint);
  /// await client.writeMultipleRegistersBytes(1, 200, 2, bytes);
  /// ```
  static Uint8List float32ToBytes(double value, {ByteOrder byteOrder = ByteOrder.bigEndian}) {
    final data = ByteData(4);
    if (byteOrder == ByteOrder.bigEndian) {
      data.setFloat32(0, value, Endian.big);
    } else {
      data.setFloat32(0, value, Endian.big);
      final high = data.getUint16(0, Endian.big);
      final low = data.getUint16(2, Endian.big);
      data.setUint16(0, low, Endian.big);
      data.setUint16(2, high, Endian.big);
    }
    return data.buffer.asUint8List();
  }

  /// Convert bytes to 64-bit double (Float64/Double).
  ///
  /// Parameters:
  /// - [bytes]: 8 bytes in big-endian format
  /// - [byteOrder]: Word order (default: [ByteOrder.bigEndian])
  ///
  /// Returns: 64-bit floating point number
  static double bytesToFloat64(Uint8List bytes, {ByteOrder byteOrder = ByteOrder.bigEndian}) {
    if (bytes.length < 8) {
      throw ArgumentError('Requires at least 8 bytes for Float64');
    }
    final data = ByteData.sublistView(bytes);
    if (byteOrder == ByteOrder.bigEndian) {
      return data.getFloat64(0, Endian.big);
    } else {
      // Swap all 4 words for little endian
      final result = ByteData(8);
      for (int i = 0; i < 4; i++) {
        result.setUint16(i * 2, data.getUint16((3 - i) * 2, Endian.big), Endian.big);
      }
      return result.getFloat64(0, Endian.big);
    }
  }

  /// Convert 64-bit double to bytes.
  ///
  /// Parameters:
  /// - [value]: 64-bit floating point number
  /// - [byteOrder]: Word order (default: [ByteOrder.bigEndian])
  ///
  /// Returns: 8 bytes in big-endian format
  static Uint8List float64ToBytes(double value, {ByteOrder byteOrder = ByteOrder.bigEndian}) {
    final data = ByteData(8);
    if (byteOrder == ByteOrder.bigEndian) {
      data.setFloat64(0, value, Endian.big);
    } else {
      data.setFloat64(0, value, Endian.big);
      final result = ByteData(8);
      for (int i = 0; i < 4; i++) {
        result.setUint16(i * 2, data.getUint16((3 - i) * 2, Endian.big), Endian.big);
      }
      return result.buffer.asUint8List();
    }
    return data.buffer.asUint8List();
  }

  // String Conversions

  /// Convert bytes to ASCII string.
  ///
  /// Parameters:
  /// - [bytes]: Byte array containing ASCII characters
  /// - [trimNull]: Remove null terminators (default: true)
  ///
  /// Returns: ASCII string
  ///
  /// Example:
  /// ```dart
  /// final bytes = await client.readHoldingRegistersBytes(1, 300, 10);
  /// final deviceName = DataConverter.bytesToString(bytes);
  /// ```
  static String bytesToString(Uint8List bytes, {bool trimNull = true}) {
    if (trimNull) {
      final nullIndex = bytes.indexOf(0);
      if (nullIndex >= 0) {
        bytes = bytes.sublist(0, nullIndex);
      }
    }
    return String.fromCharCodes(bytes);
  }

  /// Convert string to bytes.
  ///
  /// Parameters:
  /// - [value]: String to convert
  /// - [length]: Fixed length (pads with nulls if needed)
  ///
  /// Returns: Byte array with ASCII characters
  ///
  /// Example:
  /// ```dart
  /// final deviceName = 'PLC-001';
  /// final bytes = DataConverter.stringToBytes(deviceName, length: 20);
  /// await client.writeMultipleRegistersBytes(1, 300, 10, bytes);
  /// ```
  static Uint8List stringToBytes(String value, {int? length}) {
    final codeUnits = value.codeUnits;
    if (length == null) {
      return Uint8List.fromList(codeUnits);
    }
    final result = Uint8List(length);
    final copyLength = codeUnits.length > length ? length : codeUnits.length;
    result.setRange(0, copyLength, codeUnits);
    return result;
  }

  // Bit Operations

  /// Get specific bit from byte array.
  ///
  /// Parameters:
  /// - [bytes]: Byte array
  /// - [bitIndex]: Bit index (0-based)
  ///
  /// Returns: true if bit is set, false otherwise
  ///
  /// Example:
  /// ```dart
  /// final coils = await client.readCoils(1, 0, 16);
  /// final isCoil5On = DataConverter.getBit(coils, 5);
  /// ```
  static bool getBit(Uint8List bytes, int bitIndex) {
    final byteIndex = bitIndex ~/ 8;
    final bitOffset = bitIndex % 8;
    if (byteIndex >= bytes.length) {
      throw RangeError('Bit index $bitIndex out of range');
    }
    return (bytes[byteIndex] & (1 << bitOffset)) != 0;
  }

  /// Set specific bit in byte array.
  ///
  /// Parameters:
  /// - [bytes]: Byte array
  /// - [bitIndex]: Bit index (0-based)
  /// - [value]: true to set bit, false to clear bit
  ///
  /// Example:
  /// ```dart
  /// final coils = Uint8List(2);
  /// DataConverter.setBit(coils, 5, true);
  /// await client.writeMultipleCoils(1, 0, 16, coils);
  /// ```
  static void setBit(Uint8List bytes, int bitIndex, bool value) {
    final byteIndex = bitIndex ~/ 8;
    final bitOffset = bitIndex % 8;
    if (byteIndex >= bytes.length) {
      throw RangeError('Bit index $bitIndex out of range');
    }
    if (value) {
      bytes[byteIndex] |= (1 << bitOffset);
    } else {
      bytes[byteIndex] &= ~(1 << bitOffset);
    }
  }
}

/// Byte order for multi-register data types.
enum ByteOrder {
  /// Big endian (ABCD) - High word first
  bigEndian,

  /// Little endian (DCBA) - Low word first
  littleEndian,
}
