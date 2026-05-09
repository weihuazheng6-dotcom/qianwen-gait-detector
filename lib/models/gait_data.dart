class GaitData {
  final DateTime timestamp;
  final double? pFirstMetaR, pFifthMetaR, pHeelR;
  final double? accXR, accYR, accZR, gyroXR, gyroYR, gyroZR, rollR, pitchR, yawR;
  final double? pFirstMetaL, pFifthMetaL, pHeelL;
  final double? accXL, accYL, accZL, gyroXL, gyroYL, gyroZL, rollL, pitchL, yawL;
  final String label;

  GaitData({required this.timestamp, this.pFirstMetaR, this.pFifthMetaR, this.pHeelR,
    this.accXR, this.accYR, this.accZR, this.gyroXR, this.gyroYR, this.gyroZR, this.rollR, this.pitchR, this.yawR,
    this.pFirstMetaL, this.pFifthMetaL, this.pHeelL,
    this.accXL, this.accYL, this.accZL, this.gyroXL, this.gyroYL, this.gyroZL, this.rollL, this.pitchL, this.yawL, this.label = ''});

  String toCsvRow() {
    List<String> c = [timestamp.toIso8601String(), _f(pFirstMetaR,1), _f(pFifthMetaR,1), _f(pHeelR,1),
      _f(accXR,3), _f(accYR,3), _f(accZR,3), _f(gyroXR,1), _f(gyroYR,1), _f(gyroZR,1), _f(rollR,1), _f(pitchR,1), _f(yawR,1),
      _f(pFirstMetaL,1), _f(pFifthMetaL,1), _f(pHeelL,1),
      _f(accXL,3), _f(accYL,3), _f(accZL,3), _f(gyroXL,1), _f(gyroYL,1), _f(gyroZL,1), _f(rollL,1), _f(pitchL,1), _f(yawL,1), label];
    return c.join(',');
  }
  static String _f(double? v, int d) => v == null ? '' : v.toStringAsFixed(d);
  static const csvHeader = 'timestamp,P_first_meta_R,P_Fifth_meta_R,P_heel_R,acc_x_R,acc_y_R,acc_z_R,ave_x_R,ave_y_R,ave_z_R,ang_x_R,ang_y_R,ang_z_R,P_first_meta_L,P_Fifth_meta_L,P_heel_L,acc_x_L,acc_y_L,acc_z_L,ave_x_L,ave_y_L,ave_z_L,ang_x_L,ang_y_L,ang_z_L,Label';
}

enum SensorRole { leftPressure, rightPressure, leftIMU, rightIMU, unknown }
enum ConnectionState { disconnected, scanning, connecting, connected, error }

class PressureData {
  final DateTime timestamp; final String deviceId; final double p1,p2,p3;
  PressureData({required this.timestamp, required this.deviceId, required this.p1, required this.p2, required this.p3});
}

class IMUData {
  final DateTime timestamp; final String deviceId;
  final double accX,accY,accZ, gyroX,gyroY,gyroZ, roll,pitch,yaw;
  IMUData({required this.timestamp, required this.deviceId, required this.accX, required this.accY, required this.accZ,
    required this.gyroX, required this.gyroY, required this.gyroZ, required this.roll, required this.pitch, required this.yaw});
}
