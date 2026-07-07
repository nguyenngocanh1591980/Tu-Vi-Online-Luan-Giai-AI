import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:frontend/main.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/wallet_provider.dart';

void main() {
  testWidgets('Navigate to HomeScreen without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => WalletProvider()),
        ],
        child: const MyApp(),
      ),
    );
    
    await tester.pumpAndSettle();
    
    // Fill login form
    await tester.enterText(find.byType(TextField).first, 'testuser');
    await tester.enterText(find.byType(TextField).last, 'password');
    
    // Tap login button (assume it has text 'Đăng Nhập')
    // Wait, the button might be inside an InkWell or GestureDetector. Let's find by text.
    final loginButton = find.widgetWithText(ElevatedButton, 'ĐĂNG NHẬP').first;
    await tester.tap(loginButton);
    
    // Pump frames to allow navigation
    await tester.pumpAndSettle();
    
    // Check if HomeScreen is present. HomeScreen has text 'Huyền Học Thời Đại Số'
    expect(find.text('Huyền Học Thời Đại Số'), findsWidgets);
  });
}
