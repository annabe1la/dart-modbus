import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'modbus.dart';
import 'client_provider.dart';
import 'utils.dart';

const _tcpDefaultTimeout = Duration(seconds: 1);

/// TCP client provider for Modbus TCP
class TCPClientProvider implements ClientProvider {
  final String _host;
  final int _port;
  final Duration _timeout;

  Socket? _socket;
  int _transactionId = 0;

  TCPClientProvider(
    String address, {
    Duration timeout = _tcpDefaultTimeout,
  })  : _host = address.split(':').first,
        _port = address.contains(':')
            ? int.parse(address.split(':').last)
            : 502,
        _timeout = timeout;

  @override
  Future<void> connect() async {
    if (_socket != null) return;
    _socket = await Socket.connect(_host, _port, timeout: _timeout);
  }

  @override
  bool get isConnected => _socket != null;

  @override
  Future<void> close() async {
    await _socket?.close();
    _socket = null;
  }

  @override
  Future<ProtocolDataUnit> send(int slaveId, ProtocolDataUnit request) async {
    _transactionId = (_transactionId + 1) & 0xFFFF;

    final (head, adu) = _encodeTCPFrame(_transactionId, slaveId, request);
    final aduResponse = await sendRawFrame(adu);
    final (rspHead, pdu) = _decodeTCPFrame(aduResponse);
    final response = ProtocolDataUnit(pdu[0], pdu.sublist(1));

    _verifyTCPFrame(head, rspHead, request, response);
    return response;
  }

  @override
  Future<Uint8List> sendPdu(int slaveId, Uint8List pduRequest) async {
    if (pduRequest.length < pduMinSize || pduRequest.length > pduMaxSize) {
      throw ArgumentError(
          'modbus: pdu size \'${pduRequest.length}\' must be between \'$pduMinSize\' and \'$pduMaxSize\'');
    }

    _transactionId = (_transactionId + 1) & 0xFFFF;

    final request = ProtocolDataUnit(pduRequest[0], pduRequest.sublist(1));
    final (head, adu) = _encodeTCPFrame(_transactionId, slaveId, request);
    final aduResponse = await sendRawFrame(adu);
    final (rspHead, pdu) = _decodeTCPFrame(aduResponse);
    final response = ProtocolDataUnit(pdu[0], pdu.sublist(1));

    _verifyTCPFrame(head, rspHead, request, response);
    return pdu;
  }

  @override
  Future<Uint8List> sendRawFrame(Uint8List aduRequest) async {
    if (_socket == null) {
      await connect();
    }

    _socket!.add(aduRequest);
    await _socket!.flush();

    // Read MBAP header first
    final headerData = await _readBytes(tcpHeaderMbapSize);

    // Extract length from header
    final length =
        ByteData.sublistView(headerData).getUint16(4, Endian.big);

    if (length <= 0) {
      throw Exception(
          'modbus: length in response header \'$length\' must not be zero');
    }
    if (length > (tcpAduMaxSize - (tcpHeaderMbapSize - 1))) {
      throw Exception(
          'modbus: length in response header \'$length\' must not be greater than \'${tcpAduMaxSize - tcpHeaderMbapSize + 1}\'');
    }

    // Read the rest of the data
    final totalLength = tcpHeaderMbapSize + length - 1;
    final restData = await _readBytes(totalLength - tcpHeaderMbapSize);

    final result = Uint8List(totalLength);
    result.setRange(0, tcpHeaderMbapSize, headerData);
    result.setRange(tcpHeaderMbapSize, totalLength, restData);

    return result;
  }

  Future<Uint8List> _readBytes(int length) async {
    final completer = Completer<Uint8List>();
    final buffer = <int>[];
    late StreamSubscription subscription;

    final timer = Timer(_timeout, () {
      subscription.cancel();
      if (!completer.isCompleted) {
        completer.completeError(
            TimeoutException('Read timeout', _timeout));
      }
    });

    subscription = _socket!.listen(
      (data) {
        buffer.addAll(data);
        if (buffer.length >= length) {
          timer.cancel();
          subscription.cancel();
          if (!completer.isCompleted) {
            completer.complete(Uint8List.fromList(buffer.sublist(0, length)));
          }
        }
      },
      onError: (error) {
        timer.cancel();
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      },
      onDone: () {
        timer.cancel();
        if (!completer.isCompleted) {
          completer.completeError(
              Exception('Connection closed before receiving all data'));
        }
      },
      cancelOnError: true,
    );

    return completer.future;
  }

  (ProtocolTCPHeader, Uint8List) _encodeTCPFrame(
      int tid, int slaveId, ProtocolDataUnit pdu) {
    final length = tcpHeaderMbapSize + 1 + pdu.data.length;
    if (length > tcpAduMaxSize) {
      throw ArgumentError(
          'modbus: length of data \'$length\' must not be bigger than \'$tcpAduMaxSize\'');
    }

    final head = ProtocolTCPHeader(
      transactionId: tid,
      protocolId: tcpProtocolIdentifier,
      length: 2 + pdu.data.length,
      slaveId: slaveId,
    );

    final adu = Uint8List(length);
    final byteData = ByteData.sublistView(adu);

    byteData.setUint16(0, head.transactionId, Endian.big);
    byteData.setUint16(2, head.protocolId, Endian.big);
    byteData.setUint16(4, head.length, Endian.big);
    adu[6] = head.slaveId;
    adu[tcpHeaderMbapSize] = pdu.funcCode;
    adu.setRange(tcpHeaderMbapSize + 1, length, pdu.data);

    return (head, adu);
  }

  (ProtocolTCPHeader, Uint8List) _decodeTCPFrame(Uint8List adu) {
    if (adu.length < tcpAduMinSize) {
      throw Exception(
          'modbus: response length \'${adu.length}\' does not meet minimum \'$tcpAduMinSize\'');
    }

    final byteData = ByteData.sublistView(adu);
    final head = ProtocolTCPHeader(
      transactionId: byteData.getUint16(0, Endian.big),
      protocolId: byteData.getUint16(2, Endian.big),
      length: byteData.getUint16(4, Endian.big),
      slaveId: adu[6],
    );

    final pduLength = adu.length - tcpHeaderMbapSize;
    if (pduLength != head.length - 1) {
      throw Exception(
          'modbus: length in response \'${head.length - 1}\' does not match pdu data length \'$pduLength\'');
    }

    return (head, adu.sublist(tcpHeaderMbapSize));
  }

  void _verifyTCPFrame(ProtocolTCPHeader reqHead, ProtocolTCPHeader rspHead,
      ProtocolDataUnit reqPDU, ProtocolDataUnit rspPDU) {
    if (rspHead.transactionId != reqHead.transactionId) {
      throw Exception(
          'modbus: response transaction id \'${rspHead.transactionId}\' does not match request \'${reqHead.transactionId}\'');
    }

    if (rspHead.protocolId != reqHead.protocolId) {
      throw Exception(
          'modbus: response protocol id \'${rspHead.protocolId}\' does not match request \'${reqHead.protocolId}\'');
    }

    if (rspHead.slaveId != reqHead.slaveId) {
      throw Exception(
          'modbus: response unit id \'${rspHead.slaveId}\' does not match request \'${reqHead.slaveId}\'');
    }

    if (rspPDU.funcCode != reqPDU.funcCode) {
      throw responseError(rspPDU);
    }

    if (rspPDU.data.isEmpty) {
      throw Exception('modbus: response data is empty');
    }
  }
}
