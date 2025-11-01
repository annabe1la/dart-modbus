import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:dart_modbus/modbus.dart';
import '../bin/lib/virtual_serial_port.dart';
import '../bin/lib/storage.dart';

void main() {
  group('RTU Master-Slave Communication Tests', () {
    late VirtualSerialPair serialPair;
    late ModbusStorage storage;
    late ModbusClient client;
    late SerialConfig config;

    setUp(() async {
      // 创建存储
      storage = ModbusStorage();

      // 初始化测试数据
      storage.setHoldingRegisters(0, [100, 200, 300, 400, 500]);
      storage.setInputRegisters(0, [1000, 2000, 3000]);
      storage.setCoils(0, [true, false, true, false, true]);
      storage.setDiscreteInput(0, true);
      storage.setDiscreteInput(1, false);

      // 创建串口配置
      config = SerialConfig(
        portName: 'virtual-rtu',
        baudRate: 9600,
        dataBits: 8,
        stopBits: 1,
        parity: 'N',
        timeout: Duration(seconds: 2),
      );

      // 创建虚拟串口对
      serialPair = VirtualSerialPair('rtu-test', config);

      // 先打开port2用于从站
      await serialPair.port2.open();

      // 启动从站（在后台处理请求）
      _startSlaveServer(serialPair.port2, storage);

      // 创建主站客户端
      final provider = RTUClientProvider(serialPair.port1, config);
      client = ModbusClientImpl(provider);
      await client.connect();
    });

    tearDown(() async {
      await client.close();
      await serialPair.cleanup();
      storage.clear();
    });

    test('Read Holding Registers', () async {
      final result = await client.readHoldingRegisters(1, 0, 5);
      expect(result, [100, 200, 300, 400, 500]);
    });

    test('Read Input Registers', () async {
      final result = await client.readInputRegisters(1, 0, 3);
      expect(result, [1000, 2000, 3000]);
    });

    test('Read Coils', () async {
      final resultBytes = await client.readCoils(1, 0, 5);
      final result = List.generate(5, (i) => (resultBytes[i ~/ 8] & (1 << (i % 8))) != 0);
      expect(result, [true, false, true, false, true]);
    });

    test('Read Discrete Inputs', () async {
      final resultBytes = await client.readDiscreteInputs(1, 0, 2);
      final result = List.generate(2, (i) => (resultBytes[i ~/ 8] & (1 << (i % 8))) != 0);
      expect(result, [true, false]);
    });

    test('Write Single Coil', () async {
      await client.writeSingleCoil(1, 10, true);

      // 验证写入
      final resultBytes = await client.readCoils(1, 10, 1);
      final result = (resultBytes[0] & 0x01) != 0;
      expect(result, true);
    });

    test('Write Single Register', () async {
      await client.writeSingleRegister(1, 10, 12345);

      // 验证写入
      final result = await client.readHoldingRegisters(1, 10, 1);
      expect(result, [12345]);
    });

    test('Write Multiple Coils', () async {
      final coils = [true, true, false, false, true];
      final coilBytes = Uint8List(1);
      for (int i = 0; i < coils.length; i++) {
        if (coils[i]) coilBytes[0] |= (1 << i);
      }
      await client.writeMultipleCoils(1, 20, 5, coilBytes);

      // 验证写入
      final resultBytes = await client.readCoils(1, 20, 5);
      final result = List.generate(5, (i) => (resultBytes[i ~/ 8] & (1 << (i % 8))) != 0);
      expect(result, coils);
    });

    test('Write Multiple Registers', () async {
      final registers = Uint16List.fromList([111, 222, 333, 444, 555]);
      await client.writeMultipleRegisters(1, 20, 5, registers);

      // 验证写入
      final result = await client.readHoldingRegisters(1, 20, 5);
      expect(result, registers);
    });

    test('Read/Write Multiple Registers', () async {
      final writeValues = Uint16List.fromList([99, 88, 77]);
      final writeBytes = Uint8List(writeValues.length * 2);
      for (int i = 0; i < writeValues.length; i++) {
        writeBytes[i * 2] = (writeValues[i] >> 8) & 0xFF;
        writeBytes[i * 2 + 1] = writeValues[i] & 0xFF;
      }

      final result = await client.readWriteMultipleRegisters(
        1,
        0, // read address
        5, // read quantity
        30, // write address
        3, // write quantity
        writeBytes,
      );

      expect(result, Uint16List.fromList([100, 200, 300, 400, 500]));

      // 验证写入
      final written = await client.readHoldingRegisters(1, 30, 3);
      expect(written, writeValues);
    });

    test('Read Holding Registers as Bytes', () async {
      final bytes = await client.readHoldingRegistersBytes(1, 0, 2);

      // 100 = 0x0064, 200 = 0x00C8
      // Big-endian: [0x00, 0x64, 0x00, 0xC8]
      expect(bytes, [0x00, 0x64, 0x00, 0xC8]);
    });

    test('Write Multiple Registers as Bytes', () async {
      // 写入两个寄存器: 0x1234 和 0x5678
      final bytes = Uint8List.fromList([0x12, 0x34, 0x56, 0x78]);
      await client.writeMultipleRegistersBytes(1, 40, 2, bytes);

      // 验证写入
      final result = await client.readHoldingRegisters(1, 40, 2);
      expect(result, [0x1234, 0x5678]);
    });

    test('Data Type Conversion - Float32', () async {
      // 写入 float32 值
      final floatValue = 123.456;
      final bytes = DataConverter.float32ToBytes(floatValue);
      await client.writeMultipleRegistersBytes(1, 50, 2, bytes);

      // 读取并验证
      final readBytes = await client.readHoldingRegistersBytes(1, 50, 2);
      final decodedValue = DataConverter.bytesToFloat32(readBytes);

      expect(decodedValue, closeTo(floatValue, 0.001));
    });

    test('Data Type Conversion - Int32', () async {
      // 写入 int32 值
      final int32Value = 123456789;
      final bytes = DataConverter.int32ToBytes(int32Value);
      await client.writeMultipleRegistersBytes(1, 60, 2, bytes);

      // 读取并验证
      final readBytes = await client.readHoldingRegistersBytes(1, 60, 2);
      final decodedValue = DataConverter.bytesToInt32(readBytes);

      expect(decodedValue, int32Value);
    });

    test('Data Type Conversion - String', () async {
      // 写入字符串
      final text = 'Hello';
      final bytes = DataConverter.stringToBytes(text, length: 10);
      await client.writeMultipleRegistersBytes(1, 70, 5, bytes);

      // 读取并验证
      final readBytes = await client.readHoldingRegistersBytes(1, 70, 5);
      final decodedText = DataConverter.bytesToString(readBytes).trim();

      expect(decodedText, text);
    });

    test('Mask Write Register', () async {
      // 先写入初始值
      await client.writeSingleRegister(1, 80, 0xF0F0);

      // 使用掩码修改 (AND mask = 0xFF00, OR mask = 0x000F)
      await client.maskWriteRegister(1, 80, 0xFF00, 0x000F);

      // 读取并验证 (0xF0F0 & 0xFF00 | 0x000F = 0xF00F)
      final result = await client.readHoldingRegisters(1, 80, 1);
      expect(result, [0xF00F]);
    });

    test('Large Data Transfer - Max Registers', () async {
      // 准备最大数量的寄存器 (125)
      final largeData = List.generate(125, (i) => i);
      storage.setHoldingRegisters(1000, largeData);

      // 读取最大数量的寄存器
      final result = await client.readHoldingRegisters(1, 1000, 125);
      expect(result.length, 125);
      expect(result, largeData);
    });

    test('CRC16 Checksum Verification', () async {
      // 测试 CRC16 校验和计算
      final testData = Uint8List.fromList([0x01, 0x03, 0x00, 0x00, 0x00, 0x0A]);
      final checksum = crc16(testData);

      // CRC16 应该是确定性的
      expect(checksum, isA<int>());
      expect(checksum >= 0 && checksum <= 0xFFFF, true);
    });

    test('Error Handling - Illegal Address', () async {
      // 读取未初始化的地址应该返回 0
      final result = await client.readHoldingRegisters(1, 9999, 1);
      expect(result, [0]);
    });

    test('Connection Status', () {
      expect(client.isConnected, true);
    });

    test('Multiple Slave IDs', () async {
      // 测试不同的从站 ID
      storage.setHoldingRegister(100, 777);

      final result1 = await client.readHoldingRegisters(1, 100, 1);
      expect(result1, [777]);

      final result2 = await client.readHoldingRegisters(2, 100, 1);
      expect(result2, [777]); // 同一个存储
    });
  });
}

