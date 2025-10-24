import 'dart:typed_data';
import 'package:test/test.dart';
import '../lib/src/crc.dart';

void main() {
  group('CRC16 Tests', () {
    test('CRC16 calculates correct checksum for empty data', () {
      final data = Uint8List(0);
      expect(crc16(data), equals(0xFFFF));
    });

    test('CRC16 calculates correct checksum for simple data', () {
      // Example from Modbus specification
      final data = Uint8List.fromList([0x01, 0x03, 0x00, 0x00, 0x00, 0x0A]);
      final result = crc16(data);
      // CRC is little-endian in frame, but we return as uint16
      expect(result, equals(0xCDC5)); // Actual calculated value
    });

    test('CRC16 calculates correct checksum for read coils request', () {
      // Read coils: slave=1, address=19, quantity=19
      final data = Uint8List.fromList([0x01, 0x01, 0x00, 0x13, 0x00, 0x13]);
      final result = crc16(data);
      expect(result, equals(0x028C)); // Actual calculated value
    });

    test('CRC16 calculates correct checksum for write register request', () {
      // Write register: slave=1, address=0, value=0x0003
      final data = Uint8List.fromList([0x01, 0x06, 0x00, 0x00, 0x00, 0x03]);
      final result = crc16(data);
      expect(result, equals(0xCBC9)); // Actual calculated value
    });

    test('CRC16 is consistent', () {
      final data = Uint8List.fromList([0x12, 0x34, 0x56, 0x78]);
      final result1 = crc16(data);
      final result2 = crc16(data);
      expect(result1, equals(result2));
    });
  });
}
