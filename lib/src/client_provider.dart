import 'dart:typed_data';
import 'modbus.dart';

/// Client provider interface for underlying protocol implementations
abstract class ClientProvider {
  /// Connect to the remote server
  Future<void> connect();

  /// Check if client is connected
  bool get isConnected;

  /// Close connection to remote server
  Future<void> close();

  /// Send request to the remote server
  Future<ProtocolDataUnit> send(int slaveId, ProtocolDataUnit request);

  /// Send PDU request to the remote server
  Future<Uint8List> sendPdu(int slaveId, Uint8List pduRequest);

  /// Send raw frame to the remote server
  Future<Uint8List> sendRawFrame(Uint8List aduRequest);
}
