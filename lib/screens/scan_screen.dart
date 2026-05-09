import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ble_manager.dart';
import '../models/gait_data.dart';

class ScanScreen extends StatefulWidget {
  final SensorRole? role;
  const ScanScreen({super.key, this.role});
  @override
  State<ScanScreen> createState() => _ScanScreenState();
}
class _ScanScreenState extends State<ScanScreen> {
  int _p=0;Timer?_t;
  @override void initState(){super.initState();Provider.of<BLEManager>(context,listen:false).startScan();_t=Timer.periodic(Duration(seconds:1),(x){if(mounted)setState(()=>_p++);if(_p>=12)x.cancel();});}
  @override void dispose(){_t?.cancel();super.dispose();}
  void _pick(ScanResult r,SensorRole role) {
    final b=Provider.of<BLEManager>(context,listen:false);showDialog(context:context,barrierDismissible:false,builder:_=>Center(child:CircularProgressIndicator()));
    b.connect(r.device,role).then((ok){if(mounted){Navigator.pop(context);ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(ok?'✅已连接':'❌失败')));if(ok)Navigator.pop(context);}});
  }
  void _showRoles(ScanResult r) {
    final avail=[SensorRole.leftPressure,SensorRole.rightPressure,SensorRole.leftIMU,SensorRole.rightIMU].where((x)=>Provider.of<BLEManager>(context,listen:false).devices[x]==null).toList();
    if(avail.isEmpty){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('槽位已满')));return;}
    showModalBottomSheet(context:context,builder:(ctx)=>Column(mainAxisSize:MainAxisSize.min,children:[Padding(padding:EdgeInsets.all(16),child:Text('选择角色',style:TextStyle(fontSize:16,fontWeight:FontWeight.bold))),...avail.map((r)=>ListTile(title:Text(_name(r)),subtitle:Text(r.device.platformName.isNotEmpty?r.device.platformName:r.device.remoteId.str),onTap:(){Navigator.pop(ctx);_pick(r,r);})),SizedBox(height:8)]));
  }
  String _name(SensorRole r)=>{SensorRole.leftPressure:'🦶左脚压力',SensorRole.rightPressure:'🦶右脚压力',SensorRole.leftIMU:'📐左脚IMU',SensorRole.rightIMU:'📐右脚IMU'}[r]??'未知';
  @override Widget build(BuildContext context) {
    return Scaffold(appBar:AppBar(title:Text('扫描设备'),leading:IconButton(icon:Icon(Icons.arrow_back),onPressed:(){Provider.of<BLEManager>(context,listen:false).stopScan();Navigator.pop(context);})),
      body:Consumer<BLEManager>(builder:(ctx,b,_)=>Column(children:[
        Padding(padding:EdgeInsets.all(16),child:Column(children:[LinearProgressIndicator(value:_p/12,backgroundColor:Colors.grey[200],color:Color(0xFF1565C0)),SizedBox(height:8),Text('扫描中...$_p/12秒',style:TextStyle(fontSize:12,color:Colors.grey))])),
        Expanded(child:b.results.isEmpty?Center(child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(Icons.bluetooth_searching,size:48,color:Colors.grey),SizedBox(height:16),Text(_p<12?'搜索中...':'未找到设备',style:TextStyle(color:Colors.grey))])):
          ListView.builder(itemCount:b.results.length,itemBuilder:(_,i){final r=b.results[i];final d=r.device;
            return Card(margin:EdgeInsets.symmetric(horizontal:12,vertical:4),child:ListTile(leading:Icon(Icons.bluetooth),title:Text(d.platformName.isNotEmpty?d.platformName:'未知设备',style:TextStyle(fontSize:14)),subtitle:Text('${d.remoteId.str}\nRSSI:${r.rssi}dBm',style:TextStyle(fontSize:12,color:Colors.grey)),trailing:Icon(Icons.link),onTap:()=>widget.role!=null?_pick(r,widget.role!):_showRoles(r)));}),
        if(widget.role!=null)Container(padding:EdgeInsets.all(12),color:Color(0xFF1565C0).withOpacity(0.1),child:Row(children:[Icon(Icons.info_outline,size:16,color:Color(0xFF1565C0)),SizedBox(width:8),Expanded(child:Text('正在连接:${_name(widget.role!)}',style:TextStyle(fontSize:12,color:Color(0xFF1565C0))))]))])));
  }
}
