import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/gait_data.dart';

class CSVExport {
  static Future<String> save(List<GaitData> data) async {
    final dir=await getExternalStorageDirectory();if(dir==null)throw Exception('No storage');
    final doc=Directory('${dir.path}/Documents');if(!await doc.exists())await doc.create(recursive:true);
    final path='${doc.path}/gait_data_${DateTime.now().millisecondsSinceEpoch}.csv';
    final f=File(path);final w=f.openWrite();w.writeln(GaitData.csvHeader);
    for(final d in data)w.writeln(d.toCsvRow());await w.flush();await w.close();return path;
  }
}
