import 'dart:typed_data';
import 'modbus.dart';
import 'client_provider.dart';
import 'utils.dart';

/// Modbus client interface providing all standard Modbus functions.
///
/// This interface defines the high-level API for Modbus communication,
/// supporting both bit access (coils, discrete inputs) and 16-bit register
/// access (input registers, holding registers).
///
/// Example:
/// ```dart
/// final provider = TCPClientProvider('192.168.1.100:502');
/// final client = ModbusClientImpl(provider);
///
/// await client.connect();
/// final registers = await client.readHoldingRegisters(1, 0, 10);
/// await client.close();
/// ```
abstract class ModbusClient {
  /// Connect to the remote Modbus server.
  ///
  /// Must be called before any read/write operations.
  /// Throws an exception if connection fails.
  Future<void> connect();

  /// Check if client is currently connected to the server.
  ///
  /// Returns `true` if connected, `false` otherwise.
  bool get isConnected;

  /// Close connection to the remote server.
  ///
  /// Should be called when done to free resources.
  Future<void> close();

  // Bit access functions (Function Codes 01, 02, 05, 15)

  /// Read coil status (FC 01).
  ///
  /// Reads from 1 to 2000 contiguous coils in a remote device.
  ///
  /// Parameters:
  /// - [slaveId]: The slave device ID (1-247)
  /// - [address]: Starting address of coils
  /// - [quantity]: Number of coils to read (1-2000)
  ///
  /// Returns: Byte array with coil status (bit-packed)
  ///
  /// Example:
  /// ```dart
  /// final coils = await client.readCoils(1, 0, 10);
  /// final isCoil0On = (coils[0] & 0x01) != 0;
  /// ```
  Future<Uint8List> readCoils(int slaveId, int address, int quantity);

  /// Read discrete input status (FC 02).
  ///
  /// Reads from 1 to 2000 contiguous discrete inputs in a remote device.
  ///
  /// Parameters:
  /// - [slaveId]: The slave device ID (1-247)
  /// - [address]: Starting address of discrete inputs
  /// - [quantity]: Number of inputs to read (1-2000)
  ///
  /// Returns: Byte array with input status (bit-packed)
  Future<Uint8List> readDiscreteInputs(int slaveId, int address, int quantity);

  /// Write single coil (FC 05).
  ///
  /// Writes a single coil to either ON or OFF.
  ///
  /// Parameters:
  /// - [slaveId]: The slave device ID (0-247, 0 for broadcast)
  /// - [address]: Coil address
  /// - [isOn]: `true` for ON (0xFF00), `false` for OFF (0x0000)
  ///
  /// Example:
  /// ```dart
  /// await client.writeSingleCoil(1, 0, true); // Turn on coil 0
  /// ```
  Future<void> writeSingleCoil(int slaveId, int address, bool isOn);

  /// Write multiple coils (FC 15).
  ///
  /// Forces each coil in a sequence to either ON or OFF.
  ///
  /// Parameters:
  /// - [slaveId]: The slave device ID (0-247, 0 for broadcast)
  /// - [address]: Starting address of coils
  /// - [quantity]: Number of coils to write (1-1968)
  /// - [value]: Byte array with coil values (bit-packed)
  ///
  /// Example:
  /// ```dart
  /// final values = Uint8List.fromList([0xFF, 0x00]); // First 8 ON, next 8 OFF
  /// await client.writeMultipleCoils(1, 0, 16, values);
  /// ```
  Future<void> writeMultipleCoils(
      int slaveId, int address, int quantity, Uint8List value);

  // 16-bit register access functions (Function Codes 03, 04, 06, 16, 22, 23, 24)

  /// Read input registers as bytes (FC 04).
  ///
  /// Reads from 1 to 125 contiguous input registers.
  ///
  /// Parameters:
  /// - [slaveId]: The slave device ID (1-247)
  /// - [address]: Starting address of input registers
  /// - [quantity]: Number of registers to read (1-125)
  ///
  /// Returns: Raw bytes (quantity × 2 bytes, big-endian)
  Future<Uint8List> readInputRegistersBytes(
      int slaveId, int address, int quantity);

