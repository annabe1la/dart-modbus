/// Cyclical Redundancy Checking for Modbus RTU

List<int>? _crcTable;

/// Initialize CRC table
void _initCrcTable() {
  const crcPoly16 = 0xa001;
  _crcTable = List<int>.filled(256, 0);

  for (int i = 0; i < 256; i++) {
    int crc = 0;
    int b = i;

    for (int j = 0; j < 8; j++) {
      if (((crc ^ b) & 0x0001) > 0) {
        crc = (crc >> 1) ^ crcPoly16;
      } else {
        crc >>= 1;
      }
      b >>= 1;
    }
    _crcTable![i] = crc;
  }
}

/// Calculate CRC16 checksum
int crc16(List<int> data) {
  _crcTable ??= (() {
    _initCrcTable();
    return _crcTable;
  })()!;

  int val = 0xFFFF;
  for (final v in data) {
    val = (val >> 8) ^ _crcTable![(val ^ v) & 0x00FF];
  }
  return val & 0xFFFF;
}
