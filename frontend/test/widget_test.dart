import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:frontend/main.dart';
import 'package:frontend/screens/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/wallet_provider.dart';

void main() {
  testWidgets('Navigate to HomeScreen without crashing', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => WalletProvider()),
        ],
        child: const MyApp(),
      ),
    );
    
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    
    // Check if HomeScreen is present
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
