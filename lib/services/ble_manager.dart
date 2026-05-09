import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/gait_data.dart';

class BLEManager extends ChangeNotifier {
  static const SCAN_SEC = 12, IMU_INTERVAL = 100, FRAME_LEN = 20, H1 = 0x55, H2 = 0x61;
  static const P_SVC = 'FFE0', P_CHR = 'FFE1';
  static const I_SVC = '0000FFE5-0000-1000-8000-00805F9A34FB', I_NOT = '0000FFE4-0000-1000-8000-00805F9A34FB', I_WR = '0000FFE9-0000-1000-8000-00805F9A34FB';

  final Map<SensorRole, BluetoothDevice?> _dev = {};
  final Map<SensorRole, ConnectionState> _state = {for(var r in SensorRole.values) r: ConnectionState.disconnected};
  PressureData? _pR, _pL; IMUData? _iR, _iL;
  final Map<String, List<int>> _ibu = {}; final Map<String, StringBuffer> _pbu = {};
  final Map<SensorRole, Timer?> _tim = {};
  bool _rec = false; String _lbl = ''; final List<GaitData> _data = [];
  bool _scan = false; final List<ScanResult> _res = [];

  Map<SensorRole, BluetoothDevice?> get devices => _dev;
  Map<SensorRole, ConnectionState> get states => _state;
  PressureData? get pR => _pR; PressureData? get pL => _pL;
  IMUData? get iR => _iR; IMUData? get iL => _iL;
  bool get rec => _rec; String get lbl => _lbl; List<GaitData> get data => List.unmodifiable(_data);
  bool get scanning => _scan; List<ScanResult> get results => List.unmodifiable(_res);

  Future<void> startScan() async {
    if(_scan) return; _scan = true; _res.clear(); _state[SensorRole.unknown]=ConnectionState.scanning; notifyListeners();
    try { await FlutterBluePlus.startScan(timeout: Duration(seconds: SCAN_SEC));
      FlutterBluePlus.scanResults.listen((r){_res.clear();_res.addAll(r);notifyListeners();}, onError:(e)=>_log('Scan:$e'));
      await Future.delayed(Duration(seconds: SCAN_SEC));
    } catch(e){_state[SensorRole.unknown]=ConnectionState.error;}
    finally{_scan=false;_state[SensorRole.unknown]=ConnectionState.disconnected;notifyListeners();}
  }
  Future<void> stopScan() async {await FlutterBluePlus.stopScan();_scan=false;notifyListeners();}

  Future<bool> connect(BluetoothDevice d, SensorRole r) async {
    try { _state[r]=ConnectionState.connecting;notifyListeners();_log('Connect ${d.remoteId.str} as $r');
      await d.connect();_dev[r]=d;await d.discoverServices();
      if(r==SensorRole.leftPressure||r==SensorRole.rightPressure) await _setupP(d,r);
      else if(r==SensorRole.leftIMU||r==SensorRole.rightIMU) await _setupI(d,r);
      _state[r]=ConnectionState.connected;notifyListeners();return true;
    } catch(e){_state[r]=ConnectionState.error;notifyListeners();return false;}
  }

  Future<void> _setupP(BluetoothDevice d, SensorRole r) async {
    final id=d.remoteId.str;_pbu[id]=StringBuffer();
    final s=d.servicesList.firstWhere((x)=>x.uuid.toString().toUpperCase().contains(P_SVC));
    final c=s.characteristics.firstWhere((x)=>x.uuid.toString().toUpperCase().contains(P_CHR));
    await c.setNotifyValue(true);c.lastValueStream.listen((v)=>_parseP(id,v,r));_log('P setup:$id');
  }

  Future<void> _setupI(BluetoothDevice d, SensorRole r) async {
    final id=d.remoteId.str;_ibu[id]=[];
    final s=d.servicesList.firstWhere((x)=>x.uuid.toString().toUpperCase().contains(I_SVC));
    final nc=s.characteristics.firstWhere((x)=>x.uuid.toString().toUpperCase().contains(I_NOT));
    try{await nc.setNotifyValue(true);nc.lastValueStream.listen((v)=>_parseI(id,v,r));}catch(_){}
    _tim[r]=Timer.periodic(Duration(milliseconds:IMU_INTERVAL),(_){});_log('I setup:$id');
  }

