
import 'package:flutter/material.dart';
import 'quiz_play_screen.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final modes = const [
    ('Guess the Club', 'ক্লাবের লোগো দেখে ক্লাব চিনুন', Icons.shield, 'guess_club'),
    ('Guess the Country', 'পতাকা দেখে দেশ চিনুন', Icons.flag, 'guess_country'),
    ('Guess the Jersey', 'জার্সি দেখে দল চিনুন', Icons.checkroom, 'guess_jersey'),
    ('Guess the Stadium', 'স্টেডিয়ামের ছবি দেখে নাম বলুন', Icons.stadium, 'guess_stadium'),
    ('Guess the Silhouette', 'ছায়া দেখে খেলোয়াড় চিনুন', Icons.person_search, 'guess_silhouette'),
    ('Guess by Clues', 'সূত্র দেখে খেলোয়াড় চিনুন', Icons.lightbulb_outline, 'guess_clues'),
    ('General MCQ', 'সাধারণ ফুটবল প্রশ্ন', Icons.quiz, 'general_mcq'),
    ('Guess the Player', 'ছবি দেখে খেলোয়াড় চিনুন', Icons.sports, 'guess_player'),
  ];

  String difficulty = 'easy';
  int questionCount = 10;

  void selectQuiz(String quizName, String mode) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF151D18),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20, 24, 20,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    quizName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Difficulty নির্বাচন করুন',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: difficulty,
                    dropdownColor: const Color(0xFF151D18),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'easy',
                        child: Text('Easy'),
                      ),
                      DropdownMenuItem(
                        value: 'medium',
                        child: Text('Medium'),
                      ),
                      DropdownMenuItem(
                        value: 'hard',
                        child: Text('Hard'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setSheetState(() => difficulty = value);
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'প্রশ্নের সংখ্যা নির্বাচন করুন',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    value: questionCount,
                    dropdownColor: const Color(0xFF151D18),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: [5, 10, 15, 20].map((count) {
                      return DropdownMenuItem(
                        value: count,
                        child: Text('$count টি প্রশ্ন'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setSheetState(() => questionCount = value);
                      }
                    },
                  ),
                  const SizedBox(height: 25),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);

                      Navigator.push(
                        this.context,
                        MaterialPageRoute(
                          builder: (_) => QuizPlayScreen(
                            mode: mode,
                            difficulty: difficulty,
                            questionCount: questionCount,
                            quizName: quizName,
                          ),
                        ),
                      );
                    },
                    child: const Text('কুইজ শুরু করুন'),
                  ),
                ],
              ),
            );
          },
        );
      },
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
                onTap: () => selectQuiz(mode.$1, mode.$4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
