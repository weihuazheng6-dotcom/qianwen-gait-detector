import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/gait_data.dart';

class CSVExport {
  // 导出CSV到手机内部存储 Documents 目录
  static Future<String?> export(List<GaitData> data) async {
    try {
      if (data.isEmpty) return null;

      // 获取 Documents 目录
      final directory = await getApplicationDocumentsDirectory();
      final dirPath = '${directory.path}/Documents';
      final dir = Directory(dirPath);
      if (!await dir.exists()) await dir.create(recursive: true);

      // 生成文件名
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '$dirPath/gait_data_$timestamp.csv';
      final file = File(filePath);

      // 写入数据
      final sink = file.openWrite();
      
      // 1. 写入表头
      sink.writeln(GaitData.csvHeader);
      
      // 2. 写入每一行
      for (var row in data) {
        sink.writeln(row.toCsvRow());
      }
      
      await sink.flush();
      await sink.close();
      
      return filePath; // 返回文件路径
    } catch (e) {
      print('Export Error: $e');
      return null;
    }
  }
}