  /// Read input registers as 16-bit values (FC 04).
  ///
  /// Reads from 1 to 125 contiguous input registers.
  ///
  /// Parameters:
  /// - [slaveId]: The slave device ID (1-247)
  /// - [address]: Starting address of input registers
  /// - [quantity]: Number of registers to read (1-125)
  ///
  /// Returns: List of 16-bit unsigned integers
  ///
  /// Example:
  /// ```dart
  /// final registers = await client.readInputRegisters(1, 0, 5);
  /// print('Register 0: ${registers[0]}');
  /// ```
  Future<Uint16List> readInputRegisters(
      int slaveId, int address, int quantity);

  /// Read holding registers as bytes (FC 03).
  ///
  /// Reads from 1 to 125 contiguous holding registers.
  ///
  /// Parameters:
  /// - [slaveId]: The slave device ID (1-247)
  /// - [address]: Starting address of holding registers
  /// - [quantity]: Number of registers to read (1-125)
  ///
  /// Returns: Raw bytes (quantity × 2 bytes, big-endian)
  Future<Uint8List> readHoldingRegistersBytes(
      int slaveId, int address, int quantity);

  /// Read holding registers as 16-bit values (FC 03).
  ///
  /// Reads from 1 to 125 contiguous holding registers.
  ///
  /// Parameters:
  /// - [slaveId]: The slave device ID (1-247)
  /// - [address]: Starting address of holding registers
  /// - [quantity]: Number of registers to read (1-125)
  ///
  /// Returns: List of 16-bit unsigned integers
  Future<Uint16List> readHoldingRegisters(
      int slaveId, int address, int quantity);

  /// Write single register (FC 06).
  ///
  /// Writes a single 16-bit value to a holding register.
  ///
  /// Parameters:
  /// - [slaveId]: The slave device ID (0-247, 0 for broadcast)
  /// - [address]: Register address
  /// - [value]: 16-bit value to write (0-65535)
  ///
  /// Example:
  /// ```dart
  /// await client.writeSingleRegister(1, 0, 1234);
  /// ```
  Future<void> writeSingleRegister(int slaveId, int address, int value);

  /// Write multiple registers from bytes (FC 16).
  ///
  /// Writes 1 to 123 contiguous holding registers.
  ///
  /// Parameters:
  /// - [slaveId]: The slave device ID (0-247, 0 for broadcast)
  /// - [address]: Starting address of registers
  /// - [quantity]: Number of registers to write (1-123)
  /// - [value]: Raw bytes (must be quantity × 2 bytes, big-endian)
  Future<void> writeMultipleRegistersBytes(
      int slaveId, int address, int quantity, Uint8List value);

  /// Write multiple registers from 16-bit values (FC 16).
  ///
  /// Writes 1 to 123 contiguous holding registers.
  ///
  /// Parameters:
  /// - [slaveId]: The slave device ID (0-247, 0 for broadcast)
  /// - [address]: Starting address of registers
  /// - [quantity]: Number of registers to write (1-123)
  /// - [value]: List of 16-bit values
  ///
  /// Example:
  /// ```dart
  /// final values = Uint16List.fromList([100, 200, 300]);
  /// await client.writeMultipleRegisters(1, 0, 3, values);
  /// ```
  Future<void> writeMultipleRegisters(
      int slaveId, int address, int quantity, Uint16List value);

  /// Read and write multiple registers, returning bytes (FC 23).
  ///
  /// Performs a combined read/write operation in a single transaction.
  ///
  /// Parameters:
  /// - [slaveId]: The slave device ID (1-247)
  /// - [readAddress]: Starting address for read
  /// - [readQuantity]: Number of registers to read (1-125)
  /// - [writeAddress]: Starting address for write
  /// - [writeQuantity]: Number of registers to write (1-121)
  /// - [value]: Bytes to write (must be writeQuantity × 2 bytes)
  ///
  /// Returns: Read register bytes
  Future<Uint8List> readWriteMultipleRegistersBytes(int slaveId,
      int readAddress, int readQuantity, int writeAddress, int writeQuantity, Uint8List value);

