import 'package:flutter/material.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final modes = const [
    ('Guess the Club', 'ক্লাবের লোগো দেখে ক্লাব চিনুন', Icons.shield),
    ('Guess the Country', 'পতাকা দেখে দেশ চিনুন', Icons.flag),
    ('Guess the Jersey', 'জার্সি দেখে দল চিনুন', Icons.checkroom),
    ('Guess the Stadium', 'স্টেডিয়ামের ছবি দেখে নাম বলুন', Icons.stadium),
    ('Guess the Silhouette', 'ছায়া দেখে খেলোয়াড় চিনুন', Icons.person_search),
    ('Guess by Clues', 'সূত্র দেখে খেলোয়াড় চিনুন', Icons.lightbulb_outline),
    ('General MCQ', 'সাধারণ ফুটবল প্রশ্ন', Icons.quiz),
    ('Guess the Player', 'ছবি দেখে খেলোয়াড় চিনুন', Icons.sports),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text('কুইজ নির্বাচন করুন', style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('আপনার পছন্দের কুইজ পদ্ধতি বেছে নিন।'),
          const SizedBox(height: 14),
          ...modes.map((mode) => Card(
            child: ListTile(
              leading: Icon(mode.$3, color: const Color(0xFF27D66B)),
              title: Text(mode.$1, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(mode.$2),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(mode.$1),
                  content: const Text('এই কুইজের প্রশ্নভান্ডার পরবর্তী ধাপে যুক্ত করা হবে।'),
                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('ঠিক আছে'))],
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }
}
