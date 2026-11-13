
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QuizPlayScreen extends StatefulWidget {
  final String mode;
  final int questionCount;
  final String quizName;
  final String? subjectCode;

  const QuizPlayScreen({
    super.key,
    required this.mode,
    required this.questionCount,
    required this.quizName,
    this.subjectCode,
  });

  @override
  State<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends State<QuizPlayScreen> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> questions = [];

  int currentIndex = 0;
  int correctCount = 0;
  int wrongCount = 0;

  int score = 0;
  int xpEarned = 0;

  int timerSeconds = 20;
  int remainingSeconds = 20;

  int correctPoints = 5;
  int wrongPoints = 0;
  int correctXp = 5;
  int wrongXp = 0;

  int? quizAttemptId;

  String? selectedAnswer;

  bool answered = false;
  bool loading = true;
  bool savingAttempt = false;
  bool attemptSaved = false;
  bool finishing = false;
  bool summarySaved = false;
  bool profileUpdated = false;
  bool timedOut = false;

  String? error;
  String? saveError;

  Timer? quizTimer;

  String get userId => supabase.auth.currentUser!.id;

  bool get isCountryQuiz => widget.mode == 'country_quiz';

  Map<String, dynamic> get currentQuestion =>
      questions[currentIndex];

  @override
  void initState() {
    super.initState();
    loadQuiz();
  }

  @override
  void dispose() {
    quizTimer?.cancel();
    super.dispose();
  }

  int readSetting(
    Map<String, dynamic> settings,
    String key,
    int fallback,
  ) {
    return int.tryParse(settings[key]?.toString() ?? '') ??
        fallback;
  }

  Map<String, String> readOptions(dynamic rawOptions) {
    final result = <String, String>{};
    const keys = ['A', 'B', 'C', 'D'];

    if (rawOptions is Map) {
      for (final entry in rawOptions.entries) {
        final key = entry.key.toString().trim().toUpperCase();
        final value = entry.value?.toString() ?? '';

        if (keys.contains(key) && value.trim().isNotEmpty) {
          result[key] = value;
        }
      }
    } else if (rawOptions is List) {
      for (int i = 0; i < rawOptions.length && i < 4; i++) {
        final value = rawOptions[i]?.toString() ?? '';

        if (value.trim().isNotEmpty) {
          result[keys[i]] = value;
        }
      }
    }

    return result;
  }

  String getCorrectOptionKey(Map<String, dynamic> question) {
    final options = readOptions(question['options']);

    final rawCorrect =
        question['correct_option']?.toString().trim() ?? '';

    final normalized = rawCorrect.toUpperCase();

    if (options.containsKey(normalized)) {
      return normalized;
    }

    for (final entry in options.entries) {
      if (entry.value.trim().toLowerCase() ==
          rawCorrect.toLowerCase()) {
        return entry.key;
      }
    }

    return normalized;
  }

  bool isCorrectAnswer(String? answer) {
    return answer != null &&
        answer == getCorrectOptionKey(currentQuestion);
  }

  Widget buildQuestionImage(String imageUrl) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        maxHeight: 260,
        minHeight: 120,
      ),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF151D18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        imageUrl,
        width: double.infinity,
        height: 220,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;

          return const SizedBox(
            height: 180,
            child: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF27D66B),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return const SizedBox(
            height: 120,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white54,
                    size: 35,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'ছবিটি লোড করা যায়নি',
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> loadQuiz() async {
    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        throw Exception('প্রথমে লগইন করুন।');
      }

      if (isCountryQuiz &&
          (widget.subjectCode == null ||
              widget.subjectCode!.trim().isEmpty)) {
        throw Exception(
          'কোনো দেশ নির্বাচন করা হয়নি। আবার দেশ নির্বাচন করুন।',
        );
      }

      // Admin Panel থেকে কুইজ সেটিংস।
      final settingsData = await supabase
          .from('app_settings')
          .select('key, value')
          .inFilter('key', [
        'quiz_timer_seconds',
        'quiz_correct_points',
        'quiz_wrong_points',
        'quiz_correct_xp',
        'quiz_wrong_xp',
      ]);

      final settings = <String, dynamic>{};

      for (final item in settingsData) {
        settings[item['key'].toString()] = item['value'];
      }

      timerSeconds = readSetting(
        settings,
        'quiz_timer_seconds',
        20,
      ).clamp(1, 300).toInt();

      correctPoints = readSetting(
        settings,
        'quiz_correct_points',
        5,
      ).clamp(0, 100000).toInt();

      // ভুল উত্তরে পয়েন্ট কখনো কমবে না।
      wrongPoints = readSetting(
        settings,
        'quiz_wrong_points',
        0,
      ).clamp(0, 100000).toInt();

      correctXp = readSetting(
        settings,
        'quiz_correct_xp',
        5,
      ).clamp(0, 100000).toInt();

      // ভুল উত্তরে XP কখনো কমবে না।
      wrongXp = readSetting(
        settings,
        'quiz_wrong_xp',
        0,
      ).clamp(0, 100000).toInt();

      // নির্বাচিত মোড অনুযায়ী প্রশ্ন লোড।
      dynamic questionQuery = supabase
          .from('quiz_questions')
          .select()
          .eq('is_published', true);

      if (isCountryQuiz) {
        questionQuery = questionQuery
            .eq('subject_type', 'country')
            .eq('mode', 'country_quiz')
            .eq(
              'subject_code',
              widget.subjectCode!.trim().toUpperCase(),
            );
      } else {
        questionQuery = questionQuery.eq('mode', widget.mode);
      }

      final questionData = await questionQuery;

      // Replay-এর সুবিধার জন্য আগের উত্তর দেওয়া প্রশ্নও রাখা হচ্ছে।
      final availableQuestions =
          List<Map<String, dynamic>>.from(questionData);

      availableQuestions.shuffle();

      final selectedQuestions = availableQuestions
          .take(widget.questionCount)
          .toList();

      if (!mounted) return;

      setState(() {
        questions = selectedQuestions;
        loading = false;
      });

      if (selectedQuestions.isNotEmpty) {
        startTimer();
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Future<void> createQuizAttempt() async {
    if (quizAttemptId != null) return;

    final data = await supabase
        .from('quiz_attempts')
        .insert({
          'user_id': userId,
          'quiz_mode': widget.mode,
          'question_count': questions.length,
          'correct_count': 0,
          'wrong_count': 0,
          'points': 0,
          'xp_earned': 0,
          'completed_at':
              DateTime.now().toUtc().toIso8601String(),
        })
        .select('id')
        .single();

    quizAttemptId = (data['id'] as num).toInt();
  }

  void startTimer() {
    quizTimer?.cancel();

    remainingSeconds = timerSeconds;

    quizTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (!mounted || answered) {
          timer.cancel();
          return;
        }

        if (remainingSeconds > 1) {
          setState(() {
            remainingSeconds--;
          });
        } else {
          timer.cancel();
          _answer(null, isTimeout: true);
        }
      },
    );

    if (mounted) setState(() {});
  }

  Future<void> _answer(
    String? option, {
    bool isTimeout = false,
  }) async {
    if (answered || savingAttempt) return;

    quizTimer?.cancel();

    final isCorrect =
        !isTimeout && isCorrectAnswer(option);

    setState(() {
      selectedAnswer = option;
      answered = true;
      timedOut = isTimeout;
      savingAttempt = true;
      saveError = null;

      if (isCorrect) {
        correctCount++;
        score += correctPoints;
        xpEarned += correctXp;
      } else {
        wrongCount++;
        score += wrongPoints;
        xpEarned += wrongXp;
      }
    });

    await saveQuestionAttempt(isCorrect);
  }

  Future<void> saveQuestionAttempt(bool isCorrect) async {
    try {
      await createQuizAttempt();

      await supabase.from('quiz_question_attempts').insert({
        'user_id': userId,
        'question_id': currentQuestion['id'],
        'quiz_attempt_id': quizAttemptId,
        'selected_option': selectedAnswer,
        'is_correct': isCorrect,
        'status': timedOut ? 'timed_out' : 'answered',
        'attempted_at':
            DateTime.now().toUtc().toIso8601String(),
      });

      if (!mounted) return;

      setState(() {
        attemptSaved = true;
        savingAttempt = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        savingAttempt = false;
        saveError =
            'উত্তর সংরক্ষণ করা যায়নি। আবার চেষ্টা করুন।\n$e';
      });
    }
  }

  Future<void> retrySaveAttempt() async {
    if (savingAttempt || attemptSaved) return;

    setState(() {
      savingAttempt = true;
      saveError = null;
    });

    final isCorrect =
        !timedOut && isCorrectAnswer(selectedAnswer);

    await saveQuestionAttempt(isCorrect);
  }

  void nextQuestion() {
    if (!attemptSaved || savingAttempt) return;

    if (currentIndex < questions.length - 1) {
      setState(() {
        currentIndex++;
        selectedAnswer = null;
        answered = false;
        attemptSaved = false;
        timedOut = false;
        saveError = null;
      });

      startTimer();
    } else {
      finishQuiz();
    }
  }

  Future<void> finishQuiz() async {
    if (finishing) return;

    setState(() {
      finishing = true;
      saveError = null;
    });

    try {
      if (!summarySaved) {
        if (quizAttemptId == null) {
          throw Exception('কুইজের রেকর্ড পাওয়া যায়নি।');
        }

        await supabase
            .from('quiz_attempts')
            .update({
          'question_count': questions.length,
          'correct_count': correctCount,
          'wrong_count': wrongCount,
          'points': score,
          'xp_earned': xpEarned,
          'completed_at':
              DateTime.now().toUtc().toIso8601String(),
        })
            .eq('id', quizAttemptId!)
            .eq('user_id', userId);

        summarySaved = true;
      }

      if (!profileUpdated) {
        final profile = await supabase
            .from('profiles')
            .select('xp, total_points')
            .eq('id', userId)
            .maybeSingle();

        final oldXp =
            (profile?['xp'] as num?)?.toInt() ?? 0;

        final oldPoints =
            (profile?['total_points'] as num?)?.toInt() ?? 0;

        final newXp =
            (oldXp + xpEarned).clamp(0, 2147483647);

        final newPoints =
            (oldPoints + score).clamp(0, 2147483647);

        final newLevel = (newXp ~/ 100) + 1;

        await supabase.from('profiles').upsert({
          'id': userId,
          'xp': newXp,
          'total_points': newPoints,
          'level': newLevel,
        });

        profileUpdated = true;
      }

      if (!mounted) return;

      setState(() {
        currentIndex = questions.length;
        finishing = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        finishing = false;
        saveError =
            'ফলাফল সংরক্ষণে সমস্যা হয়েছে। আবার চেষ্টা করুন।\n$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF27D66B),
          ),
        ),
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('কুইজ')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'কুইজ লোড করা যায়নি:\n$error',
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
          child: Padding(
            padding: EdgeInsets.all(25),
            child: Text(
              'এই কুইজের জন্য এখনো কোনো প্রকাশিত প্রশ্ন নেই। '
              'Admin Panel থেকে প্রশ্ন যোগ করুন।',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (currentIndex >= questions.length) {
      return resultScreen();
    }

    final question = currentQuestion;
    final options = readOptions(question['options']);
    final correct = getCorrectOptionKey(question);

    final imageUrl =
        question['image_url']?.toString().trim() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quizName),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: SingleChildScrollView(
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

              const SizedBox(height: 18),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'সময় বাকি',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '$remainingSeconds সেকেন্ড',
                    style: TextStyle(
                      color: remainingSeconds <= 5
                          ? Colors.redAccent
                          : const Color(0xFF27D66B),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              Text(
                question['question_bn']?.toString() ?? '',
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              if (imageUrl.isNotEmpty)
                buildQuestionImage(imageUrl),

              ...['A', 'B', 'C', 'D'].map((key) {
                final value = options[key] ?? '';

                if (value.isEmpty) {
                  return const SizedBox.shrink();
                }

                final isOptionCorrect = key == correct;
                final isSelected = key == selectedAnswer;

                Color? tileColor;

                if (answered && isOptionCorrect) {
                  tileColor = Colors.green.withOpacity(0.25);
                } else if (answered &&
                    isSelected &&
                    !isOptionCorrect) {
                  tileColor = Colors.red.withOpacity(0.25);
                }

                return Card(
                  color: tileColor,
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(key),
                    ),
                    title: Text(value),
                    trailing: answered && isOptionCorrect
                        ? const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                          )
                        : null,
                    onTap: answered || savingAttempt
                        ? null
                        : () => _answer(key),
                  ),
                );
              }),

              if (answered) ...[
                const SizedBox(height: 12),

                Text(
                  timedOut
                      ? 'সময় শেষ! উত্তর দেওয়া হয়নি।'
                      : isCorrectAnswer(selectedAnswer)
                          ? 'সঠিক উত্তর! +$correctPoints পয়েন্ট'
                          : 'ভুল উত্তর! $wrongPoints পয়েন্ট',
                  style: TextStyle(
                    color: timedOut
                        ? Colors.orange
                        : isCorrectAnswer(selectedAnswer)
                            ? Colors.green
                            : Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'সঠিক উত্তর: $correct'
                  '${options[correct] != null ? ' — ${options[correct]}' : ''}',
                  style: const TextStyle(
                    color: Color(0xFF27D66B),
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  question['explanation_bn']?.toString() ??
                      'কোনো ব্যাখ্যা দেওয়া হয়নি।',
                  style: const TextStyle(
                    color: Colors.white70,
                  ),
                ),

                if (savingAttempt)
                  const Padding(
                    padding: EdgeInsets.all(10),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),

                if (saveError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    saveError!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: retrySaveAttempt,
                    child: const Text('আবার সংরক্ষণ করুন'),
                  ),
                ],

                const SizedBox(height: 18),

                ElevatedButton(
                  onPressed: attemptSaved && !savingAttempt
                      ? nextQuestion
                      : null,
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
      ),
    );
  }

  Widget resultScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('কুইজের ফলাফল'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
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

              const SizedBox(height: 20),

              Text('মোট প্রশ্ন: ${questions.length}'),
              Text('সঠিক উত্তর: $correctCount'),
              Text('ভুল উত্তর: $wrongCount'),

              const SizedBox(height: 12),

              Text(
                'মোট পয়েন্ট: $score',
                style: const TextStyle(
                  fontSize: 23,
                  color: Color(0xFF27D66B),
                  fontWeight: FontWeight.bold,
                ),
              ),

              Text(
                'XP অর্জন: $xpEarned',
                style: const TextStyle(fontSize: 18),
              ),

              const SizedBox(height: 20),

              if (finishing)
                const CircularProgressIndicator(),

              if (saveError != null) ...[
                Text(
                  saveError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: finishQuiz,
                  child: const Text('আবার চেষ্টা করুন'),
                ),
              ],

              if (!summarySaved &&
                  !finishing &&
                  saveError == null)
                ElevatedButton(
                  onPressed: finishQuiz,
                  child: const Text('ফলাফল সংরক্ষণ করুন'),
                ),

              if (summarySaved && profileUpdated)
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
