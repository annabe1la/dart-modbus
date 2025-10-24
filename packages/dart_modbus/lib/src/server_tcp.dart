import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'modbus.dart';

/// Callback for handling Modbus requests
typedef ModbusRequestHandler = Future<ProtocolDataUnit?> Function(
    int slaveId, ProtocolDataUnit request);

/// Modbus TCP Server implementation
class ModbusTCPServer {
  final String _host;
  final int _port;
  final ModbusRequestHandler _requestHandler;

  ServerSocket? _serverSocket;
  final List<Socket> _clients = [];
  bool _isRunning = false;

  ModbusTCPServer({
    required String host,
    required int port,
    required ModbusRequestHandler requestHandler,
  })  : _host = host,
        _port = port,
        _requestHandler = requestHandler;

  /// Start the server
  Future<void> start() async {
    if (_isRunning) {
      throw StateError('Server is already running');
    }

    _serverSocket = await ServerSocket.bind(_host, _port);
    _isRunning = true;

    print('Modbus TCP Server started on $_host:$_port');

    _serverSocket!.listen((client) {
      print('Client connected: ${client.remoteAddress.address}:${client.remotePort}');
      _clients.add(client);
      _handleClient(client);
    });
  }

  /// Stop the server
  Future<void> stop() async {
    if (!_isRunning) return;

    _isRunning = false;

    for (final client in _clients) {
      await client.close();
    }
    _clients.clear();

    await _serverSocket?.close();
    _serverSocket = null;

    print('Modbus TCP Server stopped');
  }

  /// Handle client connection
  void _handleClient(Socket client) {
    final buffer = <int>[];

    client.listen(
      (data) async {
        buffer.addAll(data);

        // Process complete MBAP frames
        while (buffer.length >= tcpHeaderMbapSize) {
          // Check if we have a complete frame
          final length = ByteData.sublistView(Uint8List.fromList(buffer))
              .getUint16(4, Endian.big);
          final frameLength = tcpHeaderMbapSize + length - 1;

          if (buffer.length < frameLength) {
            break; // Wait for more data
          }

          // Extract complete frame
          final frame = Uint8List.fromList(buffer.sublist(0, frameLength));
          buffer.removeRange(0, frameLength);

          // Process frame
          try {
            final response = await _processFrame(frame);
            if (response != null) {
              client.add(response);
            }
          } catch (e) {
            print('Error processing frame: $e');
          }
        }
      },
      onError: (error) {
        print('Client error: $error');
        _clients.remove(client);
      },
      onDone: () {
        print('Client disconnected: ${client.remoteAddress.address}:${client.remotePort}');
        _clients.remove(client);
      },
      cancelOnError: true,
    );
  }

  /// Process a single Modbus frame
  Future<Uint8List?> _processFrame(Uint8List frame) async {
    if (frame.length < tcpAduMinSize) {
      return null;
    }

    final byteData = ByteData.sublistView(frame);

    // Parse MBAP header
    final transactionId = byteData.getUint16(0, Endian.big);
    final protocolId = byteData.getUint16(2, Endian.big);
    final slaveId = frame[6];

    if (protocolId != tcpProtocolIdentifier) {
      return null; // Invalid protocol
    }

    // Extract PDU
    final pdu = frame.sublist(tcpHeaderMbapSize);
    final funcCode = pdu[0];
    final data = pdu.sublist(1);

    final request = ProtocolDataUnit(funcCode, data);

    // Call handler
    final response = await _requestHandler(slaveId, request);

    if (response == null) {
      return null; // No response (e.g., broadcast)
    }

    // Build response frame
    final responseLength = 2 + response.data.length; // slaveId + funcCode + data
    final responseFrame = Uint8List(tcpHeaderMbapSize + 1 + response.data.length);
    final responseData = ByteData.sublistView(responseFrame);

    // MBAP header
    responseData.setUint16(0, transactionId, Endian.big);
    responseData.setUint16(2, tcpProtocolIdentifier, Endian.big);
    responseData.setUint16(4, responseLength, Endian.big);
    responseFrame[6] = slaveId;

    // PDU
    responseFrame[tcpHeaderMbapSize] = response.funcCode;
    responseFrame.setRange(
        tcpHeaderMbapSize + 1, responseFrame.length, response.data);

    return responseFrame;
  }

  /// Check if server is running
  bool get isRunning => _isRunning;

  /// Get number of connected clients
  int get clientCount => _clients.length;
}
