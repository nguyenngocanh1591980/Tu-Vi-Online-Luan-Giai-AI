import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ZaloOAuthScreen extends StatefulWidget {
  const ZaloOAuthScreen({Key? key}) : super(key: key);

  @override
  _ZaloOAuthScreenState createState() => _ZaloOAuthScreenState();
}

class _ZaloOAuthScreenState extends State<ZaloOAuthScreen> {
  late WebViewController _controller;

  @override
  void initState() {
    super.initState();
    final appId = dotenv.env['ZALO_APP_ID'] ?? '';
    final redirectUri = dotenv.env['ZALO_REDIRECT_URI'] ?? '';
    final authUrl = dotenv.env['ZALO_AUTH_URL'] ?? 'https://oauth.zaloapp.com/v4/permission';

    final loginUrl = '$authUrl?app_id=$appId&redirect_uri=$redirectUri&state=login';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith(redirectUri)) {
              final uri = Uri.parse(request.url);
              final code = uri.queryParameters['code'];
              final oaToken = uri.queryParameters['access_token']; 
              
              if (oaToken != null) {
                 Navigator.pop(context, oaToken);
              } else if (code != null) {
                 Navigator.pop(context, code);
              } else {
                 Navigator.pop(context, null);
              }
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(loginUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Material(color: Colors.transparent, child: 
      appBar: AppBar(
        title: const Text('Đăng nhập Zalo'),
        backgroundColor: const Color(0xFF0068FF),
      ),
      WebViewWidget(controller: _controller),
    );
  }
}
