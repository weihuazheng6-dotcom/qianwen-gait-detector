import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/home_screen.dart';
import 'services/ble_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await _requestPermissions();
  runApp(const GaitDetectorApp());
}

Future<void> _requestPermissions() async {
  await [Permission.bluetooth, Permission.bluetoothScan, Permission.bluetoothConnect, Permission.locationWhenInUse, Permission.storage]
      .forEach((p) async { if (await p.isDenied) await p.request(); });
}

class GaitDetectorApp extends StatelessWidget {
  const GaitDetectorApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BLEManager(),
      child: MaterialApp(
        title: '步态检测',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0), brightness: Brightness.light),
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(backgroundColor: Colors.white, foregroundColor: Color(0xFF1565C0), elevation: 1, centerTitle: true, titleTextStyle: TextStyle(color: Color(0xFF1565C0), fontSize: 18, fontWeight: FontWeight.w600)),
          elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)))),
          cardTheme: CardTheme(color: Colors.white, elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
