import 'package:flutter/material.dart';

import 'screens/selector_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RandomSelectApp());
}

class RandomSelectApp extends StatelessWidget {
  const RandomSelectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Random Select',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xffd24040),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xff111318),
        useMaterial3: true,
      ),
      home: const SelectorScreen(),
    );
  }
}
