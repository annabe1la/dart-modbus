import 'package:test/test.dart';
import '../lib/src/lrc.dart';

void main() {
  group('LRC Tests', () {
    test('LRC calculates correct checksum for empty data', () {
      final lrc = LRC()..reset();
      expect(lrc.value, equals(0x00));
    });

    test('LRC calculates correct checksum for simple data', () {
      // Example: slave=1, fc=3, addr=0x0000, qty=0x000A
      final lrc = LRC()
        ..reset()
        ..push([0x01, 0x03, 0x00, 0x00, 0x00, 0x0A]);
      // LRC = -(sum) & 0xFF = -(0x0E) & 0xFF = 0xF2
      expect(lrc.value, equals(0xF2));
    });

    test('LRC can be reset and reused', () {
      final lrc = LRC();

      lrc.reset().push([0x01, 0x02, 0x03]);
      final value1 = lrc.value;

      lrc.reset().push([0x04, 0x05, 0x06]);
      final value2 = lrc.value;

      expect(value1, isNot(equals(value2)));
    });

    test('LRC push method can be chained', () {
      final lrc = LRC()
        ..reset()
        ..push([0x01])
        ..push([0x02])
        ..push([0x03]);

      final lrc2 = LRC()
        ..reset()
        ..push([0x01, 0x02, 0x03]);

      expect(lrc.value, equals(lrc2.value));
    });

    test('LRC calculation matches known values', () {
      // Example calculation
      final lrc = LRC()
        ..reset()
        ..push([0x01, 0x03, 0x00, 0x6B, 0x00, 0x03]);
      // Sum = 0x01 + 0x03 + 0x00 + 0x6B + 0x00 + 0x03 = 0x72
      // LRC = -(0x72) & 0xFF = 0x8E
      expect(lrc.value, equals(0x8E)); // Actual calculated value
    });
  });
}