  /// Read and write multiple registers, returning 16-bit values (FC 23).
  ///
  /// Performs a combined read/write operation in a single transaction.
  ///
  /// Parameters:
  /// - [slaveId]: The slave device ID (1-247)
  /// - [readAddress]: Starting address for read
  /// - [readQuantity]: Number of registers to read (1-125)
  /// - [writeAddress]: Starting address for write
  /// - [writeQuantity]: Number of registers to write (1-121)
  /// - [value]: Bytes to write (must be writeQuantity × 2 bytes)
  ///
  /// Returns: Read register values
  Future<Uint16List> readWriteMultipleRegisters(int slaveId, int readAddress,
      int readQuantity, int writeAddress, int writeQuantity, Uint8List value);

  /// Mask write register (FC 22).
  ///
  /// Modifies a holding register using AND and OR masks.
  ///
  /// Formula: `Result = (Current AND andMask) OR (orMask AND NOT andMask)`
  ///
  /// Parameters:
  /// - [slaveId]: The slave device ID (0-247, 0 for broadcast)
  /// - [address]: Register address
  /// - [andMask]: AND mask (16-bit)
  /// - [orMask]: OR mask (16-bit)
  ///
  /// Example:
  /// ```dart
  /// // Set bit 0, clear bit 1, leave others unchanged
  /// await client.maskWriteRegister(1, 0, 0xFFFD, 0x0001);
  /// ```
  Future<void> maskWriteRegister(
      int slaveId, int address, int andMask, int orMask);

  /// Read FIFO queue (FC 24).
  ///
  /// Reads the contents of a First-In-First-Out queue of registers.
  ///
  /// Parameters:
  /// - [slaveId]: The slave device ID (1-247)
  /// - [address]: FIFO pointer address
  ///
  /// Returns: FIFO queue contents as bytes (max 31 registers)
  Future<Uint8List> readFIFOQueue(int slaveId, int address);

  /// Send a custom Modbus request.
  ///
  /// Low-level method for sending custom Protocol Data Units.
  ///
  /// Parameters:
  /// - [slaveId]: The slave device ID
  /// - [request]: PDU containing function code and data
  ///
  /// Returns: Response PDU
  Future<ProtocolDataUnit> send(int slaveId, ProtocolDataUnit request);

  /// Send a custom PDU request.
  ///
  /// Low-level method for sending raw PDU bytes.
  ///
  /// Parameters:
  /// - [slaveId]: The slave device ID
  /// - [pduRequest]: Raw PDU bytes (function code + data)
  ///
  /// Returns: Response PDU bytes
  Future<Uint8List> sendPdu(int slaveId, Uint8List pduRequest);

  /// Send a raw ADU frame.
  ///
  /// Lowest-level method for sending raw Application Data Unit frames.
  /// Only use this if you need complete control over the protocol.
  ///
  /// Parameters:
  /// - [aduRequest]: Complete ADU frame (protocol-specific format)
  ///
  /// Returns: Response ADU frame
  Future<Uint8List> sendRawFrame(Uint8List aduRequest);
}

/// Default modbus client implementation
class ModbusClientImpl implements ModbusClient {
  final ClientProvider _provider;
  final int _addressMin;
  final int _addressMax;

  ModbusClientImpl(
    this._provider, {
    int addressMin = addressMin,
    int addressMax = addressMax,
  })  : _addressMin = addressMin,
        _addressMax = addressMax;

  @override
  Future<void> connect() => _provider.connect();

  @override
  bool get isConnected => _provider.isConnected;

  @override
  Future<void> close() => _provider.close();

  @override
  Future<ProtocolDataUnit> send(int slaveId, ProtocolDataUnit request) =>
      _provider.send(slaveId, request);

