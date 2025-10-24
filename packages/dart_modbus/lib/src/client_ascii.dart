import 'dart:convert';
import 'dart:typed_data';
import 'modbus.dart';
import 'client_provider.dart';
import 'lrc.dart';
import 'serial_port.dart';
import 'utils.dart';

const _asciiStart = ':';
const _asciiEnd = '\r\n';
const _hexTable = '0123456789ABCDEF';

/// ASCII client provider for Modbus ASCII
class ASCIIClientProvider implements ClientProvider {
  final SerialPort _port;

  ASCIIClientProvider(this._port);

  @override
  Future<void> connect() => _port.open();

  @override
  bool get isConnected => _port.isOpen;

  @override
  Future<void> close() => _port.close();

  @override
  Future<ProtocolDataUnit> send(int slaveId, ProtocolDataUnit request) async {
    final aduRequest = _encodeASCIIFrame(slaveId, request);
    final aduResponse = await sendRawFrame(aduRequest);
    final (rspSlaveId, pdu) = _decodeASCIIFrame(aduResponse);
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
    final aduRequest = _encodeASCIIFrame(slaveId, request);
    final aduResponse = await sendRawFrame(aduRequest);
    final (rspSlaveId, pdu) = _decodeASCIIFrame(aduResponse);
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

    // Read until we find the end pattern (\r\n)
    final aduResponse = await _port.readUntil(
      _asciiEnd.codeUnits,
      maxLength: asciiCharacterMaxSize,
    );

    return aduResponse;
  }

  Uint8List _encodeASCIIFrame(int slaveId, ProtocolDataUnit pdu) {
    final length = pdu.data.length + 3;
    if (length > asciiAduMaxSize) {
      throw ArgumentError(
          'modbus: length of data \'$length\' must not be bigger than \'$asciiAduMaxSize\'');
    }

    // Calculate LRC (excluding start and end characters)
    final lrcCalc = LRC()
      ..reset()
      ..push([slaveId])
      ..push([pdu.funcCode])
      ..push(pdu.data);
    final lrcVal = lrcCalc.value;

    // Build the ASCII frame
    final frame = StringBuffer();
    frame.write(_asciiStart);

    // Slave ID
    frame.write(_hexTable[(slaveId >> 4) & 0x0F]);
    frame.write(_hexTable[slaveId & 0x0F]);

    // Function code
    frame.write(_hexTable[(pdu.funcCode >> 4) & 0x0F]);
    frame.write(_hexTable[pdu.funcCode & 0x0F]);

    // Data
    for (final v in pdu.data) {
      frame.write(_hexTable[(v >> 4) & 0x0F]);
      frame.write(_hexTable[v & 0x0F]);
    }

    // LRC
    frame.write(_hexTable[(lrcVal >> 4) & 0x0F]);
    frame.write(_hexTable[lrcVal & 0x0F]);

    // End
    frame.write(_asciiEnd);

    return Uint8List.fromList(utf8.encode(frame.toString()));
  }

  (int, Uint8List) _decodeASCIIFrame(Uint8List adu) {
    if (adu.length < asciiAduMinSize + 6) {
      throw Exception(
          'modbus: response length \'${adu.length}\' does not meet minimum \'${asciiAduMinSize + 6}\'');
    }

    final frameStr = utf8.decode(adu);

    // Check length (excluding colon must be even)
    if ((frameStr.length - 1) % 2 != 0) {
      throw Exception(
          'modbus: response length \'${frameStr.length - 1}\' is not an even number');
    }

    // Check start character
    if (!frameStr.startsWith(_asciiStart)) {
      throw Exception(
          'modbus: response frame is not started with \'$_asciiStart\'');
    }

    // Check end characters
    if (!frameStr.endsWith(_asciiEnd)) {
      throw Exception(
          'modbus: response frame is not ended with \'${_asciiEnd.replaceAll('\r', '\\r').replaceAll('\n', '\\n')}\'');
    }

    // Extract hex data (without start colon and end CRLF)
    final hexData = frameStr.substring(1, frameStr.length - 2);

    // Decode hex to bytes
    final bytes = <int>[];
    for (int i = 0; i < hexData.length; i += 2) {
      final hex = hexData.substring(i, i + 2);
      bytes.add(int.parse(hex, radix: 16));
    }

    if (bytes.isEmpty) {
      throw Exception('modbus: decoded frame is empty');
    }

    // Verify LRC
    final lrcCalc = LRC()
      ..reset()
      ..push(bytes.sublist(0, bytes.length - 1));
    final lrcVal = lrcCalc.value;

    if (bytes.last != lrcVal) {
      throw Exception(
          'modbus: response lrc \'${bytes.last.toRadixString(16)}\' does not match expected \'${lrcVal.toRadixString(16)}\'');
    }

    // Return slave ID and PDU (without LRC)
    return (bytes[0], Uint8List.fromList(bytes.sublist(1, bytes.length - 1)));
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
}
