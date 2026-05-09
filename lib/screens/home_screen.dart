import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/ble_manager.dart';
import '../services/csv_export.dart';
import 'scan_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('步态检测')),
      body: Consumer<BLEManager>(builder:(ctx,ble,_)=>Column(children:[
        Expanded(child:Padding(padding:EdgeInsets.all(12),child:GridView.count(crossAxisCount:2,crossAxisSpacing:12,mainAxisSpacing:12,children:[
          _card(ctx,'右脚压力',SensorRole.rightPressure,_fmtP(ble.pR),ble),_card(ctx,'右脚IMU',SensorRole.rightIMU,_fmtI(ble.iR),ble),
          _card(ctx,'左脚压力',SensorRole.leftPressure,_fmtP(ble.pL),ble),_card(ctx,'左脚IMU',SensorRole.leftIMU,_fmtI(ble.iL),ble)]))),
        _bar(ctx,ble)])));
  }
  Widget _card(BuildContext ctx,String t,SensorRole r,String d,BLEManager b) {
    final s=b.states[r]??ConnectionState.disconnected;final ok=s==ConnectionState.connected;
    return Card(child:InkWell(borderRadius:BorderRadius.circular(8),onTap:()=>ok?_showDetail(ctx,t,d):Navigator.push(ctx,MaterialPageRoute(builder:_=>ScanScreen(role:r))),
      child:Padding(padding:EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text(t,style:TextStyle(fontSize:16,fontWeight:FontWeight.w600,color:Color(0xFF1565C0))),_chip(s)]),SizedBox(height:8),
        Expanded(child:Container(padding:EdgeInsets.all(8),decoration:BoxDecoration(color:Colors.grey[50],borderRadius:BorderRadius.circular(4)),child:Text(ok?d:'等待连接',style:TextStyle(fontSize:14,fontFamily:'monospace'),maxLines:6,overflow:TextOverflow.ellipsis))),
        if(!ok)SizedBox(width:double.infinity,child:ElevatedButton(onPressed:()=>Navigator.push(ctx,MaterialPageRoute(builder:_=>ScanScreen(role:r))),style:ElevatedButton.styleFrom(padding:EdgeInsets.symmetric(vertical:8)),child:Text('连接',style:TextStyle(fontSize:12))))]))));
  }
  Widget _chip(ConnectionState s){Color c;String l;switch(s){case ConnectionState.connected:c=Colors.green;l='已连接';break;case ConnectionState.connecting:c=Colors.orange;l='连接中';break;case ConnectionState.error:c=Colors.red;l='错误';break;default:c=Colors.grey;l='未连接';}
    return Container(padding:EdgeInsets.symmetric(horizontal:8,vertical:2),decoration:BoxDecoration(color:c.withOpacity(0.1),borderRadius:BorderRadius.circular(12),border:Border.all(color:c)),child:Text(l,style:TextStyle(color:c,fontSize:10)));}
  Widget _bar(BuildContext ctx,BLEManager b) {
    return Container(padding:EdgeInsets.all(12),decoration:BoxDecoration(color:Colors.white,boxShadow:[BoxShadow(color:Colors.grey.withOpacity(0.1),offset:Offset(0,-2),blurRadius:4)]),
      child:Column(mainAxisSize:MainAxisSize.min,children:[Row(children:[Expanded(child:TextField(decoration:InputDecoration(labelText:'标签(0-9)',counterText:''),maxLength:1,keyboardType:TextInputType.number,onChanged:(v){if(v.isNotEmpty)b.setLbl(v);},textAlign:TextAlign.center,style:TextStyle(fontSize:16,fontWeight:FontWeight.bold))),
          SizedBox(width:8),SizedBox(width:100,child:ElevatedButton(onPressed:()=>b.rec?b.stopRec():b.startRec(),style:ElevatedButton.styleFrom(backgroundColor:b.rec?Colors.red:Color(0xFF1565C0),padding:EdgeInsets.symmetric(vertical:12)),child:Text(b.rec?'停止':'开始',style:TextStyle(fontSize:14))))]),
        SizedBox(height:8),Row(children:[Expanded(child:ElevatedButton(onPressed:()=>Navigator.push(ctx,MaterialPageRoute(builder:_=>ScanScreen())),style:ElevatedButton.styleFrom(padding:EdgeInsets.symmetric(vertical:10)),child:Text('🔍扫描',style:TextStyle(fontSize:12)))),
          SizedBox(width:8),Expanded(child:ElevatedButton(onPressed:()async{final d=b.getData();if(d.isEmpty){ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content:Text('无数据')));return;}
            try{final p=await CSVExport.save(d);await Share.shareXFiles([XFile(p)],text:'步态数据');ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content:Text('已导出:$p')));}catch(e){ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content:Text('导出失败:$e')));}},style:ElevatedButton.styleFrom(padding:EdgeInsets.symmetric(vertical:10)),child:Text('📤导出',style:TextStyle(fontSize:12)))),
          SizedBox(width:8),Expanded(child:ElevatedButton(onPressed:(){b.disconnectAll();ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content:Text('已断开')));},style:ElevatedButton.styleFrom(backgroundColor:Colors.grey[600],padding:EdgeInsets.symmetric(vertical:10)),child:Text('🔌断开',style:TextStyle(fontSize:12))))])]));
  }
  String _fmtP(PressureData?d)=>d==null?'':'P1:${d.p1.toStringAsFixed(1)}\nP2:${d.p2.toStringAsFixed(1)}\nP3:${d.p3.toStringAsFixed(1)}';
  String _fmtI(IMUData?d)=>d==null?'':'Acc:[${d.accX.toStringAsFixed(3)},${d.accY.toStringAsFixed(3)},${d.accZ.toStringAsFixed(3)}]\nGyro:[${d.gyroX.toStringAsFixed(1)},${d.gyroY.toStringAsFixed(1)},${d.gyroZ.toStringAsFixed(1)}]\nAngle:[${d.roll.toStringAsFixed(1)},${d.pitch.toStringAsFixed(1)},${d.yaw.toStringAsFixed(1)}]';
  void _showDetail(BuildContext ctx,String t,String d) {showDialog(context:ctx,builder:_=>AlertDialog(title:Text(t),content:SingleChildScrollView(child:Text(d,style:TextStyle(fontFamily:'monospace'))),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:Text('关闭'))]));}
}
