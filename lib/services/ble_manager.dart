import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/gait_data.dart';

class BLEManager extends ChangeNotifier {
  // 保存所有录制的行数据
  final List<GaitData> _recordedData = [];
  List<GaitData> get recordedData => List.unmodifiable(_recordedData);

  // 保存左右脚的“最新状态”，用于合并
  Map<SensorRole, dynamic> _latestState = {};

  bool _isRecording = false;
  bool get isRecording => _isRecording;

  String _currentLabel = '';
  void setLabel(String label) { _currentLabel = label; }

  // 蓝牙连接状态 (简化)
  Map<SensorRole, bool> _connected = {
    for(var r in SensorRole.values) r: false
  };
  Map<SensorRole, bool> get connected => _connected;

  void _updateState(SensorRole role, dynamic data) {
    _latestState[role] = data;
    if (_isRecording) {
      _mergeAndRecord();
    }
    notifyListeners();
  }

  // 合并左右脚数据为一行
  void _mergeAndRecord() {
    // 必须至少有一个IMU和一个压力计有数据才记录
    if (_latestState.isEmpty) return;

    // 获取各部分最新数据 (如果缺失则为null)
    var rP = _latestState[SensorRole.rightPressure];
    var rI = _latestState[SensorRole.rightIMU];
    var lP = _latestState[SensorRole.leftPressure];
    var lI = _latestState[SensorRole.leftIMU];

    // 创建一行数据
    var row = GaitData(
      timestamp: DateTime.now(),
      // Right
      pFirstMetaR: rP?['p1'], pFifthMetaR: rP?['p2'], pHeelR: rP?['p3'],
      accXR: rI?['ax'], accYR: rI?['ay'], accZR: rI?['az'],
      gyroXR: rI?['gx'], gyroYR: rI?['gy'], gyroZR: rI?['gz'],
      rollR: rI?['rx'], pitchR: rI?['py'], yawR: rI?['yz'],
      // Left
      pFirstMetaL: lP?['p1'], pFifthMetaL: lP?['p2'], pHeelL: lP?['p3'],
      accXL: lI?['ax'], accYL: lI?['ay'], accZL: lI?['az'],
      gyroXL: lI?['gx'], gyroYL: lI?['gy'], gyroZL: lI?['gz'],
      rollL: lI?['rx'], pitchL: lI?['py'], yawL: lI?['yz'],
      label: _currentLabel,
    );
    
    _recordedData.add(row);
  }

  // --- 以下为蓝牙解析逻辑 (接收数据后调用 _updateState) ---

  void parsePressureData(SensorRole role, List<double> values) {
    // values = [P1, P2, P3]
    _updateState(role, {'p1': values[0], 'p2': values[1], 'p3': values[2]});
  }

  void parseIMUData(SensorRole role, Map<String, double> imuValues) {
    // imuValues = {'ax':..., 'ay':..., 'az':..., 'gx':..., ...}
    _updateState(role, imuValues);
  }

  void startRecording() {
    _isRecording = true;
    _recordedData.clear();
    notifyListeners();
  }

  void stopRecording() {
    _isRecording = false;
    notifyListeners();
  }
  
  void clearData() {
    _recordedData.clear();
    _latestState.clear();
    notifyListeners();
  }
}
