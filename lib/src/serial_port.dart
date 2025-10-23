import 'dart:typed_data';

/// Abstract serial port interface
/// Users should implement this interface using platform-specific libraries
/// such as flutter_libserialport or dart_serial_port
abstract class SerialPort {
  /// Open the serial port
  Future<void> open();

  /// Close the serial port
  Future<void> close();

  /// Check if the port is open
  bool get isOpen;

  /// Write data to the serial port
  Future<void> write(Uint8List data);

  /// Read data from the serial port
  Future<Uint8List> read(int length);

  /// Read data until a specific pattern is found
  Future<Uint8List> readUntil(List<int> pattern, {int? maxLength});
}

/// Serial port configuration
class SerialConfig {
  final String portName;
  final int baudRate;
  final int dataBits;
  final int stopBits;
  final String parity; // 'N', 'E', 'O'
  final Duration timeout;

  const SerialConfig({
    required this.portName,
    this.baudRate = 19200,
    this.dataBits = 8,
    this.stopBits = 1,
    this.parity = 'N',
    this.timeout = const Duration(seconds: 1),
  });
}
