import 'package:flutter/material.dart';
import 'dart:async';
import 'screens/chart_screen.dart';
import 'screens/login_screen.dart';

void main() {
  runZonedGuarded(() {
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.dumpErrorToConsole(details);
      runApp(ErrorWidgetApp(errorDetails: details));
    };
    runApp(const MyApp());
  }, (Object error, StackTrace stack) {
    runApp(ErrorWidgetApp(errorDetails: FlutterErrorDetails(exception: error, stack: stack)));
  });
}

class ErrorWidgetApp extends StatelessWidget {
  final FlutterErrorDetails errorDetails;
  const ErrorWidgetApp({Key? key, required this.errorDetails}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Error')),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Text(
            '${errorDetails.exceptionAsString()}\n\n${errorDetails.stack}',
            style: TextStyle(color: Colors.red, fontSize: 14),
          ),
        ),
      ),
    );
  }
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
      home: LoginScreen(),
    );
  }
}
