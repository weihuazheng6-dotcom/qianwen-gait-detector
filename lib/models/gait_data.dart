class GaitData {
  final DateTime timestamp;
  final String deviceName; // 新增：设备名称
  
  // 加速度 (g)
  final double accX, accY, accZ;
  // 角速度 (°/s)
  final double gyroX, gyroY, gyroZ;
  // 角度 (°)
  final double angleX, angleY, angleZ;
  
  // 标签
  final String label;

  GaitData({
    required this.timestamp,
    required this.deviceName,
    required this.accX, required this.accY, required this.accZ,
    required this.gyroX, required this.gyroY, required this.gyroZ,
    required this.angleX, required this.angleY, required this.angleZ,
    this.label = '',
  });

  /// 转换为 CSV 行 (匹配你提供的文本文件格式)
  String toCsvRow() {
    // 格式：Time,DeviceName,AccX,AccY,AccZ,GyroX,GyroY,GyroZ,AngleX,AngleY,AngleZ,Label
    // 注意：磁场、四元数等数据当前蓝牙帧未包含，故留空或跳过
    List<String> c = [
      timestamp.toIso8601String(),
      deviceName,
      _f(accX, 3), _f(accY, 3), _f(accZ, 3),
      _f(gyroX, 1), _f(gyroY, 1), _f(gyroZ, 1),
      _f(angleX, 1), _f(angleY, 1), _f(angleZ, 1),
      label
    ];
    return c.join(',');
  }

  static String _f(double v, int d) => v.toStringAsFixed(d);

  /// CSV 表头 (对应你的文本文件)
  static const csvHeader = 
      'Time,DeviceName,AccX,AccY,AccZ,GyroX,GyroY,GyroZ,AngleX,AngleY,AngleZ,Label';
}

enum SensorRole { leftPressure, rightPressure, leftIMU, rightIMU, unknown }
enum ConnectionState { disconnected, scanning, connecting, connected, error }

// 暂时保留压力数据类，虽然目前主要关注 IMU
class PressureData {
  final DateTime timestamp; final String deviceId; final double p1,p2,p3;
  PressureData({required this.timestamp, required this.deviceId, required this.p1, required this.p2, required this.p3});
}
