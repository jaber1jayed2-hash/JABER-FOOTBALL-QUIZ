
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'home_screen.dart';
import 'quiz_screen.dart';
import 'live_screen.dart';
import 'profile_screen.dart';
import 'contact_developer_screen.dart';
import 'nickname_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final supabase = Supabase.instance.client;

  StreamSubscription<AuthState>? _authSubscription;

  int index = 0;
  bool _checking = true;
  bool _hasNickname = false;

  String? _checkedUserId;

  final pages = const [
    HomeScreen(),
    QuizScreen(),
    LiveScreen(),
    ProfileScreen(),
    ContactDeveloperScreen(),
  ];

  @override
  void initState() {
    super.initState();

    _checkProfile();

    _authSubscription =
        supabase.auth.onAuthStateChange.listen((data) {
      _checkedUserId = null;
      _checkProfile();
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkProfile() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        _checking = false;
        _hasNickname = false;
        _checkedUserId = null;
      });
      return;
    }

    if (_checkedUserId == user.id && !_checking) {
      return;
    }

    setState(() {
      _checking = true;
    });

    try {
      final profile = await supabase
          .from('profiles')
          .select('display_name')
          .eq('id', user.id)
          .maybeSingle();

      final nickname =
          profile?['display_name']?.toString().trim() ?? '';

      if (!mounted) return;

      setState(() {
        _hasNickname = nickname.isNotEmpty;
        _checkedUserId = user.id;
        _checking = false;
        index = 0;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _checking = false;
        _hasNickname = false;
        _checkedUserId = null;
      });
    }
  }

  void _nicknameSaved() {
    setState(() {
      _hasNickname = true;
      index = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        backgroundColor: Color(0xFF090D0B),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF27D66B),
          ),
        ),
      );
    }

    // Login ছাড়া অ্যাপে প্রবেশ নিষিদ্ধ
    if (supabase.auth.currentUser == null) {
      return const LoginRequiredScreen();
    }

    // Nickname ছাড়া Home-এ প্রবেশ নিষিদ্ধ
    if (!_hasNickname) {
      return NicknameScreen(
        onSaved: _nicknameSaved,
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: index,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) {
          setState(() => index = value);
        },
        backgroundColor: const Color(0xFF111914),
        indicatorColor: const Color(0xFF245D39),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'হোম',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_soccer),
            label: 'কুইজ',
          ),
          NavigationDestination(
            icon: Icon(Icons.scoreboard_outlined),
            label: 'লাইভ স্কোর',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'প্রোফাইল',
          ),
          NavigationDestination(
            icon: Icon(Icons.contact_support_outlined),
            label: 'Contact Us',
          ),
        ],
      ),
    );
  }
}

class LoginRequiredScreen extends StatelessWidget {
  const LoginRequiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090D0B),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.sports_soccer,
                  size: 85,
                  color: Color(0xFF27D66B),
                ),
                const SizedBox(height: 25),
                const Text(
                  'JABER FOOTBALL QUIZ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'অ্যাপে প্রবেশ করতে হলে প্রথমে '
                  'লগইন অথবা নতুন অ্যাকাউন্ট তৈরি করুন।',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AuthDialog(),
                      );
                    },
                    icon: const Icon(Icons.login),
                    label: const Text(
                      'লগইন / অ্যাকাউন্ট তৈরি',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF27D66B),
                      foregroundColor: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
