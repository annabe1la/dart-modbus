import 'dart:typed_data';
import 'modbus.dart';
import 'client_provider.dart';
import 'crc.dart';
import 'serial_port.dart';
import 'utils.dart';

const _rtuExceptionSize = 5;

/// RTU client provider for Modbus RTU
class RTUClientProvider implements ClientProvider {
  final SerialPort _port;
  final SerialConfig _config;

  RTUClientProvider(this._port, this._config);

  @override
  Future<void> connect() => _port.open();

  @override
  bool get isConnected => _port.isOpen;

  @override
  Future<void> close() => _port.close();

  @override
  Future<ProtocolDataUnit> send(int slaveId, ProtocolDataUnit request) async {
    final aduRequest = _encodeRTUFrame(slaveId, request);
    final aduResponse = await sendRawFrame(aduRequest);
    final (rspSlaveId, pdu) = _decodeRTUFrame(aduResponse);
    final response = ProtocolDataUnit(pdu[0], pdu.sublist(1));

    _verify(slaveId, rspSlaveId, request, response);
    return response;
  }

  @override
  Future<Uint8List> sendPdu(int slaveId, Uint8List pduRequest) async {
    if (pduRequest.length < pduMinSize || pduRequest.length > pduMaxSize) {
      throw ArgumentError(
          'modbus: pdu size \'${pduRequest.length}\' must be between \'$pduMinSize\' and \'$pduMaxSize\'');
    }

    final request = ProtocolDataUnit(pduRequest[0], pduRequest.sublist(1));
    final aduRequest = _encodeRTUFrame(slaveId, request);
    final aduResponse = await sendRawFrame(aduRequest);
    final (rspSlaveId, pdu) = _decodeRTUFrame(aduResponse);
    final response = ProtocolDataUnit(pdu[0], pdu.sublist(1));

    _verify(slaveId, rspSlaveId, request, response);
    return pdu;
  }

  @override
  Future<Uint8List> sendRawFrame(Uint8List aduRequest) async {
    if (!isConnected) {
      await connect();
    }

    await _port.write(aduRequest);

    final function = aduRequest[1];
    final functionFail = (aduRequest[1] | 0x80) & 0xFF;
    final bytesToRead = _calculateResponseLength(aduRequest);

    // Add delay based on baud rate
    await Future.delayed(_calculateDelay(aduRequest.length + bytesToRead));

    // Read minimum length first
    final minData = await _port.read(rtuAduMinSize);

    if (minData[1] == function) {
      // Function is correct, read the rest
      if (bytesToRead > rtuAduMinSize) {
        final remaining = bytesToRead - minData.length;
        if (remaining > 0) {
          final restData = await _port.read(remaining);
          return Uint8List.fromList([...minData, ...restData]);
        }
      }
      return minData;
    } else if (minData[1] == functionFail) {
      // Error response, read 5 bytes total
      if (minData.length < _rtuExceptionSize) {
        final remaining = _rtuExceptionSize - minData.length;
        final restData = await _port.read(remaining);
        return Uint8List.fromList([...minData, ...restData]);
      }
      return minData;
    } else {
      throw Exception('modbus: unknown function code ${minData[1]}');
    }
  }

  Uint8List _encodeRTUFrame(int slaveId, ProtocolDataUnit pdu) {
    final length = pdu.data.length + 4;
    if (length > rtuAduMaxSize) {
      throw ArgumentError(
          'modbus: length of data \'$length\' must not be bigger than \'$rtuAduMaxSize\'');
    }

    final adu = Uint8List(length);
    adu[0] = slaveId;
    adu[1] = pdu.funcCode;
    adu.setRange(2, length - 2, pdu.data);

    final checksum = crc16(adu.sublist(0, length - 2));
    adu[length - 2] = checksum & 0xFF;
    adu[length - 1] = (checksum >> 8) & 0xFF;

    return adu;
  }

  (int, Uint8List) _decodeRTUFrame(Uint8List adu) {
    if (adu.length < rtuAduMinSize) {
      throw Exception(
          'modbus: response length \'${adu.length}\' does not meet minimum \'$rtuAduMinSize\'');
    }

    // Verify CRC
    final crcData = adu.sublist(0, adu.length - 2);
    final crcExpected = adu[adu.length - 2] | (adu[adu.length - 1] << 8);
    final crcActual = crc16(crcData);

    if (crcActual != crcExpected) {
      throw Exception(
          'modbus: response crc \'${crcExpected.toRadixString(16)}\' does not match expected \'${crcActual.toRadixString(16)}\'');
    }

    return (adu[0], adu.sublist(1, adu.length - 2));
  }

  void _verify(int reqSlaveId, int rspSlaveId, ProtocolDataUnit reqPDU,
      ProtocolDataUnit rspPDU) {
    if (reqSlaveId != rspSlaveId) {
      throw Exception(
          'modbus: response slave id \'$rspSlaveId\' does not match request \'$reqSlaveId\'');
    }

    if (rspPDU.funcCode != reqPDU.funcCode) {
      throw responseError(rspPDU);
    }

    if (rspPDU.data.isEmpty) {
      throw Exception('modbus: response data is empty');
    }
  }

  Duration _calculateDelay(int chars) {
    int characterDelay, frameDelay; // microseconds

    if (_config.baudRate <= 0 || _config.baudRate > 19200) {
      characterDelay = 750;
      frameDelay = 1750;
    } else {
      characterDelay = 15000000 ~/ _config.baudRate;
      frameDelay = 35000000 ~/ _config.baudRate;
    }

    return Duration(microseconds: characterDelay * chars + frameDelay);
  }

  int _calculateResponseLength(Uint8List adu) {
    int length = rtuAduMinSize;
    final funcCode = adu[1];

    switch (funcCode) {
      case funcCodeReadDiscreteInputs:
      case funcCodeReadCoils:
        final count =
            ByteData.sublistView(adu).getUint16(4, Endian.big);
        length += 1 + count ~/ 8;
        if (count % 8 != 0) {
          length++;
        }
        break;

      case funcCodeReadInputRegisters:
      case funcCodeReadHoldingRegisters:
      case funcCodeReadWriteMultipleRegisters:
        final count =
            ByteData.sublistView(adu).getUint16(4, Endian.big);
        length += 1 + count * 2;
        break;

      case funcCodeWriteSingleCoil:
      case funcCodeWriteMultipleCoils:
      case funcCodeWriteSingleRegister:
      case funcCodeWriteMultipleRegisters:
        length += 4;
        break;

      case funcCodeMaskWriteRegister:
        length += 6;
        break;

      case funcCodeReadFIFOQueue:
        // Undetermined
        break;
    }

    return length;
  }
}