  @override
  Future<Uint8List> sendPdu(int slaveId, Uint8List pduRequest) =>
      _provider.sendPdu(slaveId, pduRequest);

  @override
  Future<Uint8List> sendRawFrame(Uint8List aduRequest) =>
      _provider.sendRawFrame(aduRequest);

  @override
  Future<Uint8List> readCoils(int slaveId, int address, int quantity) async {
    if (slaveId < _addressMin || slaveId > _addressMax) {
      throw ArgumentError(
          'modbus: slaveId \'$slaveId\' must be between \'$_addressMin\' and \'$_addressMax\'');
    }
    if (quantity < readBitsQuantityMin || quantity > readBitsQuantityMax) {
      throw ArgumentError(
          'modbus: quantity \'$quantity\' must be between \'$readBitsQuantityMin\' and \'$readBitsQuantityMax\'');
    }

    final response = await send(
      slaveId,
      ProtocolDataUnit(
        funcCodeReadCoils,
        uint16ToBytes([address, quantity]),
      ),
    );

    if (response.data.length - 1 != response.data[0]) {
      throw Exception(
          'modbus: response byte size \'${response.data.length - 1}\' does not match count \'${response.data[0]}\'');
    }
    if (response.data[0] != (quantity + 7) ~/ 8) {
      throw Exception(
          'modbus: response byte size \'${response.data[0]}\' does not match quantity to bytes \'${(quantity + 7) ~/ 8}\'');
    }

    return Uint8List.fromList(response.data.sublist(1));
  }

  @override
  Future<Uint8List> readDiscreteInputs(
      int slaveId, int address, int quantity) async {
    if (slaveId < _addressMin || slaveId > _addressMax) {
      throw ArgumentError(
          'modbus: slaveId \'$slaveId\' must be between \'$_addressMin\' and \'$_addressMax\'');
    }
    if (quantity < readBitsQuantityMin || quantity > readBitsQuantityMax) {
      throw ArgumentError(
          'modbus: quantity \'$quantity\' must be between \'$readBitsQuantityMin\' and \'$readBitsQuantityMax\'');
    }

    final response = await send(
      slaveId,
      ProtocolDataUnit(
        funcCodeReadDiscreteInputs,
        uint16ToBytes([address, quantity]),
      ),
    );

    if (response.data.length - 1 != response.data[0]) {
      throw Exception(
          'modbus: response byte size \'${response.data.length - 1}\' does not match count \'${response.data[0]}\'');
    }
    if (response.data[0] != (quantity + 7) ~/ 8) {
      throw Exception(
          'modbus: response byte size \'${response.data[0]}\' does not match quantity to bytes \'${(quantity + 7) ~/ 8}\'');
    }

    return Uint8List.fromList(response.data.sublist(1));
  }

  @override
  Future<void> writeSingleCoil(int slaveId, int address, bool isOn) async {
    if (slaveId > _addressMax) {
      throw ArgumentError(
          'modbus: slaveId \'$slaveId\' must be between \'$addressBroadCast\' and \'$_addressMax\'');
    }

    final value = isOn ? 0xFF00 : 0x0000;
    final response = await send(
      slaveId,
      ProtocolDataUnit(
        funcCodeWriteSingleCoil,
        uint16ToBytes([address, value]),
      ),
    );

    if (response.data.length != 4) {
      throw Exception(
          'modbus: response data size \'${response.data.length}\' does not match expected \'4\'');
    }

    final rspAddress = bytesToUint16(response.data.sublist(0, 2))[0];
    if (rspAddress != address) {
      throw Exception(
          'modbus: response address \'$rspAddress\' does not match request \'$address\'');
    }

    final rspValue = bytesToUint16(response.data.sublist(2, 4))[0];
    if (rspValue != value) {
      throw Exception(
          'modbus: response value \'$rspValue\' does not match request \'$value\'');
    }
  }