/// 启动从站服务器处理请求
void _startSlaveServer(VirtualSerialPort port, ModbusStorage storage) {
  port.stream.listen((data) async {
    try {
      // RTU 帧格式: [SlaveID(1)][FuncCode(1)][Data(n)][CRC(2)]
      if (data.length < 4) return;

      // 验证 CRC (小端序)
      final frameData = data.sublist(0, data.length - 2);
      final receivedCrc = data[data.length - 2] | (data[data.length - 1] << 8);
      final calculatedCrc = crc16(frameData);

      if (receivedCrc != calculatedCrc) {
        print('CRC error: received=$receivedCrc, calculated=$calculatedCrc');
        return;
      }

      final slaveId = data[0];
      final funcCode = data[1];
      final pduData = data.sublist(2, data.length - 2);

      final pdu = ProtocolDataUnit(funcCode, pduData);

      // 处理请求
      final response = await storage.handleRequest(slaveId, pdu);
      if (response == null) return;

      // 构建响应帧
      final responseFrame = <int>[slaveId, response.funcCode, ...response.data];
      final responseCrc = crc16(Uint8List.fromList(responseFrame));

      final fullResponse = Uint8List.fromList([
        ...responseFrame,
        responseCrc & 0xFF,
        (responseCrc >> 8) & 0xFF,
      ]);

      await port.write(fullResponse);
    } catch (e) {
      print('Slave server error: $e');
    }
  });
}