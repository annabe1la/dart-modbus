import 'package:dart_modbus/dart_modbus.dart';

void main() async {
  // Example 1: Define register map programmatically
  print('=== Example 1: Programmatic Register Map ===\n');

  final registerMap = RegisterMap(
    slaveId: 1,
    deviceName: 'Temperature Controller',
    registers: [
      RegisterDefinition(
        name: 'temperature',
        address: 100,
        type: RegisterType.inputRegister,
        dataType: DataType.float32,
        multiplier: 0.1,
        unit: '°C',
        description: 'Current temperature reading',
      ),
      RegisterDefinition(
        name: 'setpoint',
        address: 200,
        type: RegisterType.holdingRegister,
        dataType: DataType.float32,
        unit: '°C',
        description: 'Temperature setpoint',
      ),
      RegisterDefinition(
        name: 'alarm',
        address: 300,
        type: RegisterType.coil,
        dataType: DataType.bool,
        description: 'High temperature alarm',
        readOnly: true,
      ),
      RegisterDefinition(
        name: 'counter',
        address: 400,
        type: RegisterType.holdingRegister,
        dataType: DataType.uint32,
        description: 'Operation counter',
      ),
      RegisterDefinition(
        name: 'deviceName',
        address: 500,
        type: RegisterType.holdingRegister,
        dataType: DataType.string,
        quantity: 10, // 10 registers = 20 characters
        description: 'Device name',
      ),
    ],
  );

  // Connect to device
  final provider = TCPClientProvider('192.168.1.100:502');
  final client = ModbusClientImpl(provider);

  try {
    await client.connect();
    print('Connected to Modbus device\n');

    // Read individual register
    print('--- Reading Individual Registers ---');
    final temp = await registerMap.read(client, 'temperature');
    print('Temperature: $temp °C');

    final setpoint = await registerMap.read(client, 'setpoint');
    print('Setpoint: $setpoint °C');

    final alarm = await registerMap.read(client, 'alarm');
    print('Alarm: ${alarm ? "ACTIVE" : "Inactive"}');

    final name = await registerMap.read(client, 'deviceName');
    print('Device Name: $name\n');

    // Read all registers at once
    print('--- Reading All Registers ---');
    final allValues = await registerMap.readAll(client);
    allValues.forEach((name, value) {
      print('$name: $value');
    });
    print('');

    // Write a value
    print('--- Writing Register ---');
    await registerMap.write(client, 'setpoint', 25.5);
    print('New setpoint written: 25.5 °C\n');

    // Example 2: Load from JSON
    print('=== Example 2: Load from JSON ===\n');

    final jsonConfig = '''
{
  "slaveId": 2,
  "deviceName": "Pressure Sensor",
  "registers": [
    {
      "name": "pressure",
      "address": 0,
      "type": "inputRegister",
      "dataType": "float32",
      "multiplier": 0.01,
      "unit": "Bar",
      "description": "Current pressure"
    },
    {
      "name": "maxPressure",
      "address": 10,
      "type": "holdingRegister",
      "dataType": "float32",
      "unit": "Bar",
      "description": "Maximum pressure limit"
    },
    {
      "name": "statusFlags",
      "address": 20,
      "type": "holdingRegister",
      "dataType": "uint16",
      "description": "Device status flags"
    }
  ]
}
''';

    final map2 = RegisterMap.fromJson(jsonConfig);
    print('Loaded register map for: ${map2.deviceName}');
    print('Registers: ${map2.registers.map((r) => r.name).join(", ")}\n');

    // Export to JSON
    print('--- Export to JSON ---');
    final exported = registerMap.toJson();
    print(exported);

  } finally {
    await client.close();
    print('\nConnection closed');
  }
}