  @override
  Future<void> writeMultipleCoils(
      int slaveId, int address, int quantity, Uint8List value) async {
    if (slaveId > _addressMax) {
      throw ArgumentError(
          'modbus: slaveId \'$slaveId\' must be between \'$addressBroadCast\' and \'$_addressMax\'');
    }
    if (quantity < writeBitsQuantityMin || quantity > writeBitsQuantityMax) {
      throw ArgumentError(
          'modbus: quantity \'$quantity\' must be between \'$writeBitsQuantityMin\' and \'$writeBitsQuantityMax\'');
    }
    if (value.length * 8 < quantity) {
      throw ArgumentError(
          'modbus: value bits size \'${value.length * 8}\' does not greater or equal to quantity \'$quantity\'');
    }

    final response = await send(
      slaveId,
      ProtocolDataUnit(
        funcCodeWriteMultipleCoils,
        pduDataBlockSuffix(value, [address, quantity]),
      ),
    );

    if (response.data.length != 4) {
      throw Exception(
          'modbus: response data size \'${response.data.length}\' does not match expected \'4\'');
    }

    final rspAddress = bytesToUint16(response.data.sublist(0, 2))[0];
    if (rspAddress != address) {
      throw Exception(
          'modbus: response address \'$rspAddress\' does not match request \'$address\'');
    }

    final rspQuantity = bytesToUint16(response.data.sublist(2, 4))[0];
    if (rspQuantity != quantity) {
      throw Exception(
          'modbus: response quantity \'$rspQuantity\' does not match request \'$quantity\'');
    }
  }

  @override
  Future<Uint8List> readInputRegistersBytes(
      int slaveId, int address, int quantity) async {
    if (slaveId < _addressMin || slaveId > _addressMax) {
      throw ArgumentError(
          'modbus: slaveId \'$slaveId\' must be between \'$_addressMin\' and \'$_addressMax\'');
    }
    if (quantity < readRegQuantityMin || quantity > readRegQuantityMax) {
      throw ArgumentError(
          'modbus: quantity \'$quantity\' must be between \'$readRegQuantityMin\' and \'$readRegQuantityMax\'');
    }

    final response = await send(
      slaveId,
      ProtocolDataUnit(
        funcCodeReadInputRegisters,
        uint16ToBytes([address, quantity]),
      ),
    );

    if (response.data.length - 1 != response.data[0]) {
      throw Exception(
          'modbus: response data size \'${response.data.length - 1}\' does not match count \'${response.data[0]}\'');
    }
    if (response.data[0] != quantity * 2) {
      throw Exception(
          'modbus: response data size \'${response.data[0]}\' does not match quantity to bytes \'${quantity * 2}\'');
    }

    return Uint8List.fromList(response.data.sublist(1));
  }

  @override
  Future<Uint16List> readInputRegisters(
      int slaveId, int address, int quantity) async {
    final bytes = await readInputRegistersBytes(slaveId, address, quantity);
    return bytesToUint16(bytes);
  }

  @override
  Future<Uint8List> readHoldingRegistersBytes(
      int slaveId, int address, int quantity) async {
    if (slaveId < _addressMin || slaveId > _addressMax) {
      throw ArgumentError(
          'modbus: slaveId \'$slaveId\' must be between \'$_addressMin\' and \'$_addressMax\'');
    }
    if (quantity < readRegQuantityMin || quantity > readRegQuantityMax) {
      throw ArgumentError(
          'modbus: quantity \'$quantity\' must be between \'$readRegQuantityMin\' and \'$readRegQuantityMax\'');
    }

    final response = await send(
      slaveId,
      ProtocolDataUnit(
        funcCodeReadHoldingRegisters,
        uint16ToBytes([address, quantity]),
      ),
    );

    if (response.data.length - 1 != response.data[0]) {
      throw Exception(
          'modbus: response data size \'${response.data.length - 1}\' does not match count \'${response.data[0]}\'');
    }
    if (response.data[0] != quantity * 2) {
      throw Exception(
          'modbus: response data size \'${response.data[0]}\' does not match quantity to bytes \'${quantity * 2}\'');
    }

    return Uint8List.fromList(response.data.sublist(1));
  }

