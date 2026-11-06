
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'quiz_screen.dart';
import 'live_screen.dart';
import 'profile_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;

  final pages = const [
    HomeScreen(),
    QuizScreen(),
    LiveScreen(),
    ProfileScreen(),
    ContactDeveloperScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
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
            label: 'Contact with Developer',
          ),
        ],
      ),
    );
  }
}

class ContactDeveloperScreen extends StatelessWidget {
  const ContactDeveloperScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B120E),
      appBar: AppBar(
        title: const Text('Contact with Developer'),
        backgroundColor: const Color(0xFF111914),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Developer-এর ছবি ও যোগাযোগের তথ্য এখানে দেখানো হবে।\n\n'
            'Admin Panel-এর সঙ্গে সংযোগের কাজ এখনো বাকি।',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.7,
            ),
          ),
        ),
      ),
    );
  }
}
