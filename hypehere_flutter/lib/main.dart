import 'package:flutter/material.dart';
import 'screens/webview_screen.dart';
import 'config/app_config.dart';

void main() {
  runApp(const HypeHereApp());
}

class HypeHereApp extends StatelessWidget {
  const HypeHereApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const WebViewScreen(),
    );
  }
}
