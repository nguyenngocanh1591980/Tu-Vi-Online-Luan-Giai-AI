import 'package:flutter/material.dart';
import 'dart:async';
import 'package:frontend/screens/chart_screen.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/screens/home_screen.dart';
import 'package:frontend/screens/verify_email_screen.dart';

import 'package:provider/provider.dart';
import 'package:frontend/providers/wallet_provider.dart';
import 'package:frontend/providers/horoscope_provider.dart';
import 'package:frontend/services/signalr_service.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Khởi tạo kết nối WebSocket toàn cục
    await signalRService.initConnection();
    
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
    return MaterialApp(
      title: 'Tử Vi AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red.shade900),
        useMaterial3: true,
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        if (settings.name != null) {
          final uri = Uri.parse(settings.name!);
          if (uri.path == '/verify') {
            final token = uri.queryParameters['token'];
            if (token != null && token.isNotEmpty) {
              return MaterialPageRoute(
                builder: (context) => VerifyEmailScreen(token: token),
              );
            }
          } else if (uri.path == '/login') {
            return MaterialPageRoute(
              builder: (context) => const LoginScreen(initialIsLogin: true),
            );
          }
        }
        return MaterialPageRoute(builder: (context) => const HomeScreen());
      },
    );
  }
}
