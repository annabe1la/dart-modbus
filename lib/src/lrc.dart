/// Longitudinal Redundancy Check for Modbus ASCII

class LRC {
  int _sum = 0;

  /// Reset LRC sum
  LRC reset() {
    _sum = 0;
    return this;
  }

  /// Push data into sum calculation
  LRC push(List<int> data) {
    for (final b in data) {
      _sum = (_sum + b) & 0xFF;
    }
    return this;
  }

  /// Get LRC value
  int get value => (-((_sum << 24) >> 24)) & 0xFF;
}