  @override
  Future<Uint16List> readHoldingRegisters(
      int slaveId, int address, int quantity) async {
    final bytes = await readHoldingRegistersBytes(slaveId, address, quantity);
    return bytesToUint16(bytes);
  }

  @override
  Future<void> writeSingleRegister(
      int slaveId, int address, int value) async {
    if (slaveId > _addressMax) {
      throw ArgumentError(
          'modbus: slaveId \'$slaveId\' must be between \'$addressBroadCast\' and \'$_addressMax\'');
    }

    final response = await send(
      slaveId,
      ProtocolDataUnit(
        funcCodeWriteSingleRegister,
        uint16ToBytes([address, value]),
      ),
    );

    if (response.data.length != 4) {
      throw Exception(
          'modbus: response data size \'${response.data.length}\' does not match expected \'4\'');
    }

    final rspAddress = bytesToUint16(response.data.sublist(0, 2))[0];
    if (rspAddress != address) {
      throw Exception(
          'modbus: response address \'$rspAddress\' does not match request \'$address\'');
    }

    final rspValue = bytesToUint16(response.data.sublist(2, 4))[0];
    if (rspValue != value) {
      throw Exception(
          'modbus: response value \'$rspValue\' does not match request \'$value\'');
    }
  }

  @override
  Future<void> writeMultipleRegistersBytes(
      int slaveId, int address, int quantity, Uint8List value) async {
    if (slaveId > _addressMax) {
      throw ArgumentError(
          'modbus: slaveId \'$slaveId\' must be between \'$addressBroadCast\' and \'$_addressMax\'');
    }
    if (quantity < writeRegQuantityMin || quantity > writeRegQuantityMax) {
      throw ArgumentError(
          'modbus: quantity \'$quantity\' must be between \'$writeRegQuantityMin\' and \'$writeRegQuantityMax\'');
    }
    if (value.length != quantity * 2) {
      throw ArgumentError(
          'modbus: value length \'${value.length}\' does not twice as quantity \'$quantity\'');
    }

    final response = await send(
      slaveId,
      ProtocolDataUnit(
        funcCodeWriteMultipleRegisters,
        pduDataBlockSuffix(value, [address, quantity]),
      ),
    );

    if (response.data.length != 4) {
      throw Exception(
          'modbus: response data size \'${response.data.length}\' does not match expected \'4\'');
    }

    final rspAddress = bytesToUint16(response.data.sublist(0, 2))[0];
    if (rspAddress != address) {
      throw Exception(
          'modbus: response address \'$rspAddress\' does not match request \'$address\'');
    }

    final rspQuantity = bytesToUint16(response.data.sublist(2, 4))[0];
    if (rspQuantity != quantity) {
      throw Exception(
          'modbus: response quantity \'$rspQuantity\' does not match request \'$quantity\'');
    }
  }

  @override
  Future<void> writeMultipleRegisters(
      int slaveId, int address, int quantity, Uint16List value) async {
    await writeMultipleRegistersBytes(
        slaveId, address, quantity, uint16ToBytes(value));
  }

  @override
  Future<void> maskWriteRegister(
      int slaveId, int address, int andMask, int orMask) async {
    if (slaveId > _addressMax) {
      throw ArgumentError(
          'modbus: slaveId \'$slaveId\' must be between \'$addressBroadCast\' and \'$_addressMax\'');
    }

    final response = await send(
      slaveId,
      ProtocolDataUnit(
        funcCodeMaskWriteRegister,
        uint16ToBytes([address, andMask, orMask]),
      ),
    );

    if (response.data.length != 6) {
      throw Exception(
          'modbus: response data size \'${response.data.length}\' does not match expected \'6\'');
    }

    final rspAddress = bytesToUint16(response.data.sublist(0, 2))[0];
    if (rspAddress != address) {
      throw Exception(
          'modbus: response address \'$rspAddress\' does not match request \'$address\'');
    }

    final rspAndMask = bytesToUint16(response.data.sublist(2, 4))[0];
    if (rspAndMask != andMask) {
      throw Exception(
          'modbus: response AND-mask \'$rspAndMask\' does not match request \'$andMask\'');
    }

    final rspOrMask = bytesToUint16(response.data.sublist(4, 6))[0];
    if (rspOrMask != orMask) {
      throw Exception(
          'modbus: response OR-mask \'$rspOrMask\' does not match request \'$orMask\'');
    }
  }

