
import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://cuvfoltgtopchiugrbuf.supabase.co',
    anonKey: 'sb_publishable_9Ap4_wNTgEujxZy8wq4sKg_x1IsQd8D',
  );

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
      home: const StartupScreen(),
    );
  }
}

class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen>
    with TickerProviderStateMixin {
  bool _showLoading = false;
  bool _finished = false;
  int _progress = 0;

  late AnimationController _blurController;

  @override
  void initState() {
    super.initState();

    _blurController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _startSequence();
  }

  Future<void> _startSequence() async {
    // প্রথম ২ সেকেন্ড Blur থেকে স্পষ্ট হবে
    await _blurController.forward();

    // স্পষ্ট অবস্থায় আরও ৮ সেকেন্ড থাকবে
    await Future.delayed(const Duration(seconds: 4));

    if (!mounted) return;

    setState(() {
      _showLoading = true;
    });

    await _startProgress();
  }

  Future<void> _startProgress() async {
    // ১% থেকে ১০০% পর্যন্ত মোট ৩০ সেকেন্ড
    for (int value = 1; value <= 100; value++) {
      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;

      setState(() {
        _progress = value;
      });
    }

    // ১০০% হওয়ার পর ২ সেকেন্ড থাকবে
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() {
      _finished = true;
    });
  }

  @override
  void dispose() {
    _blurController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_finished) {
      return const AppShell();
    }

    if (_showLoading) {
      return _loadingScreen();
    }

    return _jaberTechScreen();
  }

  Widget _jaberTechScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: AnimatedBuilder(
          animation: _blurController,
          builder: (context, child) {
            final blur = 12 * (1 - _blurController.value);

            return ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: blur,
                sigmaY: blur,
              ),
              child: Opacity(
                opacity: _blurController.value,
                child: child,
              ),
            );
          },
          child: Image.asset(
            'assets/splash/file_00000000c4b4821187bb08373b0fdbb8.png',
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      ),
    );
  }

  Widget _loadingScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/splash/1795784598864.jpg',
            fit: BoxFit.cover,
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 35),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0xCC000000),
                    Colors.black,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Loading...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),

                  const SizedBox(height: 12),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      height: 12,
                      width: double.infinity,
                      color: Colors.white.withOpacity(0.18),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                          width: MediaQuery.of(context).size.width *
                              (_progress / 100),
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFF27D66B),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0xFF27D66B),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    '$_progress%',
                    style: const TextStyle(
                      color: Color(0xFF27D66B),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
