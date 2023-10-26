import 'package:flutter/material.dart';
import 'package:flutter_connect4/view/home/home.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  const App app = App();

  runApp(const ProviderScope(child: app));
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Connect Four',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.blue,
          backgroundColor: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