  void _parseP(String id, List<int> bytes, SensorRole r) {
    try { final buf=_pbu[id]??=StringBuffer();buf.write(String.fromCharCodes(bytes));final txt=buf.toString();
      for(final f in txt.split(RegExp(r'\$|;')).where((x)=>x.isNotEmpty&&x.contains(','))) {
        final p=f.split(',');if(p.length>=3) {
          final d=PressureData(timestamp:DateTime.now(),deviceId:id,p1:double.tryParse(p[0].trim())??0,p2:double.tryParse(p[1].trim())??0,p3:double.tryParse(p[2].trim())??0);
          if(r==SensorRole.rightPressure)_pR=d;else if(r==SensorRole.leftPressure)_pL=d;_tryRec();notifyListeners();
        }
      }
      if(txt.contains(';')){final l=txt.split(';').last;buf.clear();if(l.startsWith('\$'))buf.write(l);}
    } catch(e){_log('P err:$e');}
  }

  void _parseI(String id, List<int> bytes, SensorRole r) {
    try { final buf=_ibu[id]??=[];buf.addAll(bytes);
      while(buf.length>=FRAME_LEN) { int hi=-1;for(int i=0;i<buf.length-1;i++)if(buf[i]==H1&&buf[i+1]==H2){hi=i;break;}
        if(hi<0){buf.clear();break;}if(hi>0)buf.removeRange(0,hi);if(buf.length<FRAME_LEN)break;
        final fr=buf.sublist(0,FRAME_LEN);buf.removeRange(0,FRAME_LEN);final m=_dec(fr);
        if(m!=null) { final d=IMUData(timestamp:DateTime.now(),deviceId:id,accX:m['aX']!,accY:m['aY']!,accZ:m['aZ']!,gyroX:m['gX']!,gyroY:m['gY']!,gyroZ:m['gZ']!,roll:m['r']!,pitch:m['p']!,yaw:m['y']!);
          if(r==SensorRole.rightIMU)_iR=d;else if(r==SensorRole.leftIMU)_iL=d;_tryRec();notifyListeners();
        }
      }
    } catch(e){_log('I err:$e');}
  }

  Map<String,double>? _dec(List<int> f) {
    if(f.length<FRAME_LEN||f[0]!=H1||f[1]!=H2)return null;
    try { int r16(int o)=>f[o]|(f[o+1]<<8); double a(int v)=>v/32768*16,g(int v)=>v/32768*2000,e(int v)=>v/32768*180;
      return {'aX':a(r16(2)),'aY':a(r16(4)),'aZ':a(r16(6)),'gX':g(r16(8)),'gY':g(r16(10)),'gZ':g(r16(12)),'r':e(r16(14)),'p':e(r16(16)),'y':e(r16(18))};
    } catch(e){_log('Dec err:$e');return null;}
  }

  void _tryRec() { if(!_rec)return; if((_pR!=null||_pL!=null)&&(_iR!=null||_iL!=null)) {
      _data.add(GaitData(timestamp:DateTime.now(),pFirstMetaR:_pR?.p1,pFifthMetaR:_pR?.p2,pHeelR:_pR?.p3,accXR:_iR?.accX,accYR:_iR?.accY,accZR:_iR?.accZ,gyroXR:_iR?.gyroX,gyroYR:_iR?.gyroY,gyroZR:_iR?.gyroZ,rollR:_iR?.roll,pitchR:_iR?.pitch,yawR:_iR?.yaw,pFirstMetaL:_pL?.p1,pFifthMetaL:_pL?.p2,pHeelL:_pL?.p3,accXL:_iL?.accX,accYL:_iL?.accY,accZL:_iL?.accZ,gyroXL:_iL?.gyroX,gyroYL:_iL?.gyroY,gyroZL:_iL?.gyroZ,rollL:_iL?.roll,pitchL:_iL?.pitch,yawL:_iL?.yaw,label:_lbl));
    }
  }

  void startRec(){_rec=true;_data.clear();notifyListeners();}
  void stopRec(){_rec=false;notifyListeners();}
  void setLbl(String l){_lbl=l;notifyListeners();}
  List<GaitData> getData()=>List.unmodifiable(_data);
  void clearData(){_data.clear();notifyListeners();}

  Future<void> disconnect(SensorRole r) async { final d=_dev[r];if(d==null)return;
    try{_tim[r]?.cancel();_tim[r]=null;await d.disconnect();_dev[r]=null;_state[r]=ConnectionState.disconnected;_ibu.remove(d.remoteId.str);_pbu.remove(d.remoteId.str);_clr(r);notifyListeners();}catch(e){_log('Disc:$e');}
  }
  Future<void> disconnectAll() async {for(final r in SensorRole.values)await disconnect(r);_data.clear();notifyListeners();}
  void _clr(SensorRole r){if(r==SensorRole.rightPressure)_pR=null;else if(r==SensorRole.leftPressure)_pL=null;else if(r==SensorRole.rightIMU)_iR=null;else if(r==SensorRole.leftIMU)_iL=null;}
  void _log(String m){if(kDebugMode)print('[${DateTime.now().toIso8601String()}] $m');}
  @override void dispose(){for(final t in _tim.values)t?.cancel();disconnectAll();super.dispose();}
}
