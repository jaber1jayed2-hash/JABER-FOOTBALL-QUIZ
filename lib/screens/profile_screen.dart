import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text('আমার প্রোফাইল', style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
          const SizedBox(height: 18),
          const CircleAvatar(
            radius: 42,
            backgroundColor: Color(0xFF245D39),
            child: Icon(Icons.person, size: 45, color: Colors.white),
          ),
          const SizedBox(height: 12),
          const Center(child: Text('অতিথি খেলোয়াড়', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold))),
          const Center(child: Text('অ্যাকাউন্ট তৈরি করলে অগ্রগতি অনলাইনে সংরক্ষিত হবে।',
              style: TextStyle(color: Colors.white60), textAlign: TextAlign.center)),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('অ্যাকাউন্ট ব্যবস্থা'),
                content: const Text('পরবর্তী ধাপে নিরাপদ Registration ও Login যুক্ত করা হবে।'),
                actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('বন্ধ করুন'))],
              ),
            ),
            icon: const Icon(Icons.login),
            label: const Text('লগইন / অ্যাকাউন্ট তৈরি'),
          ),
          const SizedBox(height: 18),
          const Card(child: ListTile(leading: Icon(Icons.star), title: Text('XP'), trailing: Text('0'))),
          const Card(child: ListTile(leading: Icon(Icons.military_tech), title: Text('লেভেল'), trailing: Text('1'))),
          const Card(child: ListTile(leading: Icon(Icons.emoji_events), title: Text('র‍্যাংক'), trailing: Text('--'))),
        ],
      ),
    );
  }
}
