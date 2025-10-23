/// Constants which define the format of a modbus frame. The example is
/// shown for a Modbus RTU/ASCII frame. Note that the Modbus PDU is not
/// dependent on the underlying transport.
///
/// ```
/// <------------------------ MODBUS SERIAL LINE ADU (1) ------------------->
///              <----------- MODBUS PDU (1') ---------------->
///  +-----------+---------------+----------------------------+-------------+
///  | Address   | Function Code | Data                       | CRC/LRC     |
///  +-----------+---------------+----------------------------+-------------+
///  |           |               |                                   |
/// (2)        (3/2')           (3')                                (4)
///
/// (1)  ... SerADUMaxSize    = 256
/// (2)  ... SerAddressOffset = 0
/// (3)  ... SerPDUOffset     = 1
/// (4)  ... SerCrcSize       = 2
///      ... SerLrcSize       = 1
///
/// (1') ... SerPDUMaxSize         = 253
/// (2') ... SerPDUFuncCodeOffset  = 0
/// (3') ... SerPDUDataOffset       = 1
/// ```

/// ```
/// <------------------------ MODBUS TCP/IP ADU(1) ------------------------->
///                              <----------- MODBUS PDU (1') -------------->
///  +-----------+---------------+------------------------------------------+
///  | TID | PID | Length | UID  | Function Code  | Data                    |
///  +-----------+---------------+------------------------------------------+
///  |     |     |        |      |
/// (2)   (3)   (4)      (5)    (6)
///
/// (2)  ... TCPTidOffset    = 0 (Transaction Identifier - 2 Byte)
/// (3)  ... TCPPidOffset    = 2 (Protocol Identifier - 2 Byte)
/// (4)  ... TCPLengthOffset = 4 (Number of bytes - 2 Byte)( UID + PDU length )
/// (5)  ... TCPUidOffset    = 6 (Unit Identifier - 1 Byte)
/// (6)  ... TCPPDUOffset    = 7 (Modbus PDU )
///
/// (1)  ... TCPADUMaxSize   = 260 Modbus TCP/IP Application Data Unit
/// (1') ... SerPDUMaxSize   = 253 Modbus Protocol Data Unit
/// ```

library modbus;

// Proto address limits
const int addressBroadCast = 0;
const int addressMin = 1;
const int addressMax = 247;

// PDU sizes
const int pduMinSize = 1; // funcCode(1)
const int pduMaxSize = 253; // funcCode(1) + data(252)

// RTU ADU sizes
const int rtuAduMinSize = 4; // address(1) + funcCode(1) + crc(2)
const int rtuAduMaxSize = 256; // address(1) + PDU(253) + crc(2)

// ASCII ADU sizes
const int asciiAduMinSize = 3;
const int asciiAduMaxSize = 256;
const int asciiCharacterMaxSize = 513;

// TCP sizes
const int tcpProtocolIdentifier = 0x0000;
const int tcpHeaderMbapSize = 7; // MBAP header
const int tcpAduMinSize = 8; // MBAP + funcCode
const int tcpAduMaxSize = 260;

// Proto register limits
const int readBitsQuantityMin = 1; // 0x0001
const int readBitsQuantityMax = 2000; // 0x07d0
const int writeBitsQuantityMin = 1;
const int writeBitsQuantityMax = 1968; // 0x07b0

// 16 Bits register limits
const int readRegQuantityMin = 1;
const int readRegQuantityMax = 125; // 0x007d
const int writeRegQuantityMin = 1;
const int writeRegQuantityMax = 123; // 0x007b
const int readWriteOnReadRegQuantityMin = 1;
const int readWriteOnReadRegQuantityMax = 125; // 0x007d
const int readWriteOnWriteRegQuantityMin = 1;
const int readWriteOnWriteRegQuantityMax = 121; // 0x0079

// Function codes
const int funcCodeReadDiscreteInputs = 2;
const int funcCodeReadCoils = 1;
const int funcCodeWriteSingleCoil = 5;
const int funcCodeWriteMultipleCoils = 15;

const int funcCodeReadInputRegisters = 4;
const int funcCodeReadHoldingRegisters = 3;
const int funcCodeWriteSingleRegister = 6;
const int funcCodeWriteMultipleRegisters = 16;
const int funcCodeReadWriteMultipleRegisters = 23;
const int funcCodeMaskWriteRegister = 22;
const int funcCodeReadFIFOQueue = 24;
const int funcCodeOtherReportSlaveID = 17;

// Exception codes
const int exceptionCodeIllegalFunction = 1;
const int exceptionCodeIllegalDataAddress = 2;
const int exceptionCodeIllegalDataValue = 3;
const int exceptionCodeServerDeviceFailure = 4;
const int exceptionCodeAcknowledge = 5;
const int exceptionCodeServerDeviceBusy = 6;
const int exceptionCodeNegativeAcknowledge = 7;
const int exceptionCodeMemoryParityError = 8;
const int exceptionCodeGatewayPathUnavailable = 10;
const int exceptionCodeGatewayTargetDeviceFailedToRespond = 11;

/// Exception error from modbus server
class ModbusException implements Exception {
  final int exceptionCode;

  const ModbusException(this.exceptionCode);

  @override
  String toString() {
    final name = switch (exceptionCode) {
      exceptionCodeIllegalFunction => 'illegal function',
      exceptionCodeIllegalDataAddress => 'illegal data address',
      exceptionCodeIllegalDataValue => 'illegal data value',
      exceptionCodeServerDeviceFailure => 'server device failure',
      exceptionCodeAcknowledge => 'acknowledge',
      exceptionCodeServerDeviceBusy => 'server device busy',
      exceptionCodeNegativeAcknowledge => 'negative acknowledge',
      exceptionCodeMemoryParityError => 'memory parity error',
      exceptionCodeGatewayPathUnavailable => 'gateway path unavailable',
      exceptionCodeGatewayTargetDeviceFailedToRespond =>
        'gateway target device failed to respond',
      _ => 'unknown',
    };
    return 'modbus: exception \'$exceptionCode\' ($name)';
  }
}

/// Protocol TCP header
class ProtocolTCPHeader {
  final int transactionId;
  final int protocolId;
  final int length;
  final int slaveId;

  const ProtocolTCPHeader({
    required this.transactionId,
    required this.protocolId,
    required this.length,
    required this.slaveId,
  });
}

/// Protocol Data Unit (PDU) is independent of underlying communication layers
class ProtocolDataUnit {
  final int funcCode;
  final List<int> data;

  const ProtocolDataUnit(this.funcCode, this.data);
}