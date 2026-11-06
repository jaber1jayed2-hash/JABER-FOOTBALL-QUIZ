import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const SizedBox(height: 12),
          const Text('JABER FOOTBALL QUIZ',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, letterSpacing: 1)),
          const SizedBox(height: 6),
          const Text('ফুটবল জানুন, কুইজ খেলুন, বিশ্বকে চ্যালেঞ্জ করুন',
              style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF164B2C), Color(0xFF102018)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.emoji_events, color: Color(0xFF27D66B), size: 36),
                SizedBox(height: 12),
                Text('আজকের চ্যালেঞ্জ', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
                Text('প্রতিদিন কুইজ খেলুন এবং XP অর্জন করুন।'),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text('আপনার ফুটবল জগৎ', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HomeTile(icon: Icons.flag, title: 'দেশভিত্তিক কুইজ'),
              _HomeTile(icon: Icons.shield, title: 'ক্লাব কুইজ'),
              _HomeTile(icon: Icons.person, title: 'খেলোয়াড় কুইজ'),
              _HomeTile(icon: Icons.leaderboard, title: 'লিডারবোর্ড'),
              _HomeTile(icon: Icons.groups, title: 'বন্ধুদের সঙ্গে'),
              _HomeTile(icon: Icons.emoji_events, title: 'টুর্নামেন্ট'),
            ],
          ),
          const SizedBox(height: 20),
          const Text('নোট: লাইভ ডেটা ও অনলাইন ফিচার ব্যাকএন্ড/API যুক্ত করার পর চালু হবে。',
              style: TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }
}

class _HomeTile extends StatelessWidget {
  final IconData icon;
  final String title;
  const _HomeTile({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 155,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              Icon(icon, color: const Color(0xFF27D66B), size: 28),
              const SizedBox(height: 8),
              Text(title, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
