
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

  void selectQuiz(String quizName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF151D18),
        title: Text(
          quizName,
          style: const TextStyle(color: Colors.white),
        ),
        content: const Text(
          'এই কুইজের প্রশ্নভান্ডার এখনো যুক্ত করা হয়নি। '
          'পরবর্তী ধাপে প্রশ্ন, Difficulty এবং প্রশ্নের সংখ্যা যুক্ত করা হবে।',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'ঠিক আছে',
              style: TextStyle(color: Color(0xFF27D66B)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            'কুইজ নির্বাচন করুন',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'আপনার পছন্দের কুইজ পদ্ধতি বেছে নিন।',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 14),

          ...modes.map(
            (mode) => Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF164B2C),
                  child: Icon(
                    mode.$3,
                    color: const Color(0xFF27D66B),
                  ),
                ),
                title: Text(
                  mode.$1,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(mode.$2),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => selectQuiz(mode.$1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
