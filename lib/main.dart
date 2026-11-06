import 'package:flutter/material.dart';
import 'screens/app_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const JaberFootballQuizApp());
}

class JaberFootballQuizApp extends StatelessWidget {
  const JaberFootballQuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF27D66B);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'JABER FOOTBALL QUIZ',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF090D0B),
        colorScheme: const ColorScheme.dark(
          primary: green,
          secondary: green,
          surface: Color(0xFF151D18),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF090D0B),
          foregroundColor: Colors.white,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF151D18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        useMaterial3: true,
      ),
      home: const AppShell(),
    );
  }
}