  @override
  Future<Uint8List> readWriteMultipleRegistersBytes(
      int slaveId,
      int readAddress,
      int readQuantity,
      int writeAddress,
      int writeQuantity,
      Uint8List value) async {
    if (slaveId < _addressMin || slaveId > _addressMax) {
      throw ArgumentError(
          'modbus: slaveId \'$slaveId\' must be between \'$_addressMin\' and \'$_addressMax\'');
    }
    if (readQuantity < readWriteOnReadRegQuantityMin ||
        readQuantity > readWriteOnReadRegQuantityMax) {
      throw ArgumentError(
          'modbus: quantity to read \'$readQuantity\' must be between \'$readWriteOnReadRegQuantityMin\' and \'$readWriteOnReadRegQuantityMax\'');
    }
    if (writeQuantity < readWriteOnWriteRegQuantityMin ||
        writeQuantity > readWriteOnWriteRegQuantityMax) {
      throw ArgumentError(
          'modbus: quantity to write \'$writeQuantity\' must be between \'$readWriteOnWriteRegQuantityMin\' and \'$readWriteOnWriteRegQuantityMax\'');
    }
    if (value.length != writeQuantity * 2) {
      throw ArgumentError(
          'modbus: value length \'${value.length}\' does not twice as write quantity \'$writeQuantity\'');
    }

    final response = await send(
      slaveId,
      ProtocolDataUnit(
        funcCodeReadWriteMultipleRegisters,
        pduDataBlockSuffix(
            value, [readAddress, readQuantity, writeAddress, writeQuantity]),
      ),
    );

    if (response.data[0] != response.data.length - 1) {
      throw Exception(
          'modbus: response data size \'${response.data.length - 1}\' does not match count \'${response.data[0]}\'');
    }

    return Uint8List.fromList(response.data.sublist(1));
  }

  @override
  Future<Uint16List> readWriteMultipleRegisters(
      int slaveId,
      int readAddress,
      int readQuantity,
      int writeAddress,
      int writeQuantity,
      Uint8List value) async {
    final bytes = await readWriteMultipleRegistersBytes(
        slaveId, readAddress, readQuantity, writeAddress, writeQuantity, value);
    return bytesToUint16(bytes);
  }

  @override
  Future<Uint8List> readFIFOQueue(int slaveId, int address) async {
    if (slaveId < _addressMin || slaveId > _addressMax) {
      throw ArgumentError(
          'modbus: slaveId \'$slaveId\' must be between \'$_addressMin\' and \'$_addressMax\'');
    }

    final response = await send(
      slaveId,
      ProtocolDataUnit(
        funcCodeReadFIFOQueue,
        uint16ToBytes([address]),
      ),
    );

    if (response.data.length < 4) {
      throw Exception(
          'modbus: response data size \'${response.data.length}\' is less than expected \'4\'');
    }

    final count = bytesToUint16(response.data.sublist(0, 2))[0];
    if (response.data.length - 2 != count) {
      throw Exception(
          'modbus: response data size \'${response.data.length - 2}\' does not match count \'$count\'');
    }

    final fifoCount = bytesToUint16(response.data.sublist(2, 4))[0];
    if (fifoCount > 31) {
      throw Exception(
          'modbus: fifo count \'$fifoCount\' is greater than expected \'31\'');
    }

    return Uint8List.fromList(response.data.sublist(4));
  }
}
