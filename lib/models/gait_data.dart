class GaitData {
  final DateTime timestamp;
  
  // Right Foot
  final double? pFirstMetaR, pFifthMetaR, pHeelR;
  final double? accXR, accYR, accZR;
  final double? gyroXR, gyroYR, gyroZR; // Maps to ave_x/y/z_R
  final double? rollR, pitchR, yawR;    // Maps to ang_x/y/z_R

  // Left Foot
  final double? pFirstMetaL, pFifthMetaL, pHeelL;
  final double? accXL, accYL, accZL;
  final double? gyroXL, gyroYL, gyroZL;
  final double? rollL, pitchL, yawL;

  final String label;

  GaitData({
    required this.timestamp,
    this.pFirstMetaR, this.pFifthMetaR, this.pHeelR,
    this.accXR, this.accYR, this.accZR, this.gyroXR, this.gyroYR, this.gyroZR, this.rollR, this.pitchR, this.yawR,
    this.pFirstMetaL, this.pFifthMetaL, this.pHeelL,
    this.accXL, this.accYL, this.accZL, this.gyroXL, this.gyroYL, this.gyroZL, this.rollL, this.pitchL, this.yawL,
    this.label = '',
  });

  // 格式化时间戳为 2026-05-09T10:50:15.475
  String _formatTime(DateTime dt) {
    final ms = dt.millisecond.toString().padLeft(3, '0');
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}T'
           '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}.$ms';
  }

  String _fmt(double? v, int decimals) {
    if (v == null) return ''; // 如果没数据则留空
    return v.toStringAsFixed(decimals);
  }

  String toCsvRow() {
    return [
      _formatTime(timestamp),
      // Right Pressure
      _fmt(pFirstMetaR, 1), _fmt(pFifthMetaR, 1), _fmt(pHeelR, 1),
      // Right Acc
      _fmt(accXR, 3), _fmt(accYR, 3), _fmt(accZR, 3),
      // Right Gyro (ave)
      _fmt(gyroXR, 1), _fmt(gyroYR, 1), _fmt(gyroZR, 1),
      // Right Angle (ang)
      _fmt(rollR, 1), _fmt(pitchR, 1), _fmt(yawR, 1),
      // Left Pressure
      _fmt(pFirstMetaL, 1), _fmt(pFifthMetaL, 1), _fmt(pHeelL, 1),
      // Left Acc
      _fmt(accXL, 3), _fmt(accYL, 3), _fmt(accZL, 3),
      // Left Gyro (ave)
      _fmt(gyroXL, 1), _fmt(gyroYL, 1), _fmt(gyroZL, 1),
      // Left Angle (ang)
      _fmt(rollL, 1), _fmt(pitchL, 1), _fmt(yawL, 1),
      // Label
      label
    ].join(',');
  }

  static const String csvHeader = 
      'timestamp,'
      'P_first_meta_R,P_Fifth_meta_R,P_heel_R,'
      'acc_x_R,acc_y_R,acc_z_R,'
      'ave_x_R,ave_y_R,ave_z_R,'
      'ang_x_R,ang_y_R,ang_z_R,'
      'P_first_meta_L,P_Fifth_meta_L,P_heel_L,'
      'acc_x_L,acc_y_L,acc_z_L,'
      'ave_x_L,ave_y_L,ave_z_L,'
      'ang_x_L,ang_y_L,ang_z_L,'
      'Label';
}

// 枚举保持不变
enum SensorRole { leftPressure, rightPressure, leftIMU, rightIMU }
