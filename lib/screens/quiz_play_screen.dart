
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QuizPlayScreen extends StatefulWidget {
  final String mode;
  final String difficulty;
  final int questionCount;
  final String quizName;

  const QuizPlayScreen({
    super.key,
    required this.mode,
    required this.difficulty,
    required this.questionCount,
    required this.quizName,
  });

  @override
  State<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends State<QuizPlayScreen> {
  List<Map<String, dynamic>> questions = [];
  int currentIndex = 0;
  int score = 0;
  String? selectedAnswer;
  bool answered = false;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadQuestions();
  }

  Future<void> loadQuestions() async {
    try {
      final data = await Supabase.instance.client
          .from('quiz_questions')
          .select()
          .eq('mode', widget.mode)
          .eq('difficulty', widget.difficulty)
          .eq('is_published', true)
          .limit(widget.questionCount);

      final loaded = List<Map<String, dynamic>>.from(data);
      loaded.shuffle();

      if (!mounted) return;

      setState(() {
        questions = loaded;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  void chooseAnswer(String option) {
    if (answered) return;

    final question = questions[currentIndex];
    final correct =
        question['correct_option'].toString().trim().toUpperCase();

    setState(() {
      selectedAnswer = option;
      answered = true;

      if (option == correct) {
        score += 5;
      }
    });
  }

  void nextQuestion() {
    if (currentIndex < questions.length - 1) {
      setState(() {
        currentIndex++;
        selectedAnswer = null;
        answered = false;
      });
    } else {
      setState(() {
        currentIndex = questions.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('কুইজ')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'প্রশ্ন লোড করা যায়নি:\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('কুইজ')),
        body: const Center(
          child: Text(
            'এই Mode ও Difficulty-তে কোনো প্রকাশিত প্রশ্ন পাওয়া যায়নি।',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (currentIndex >= questions.length) {
      return resultScreen();
    }

    final question = questions[currentIndex];
    final options = Map<String, dynamic>.from(
      question['options'] as Map,
    );

    final correct =
        question['correct_option'].toString().trim().toUpperCase();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quizName),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'প্রশ্ন ${currentIndex + 1} / ${questions.length}',
              style: const TextStyle(
                color: Color(0xFF27D66B),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: (currentIndex + 1) / questions.length,
              color: const Color(0xFF27D66B),
              backgroundColor: Colors.white12,
            ),
            const SizedBox(height: 25),
            Text(
              question['question_bn']?.toString() ?? '',
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            ...['A', 'B', 'C', 'D'].map((key) {
              final value = options[key]?.toString() ?? '';
              if (value.isEmpty) return const SizedBox.shrink();

              final isCorrect = key == correct;
              final isSelected = key == selectedAnswer;

              Color? tileColor;
              if (answered && isCorrect) {
                tileColor = Colors.green.withValues(alpha: 0.25);
              } else if (answered && isSelected && !isCorrect) {
                tileColor = Colors.red.withValues(alpha: 0.25);
              }

              return Card(
                color: tileColor,
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(key),
                  ),
                  title: Text(value),
                  trailing: answered && isCorrect
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                  onTap: () => chooseAnswer(key),
                ),
              );
            }),

            if (answered) ...[
              const SizedBox(height: 15),
              Text(
                selectedAnswer == correct
                    ? 'সঠিক উত্তর! +৫ পয়েন্ট'
                    : 'ভুল উত্তর! সঠিক উত্তর: $correct',
                style: TextStyle(
                  color: selectedAnswer == correct
                      ? Colors.green
                      : Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                question['explanation_bn']?.toString() ??
                    'কোনো ব্যাখ্যা দেওয়া হয়নি।',
                style: const TextStyle(color: Colors.white70),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: nextQuestion,
                child: Text(
                  currentIndex == questions.length - 1
                      ? 'ফলাফল দেখুন'
                      : 'পরবর্তী প্রশ্ন',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget resultScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('কুইজের ফলাফল')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.emoji_events,
                size: 75,
                color: Color(0xFF27D66B),
              ),
              const SizedBox(height: 20),
              const Text(
                'কুইজ সম্পন্ন!',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                'মোট প্রশ্ন: ${questions.length}',
                style: const TextStyle(fontSize: 18),
              ),
              Text(
                'তোমার স্কোর: $score',
                style: const TextStyle(
                  fontSize: 23,
                  color: Color(0xFF27D66B),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('আবার কুইজ নির্বাচন করুন'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
