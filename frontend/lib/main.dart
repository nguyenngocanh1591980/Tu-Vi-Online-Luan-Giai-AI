import 'package:flutter/material.dart';
import 'dart:async';

import 'package:provider/provider.dart';
import 'package:frontend/providers/wallet_provider.dart';
import 'package:frontend/providers/horoscope_provider.dart';
import 'package:frontend/providers/forum_category_provider.dart';
import 'package:frontend/providers/draft_provider.dart';
import 'package:frontend/providers/forum_stats_provider.dart';
import 'package:frontend/providers/upload_manager.dart';
import 'package:frontend/services/signalr_service.dart';
import 'package:frontend/router/app_router.dart';
import 'package:frontend/theme/app_theme.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/providers/auth_provider.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(fileName: ".env");

    // Khởi tạo kết nối WebSocket toàn cục Singleton chạy ngầm (không chặn quá trình tải giao diện)
    unawaited(signalRService.startConnection());
    
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
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => WalletProvider()),
          ChangeNotifierProvider(create: (_) => HoroscopeProvider()),
          ChangeNotifierProvider(create: (_) => ForumCategoryProvider()),
          ChangeNotifierProvider(create: (_) => DraftProvider()),
          ChangeNotifierProvider(create: (_) => ForumStatsProvider()),
          ChangeNotifierProvider<UploadManager>.value(value: UploadManager.instance),
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
      theme: AppTheme.lightTheme,
      localizationsDelegates: const [
        FlutterQuillLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: FlutterQuillLocalizations.supportedLocales,
      routerConfig: appRouter,
    );
  }
}
