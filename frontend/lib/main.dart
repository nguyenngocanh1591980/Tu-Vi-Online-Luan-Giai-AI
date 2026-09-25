import 'package:flutter/material.dart';
import 'dart:async';

import 'package:provider/provider.dart';
import 'package:frontend/providers/wallet_provider.dart';
import 'package:frontend/providers/horoscope_provider.dart';
import 'package:frontend/services/signalr_service.dart';
import 'package:frontend/router/app_router.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(fileName: ".env");
    
    // Mặc định khởi động ứng dụng luôn ở chế độ Khách xem, xóa sạch session tài khoản cũ
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('jwt_token');
      await prefs.remove('username');
      await prefs.remove('role');
    } catch (e) {
      debugPrint('Error clearing initial auth state: $e');
    }

    // Khởi tạo kết nối WebSocket toàn cục chạy ngầm (không chặn quá trình tải giao diện)
    unawaited(signalRService.initConnection());
    
    // Thiết lập ErrorWidget.builder để hiển thị lỗi ngay trên UI mà không gây crash framework
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Container(
          color: Colors.red.shade900,
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Text(
              '${details.exceptionAsString()}\n\n${details.stack}',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ),
      );
    };

    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.dumpErrorToConsole(details);
    };
    
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => WalletProvider()),
          ChangeNotifierProvider(create: (_) => HoroscopeProvider()),
        ],
        child: const MyApp(),
      ),
    );
  }, (Object error, StackTrace stack) {
    print('ERROR_CAUGHT_BY_ZONE: $error');
    print(stack);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Tử Vi AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red.shade900),
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}
