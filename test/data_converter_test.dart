import 'dart:typed_data';
import 'package:test/test.dart';
import '../lib/src/data_converter.dart';

void main() {
  group('16-bit Integer Conversions', () {
    test('bytesToUint16 converts correctly', () {
      final bytes = Uint8List.fromList([0x12, 0x34, 0x56, 0x78]);
      final result = DataConverter.bytesToUint16(bytes);
      expect(result.length, equals(2));
      expect(result[0], equals(0x1234));
      expect(result[1], equals(0x5678));
    });

    test('uint16ToBytes converts correctly', () {
      final values = [0x1234, 0x5678];
      final result = DataConverter.uint16ToBytes(values);
      expect(result, equals([0x12, 0x34, 0x56, 0x78]));
    });

    test('bytesToInt16 handles negative numbers', () {
      final bytes = Uint8List.fromList([0xFF, 0xFF]); // -1
      final result = DataConverter.bytesToInt16(bytes);
      expect(result[0], equals(-1));
    });
  });

  group('32-bit Integer Conversions', () {
    test('bytesToInt32 big endian', () {
      final bytes = Uint8List.fromList([0x12, 0x34, 0x56, 0x78]);
      final result = DataConverter.bytesToInt32(bytes);
      expect(result, equals(0x12345678));
    });

    test('int32ToBytes big endian', () {
      final result = DataConverter.int32ToBytes(0x12345678);
      expect(result, equals([0x12, 0x34, 0x56, 0x78]));
    });

    test('bytesToUint32 big endian', () {
      final bytes = Uint8List.fromList([0xFF, 0xFF, 0xFF, 0xFF]);
      final result = DataConverter.bytesToUint32(bytes);
      expect(result, equals(0xFFFFFFFF));
    });

    test('uint32ToBytes big endian', () {
      final result = DataConverter.uint32ToBytes(0x12345678);
      expect(result, equals([0x12, 0x34, 0x56, 0x78]));
    });
  });

  group('Float Conversions', () {
    test('bytesToFloat32 converts correctly', () {
      // IEEE 754: 25.5 = 0x41CC0000
      final bytes = Uint8List.fromList([0x41, 0xCC, 0x00, 0x00]);
      final result = DataConverter.bytesToFloat32(bytes);
      expect(result, closeTo(25.5, 0.001));
    });

    test('float32ToBytes converts correctly', () {
      final result = DataConverter.float32ToBytes(25.5);
      // IEEE 754: 25.5 = 0x41CC0000
      expect(result[0], equals(0x41));
      expect(result[1], equals(0xCC));
    });

    test('float32 round trip', () {
      final original = 123.456;
      final bytes = DataConverter.float32ToBytes(original);
      final result = DataConverter.bytesToFloat32(bytes);
      expect(result, closeTo(original, 0.001));
    });
  });

  group('String Conversions', () {
    test('bytesToString converts ASCII', () {
      final bytes = Uint8List.fromList([0x48, 0x65, 0x6C, 0x6C, 0x6F]); // "Hello"
      final result = DataConverter.bytesToString(bytes);
      expect(result, equals('Hello'));
    });

    test('bytesToString trims null terminators', () {
      final bytes = Uint8List.fromList([0x48, 0x69, 0x00, 0x00]); // "Hi\0\0"
      final result = DataConverter.bytesToString(bytes, trimNull: true);
      expect(result, equals('Hi'));
    });

    test('stringToBytes converts correctly', () {
      final result = DataConverter.stringToBytes('Hello');
      expect(result, equals([0x48, 0x65, 0x6C, 0x6C, 0x6F]));
    });

    test('stringToBytes pads to fixed length', () {
      final result = DataConverter.stringToBytes('Hi', length: 10);
      expect(result.length, equals(10));
      expect(result[0], equals(0x48)); // 'H'
      expect(result[1], equals(0x69)); // 'i'
      expect(result[2], equals(0x00)); // null padding
    });
  });

  group('Bit Operations', () {
    test('getBit reads correct bit', () {
      final bytes = Uint8List.fromList([0x55]); // 01010101
      expect(DataConverter.getBit(bytes, 0), isTrue);
      expect(DataConverter.getBit(bytes, 1), isFalse);
      expect(DataConverter.getBit(bytes, 2), isTrue);
      expect(DataConverter.getBit(bytes, 3), isFalse);
    });

    test('setBit sets bit correctly', () {
      final bytes = Uint8List.fromList([0x00]);
      DataConverter.setBit(bytes, 0, true);
      expect(bytes[0], equals(0x01));

      DataConverter.setBit(bytes, 7, true);
      expect(bytes[0], equals(0x81));
    });

    test('setBit clears bit correctly', () {
      final bytes = Uint8List.fromList([0xFF]);
      DataConverter.setBit(bytes, 0, false);
      expect(bytes[0], equals(0xFE));

      DataConverter.setBit(bytes, 7, false);
      expect(bytes[0], equals(0x7E));
    });
  });

  group('Byte Order Tests', () {
    test('int32 little endian word swap', () {
      final bytes = Uint8List.fromList([0x12, 0x34, 0x56, 0x78]);
      final result = DataConverter.bytesToInt32(bytes, byteOrder: ByteOrder.littleEndian);
      // Little endian swaps words: [0x56, 0x78, 0x12, 0x34]
      expect(result, equals(0x56781234));
    });

    test('float32 little endian word swap', () {
      final value = 25.5;
      final bytesBE = DataConverter.float32ToBytes(value, byteOrder: ByteOrder.bigEndian);
      final bytesLE = DataConverter.float32ToBytes(value, byteOrder: ByteOrder.littleEndian);

      // Verify word swap
      expect(bytesLE[0], equals(bytesBE[2]));
      expect(bytesLE[1], equals(bytesBE[3]));
      expect(bytesLE[2], equals(bytesBE[0]));
      expect(bytesLE[3], equals(bytesBE[1]));
    });
  });
}
