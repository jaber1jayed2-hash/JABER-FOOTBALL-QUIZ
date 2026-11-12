
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'quiz_play_screen.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final SupabaseClient supabase = Supabase.instance.client;

  final List<(
    String,
    String,
    IconData,
    String,
  )> modes = const [
    (
      'Guess the Club',
      'ক্লাবের লোগো দেখে ক্লাব চিনুন',
      Icons.shield,
      'guess_club',
    ),
    (
      'Guess the Country',
      'পতাকা দেখে দেশ চিনুন',
      Icons.flag,
      'guess_country',
    ),
    (
      'Guess the Jersey',
      'জার্সি দেখে দল চিনুন',
      Icons.checkroom,
      'guess_jersey',
    ),
    (
      'Guess the Stadium',
      'স্টেডিয়ামের ছবি দেখে নাম বলুন',
      Icons.stadium,
      'guess_stadium',
    ),
    (
      'Guess the Silhouette',
      'ছায়া দেখে খেলোয়াড় চিনুন',
      Icons.person_search,
      'guess_silhouette',
    ),
    (
      'Guess by Clues',
      'সূত্র দেখে খেলোয়াড় চিনুন',
      Icons.lightbulb_outline,
      'guess_clues',
    ),
    (
      'General MCQ',
      'সাধারণ ফুটবল প্রশ্ন',
      Icons.quiz,
      'general_mcq',
    ),
    (
      'Guess the Player',
      'ছবি দেখে খেলোয়াড় চিনুন',
      Icons.sports,
      'guess_player',
    ),
  ];

  int minQuestions = 5;
  int maxQuestions = 50;
  int defaultQuestions = 10;

  bool loadingSettings = true;
  bool settingsLoaded = false;

  @override
  void initState() {
    super.initState();
    loadQuizSettings();
  }

  int parseSetting(dynamic value, int fallback) {
    if (value == null) return fallback;

    if (value is int) return value;

    if (value is num) return value.toInt();

    return int.tryParse(value.toString()) ?? fallback;
  }

  Future<void> loadQuizSettings() async {
    try {
      final data = await supabase
          .from('app_settings')
          .select('key, value')
          .inFilter('key', [
        'quiz_min_questions',
        'quiz_max_questions',
        'quiz_default_questions',
      ]);

      final Map<String, dynamic> settings = {};

      for (final row in data) {
        settings[row['key'].toString()] = row['value'];
      }

      int minimum = parseSetting(
        settings['quiz_min_questions'],
        5,
      );

      int maximum = parseSetting(
        settings['quiz_max_questions'],
        50,
      );

      int defaultCount = parseSetting(
        settings['quiz_default_questions'],
        10,
      );

      // নিরাপদ সীমা
      minimum = minimum.clamp(1, 100);
      maximum = maximum.clamp(1, 100);

      if (maximum < minimum) {
        maximum = minimum;
      }

      defaultCount = defaultCount.clamp(
        minimum,
        maximum,
      );

      if (!mounted) return;

      setState(() {
        minQuestions = minimum;
        maxQuestions = maximum;
        defaultQuestions = defaultCount;
        loadingSettings = false;
        settingsLoaded = true;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        minQuestions = 5;
        maxQuestions = 50;
        defaultQuestions = 10;
        loadingSettings = false;
        settingsLoaded = false;
      });
    }
  }

  void selectQuiz(String quizName, String mode) {
    if (loadingSettings) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('কুইজ সেটিংস লোড হচ্ছে। একটু অপেক্ষা করুন।'),
        ),
      );
      return;
    }

    if (supabase.auth.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('কুইজ খেলতে প্রথমে লগইন করুন।'),
        ),
      );
      return;
    }

    int selectedQuestionCount = defaultQuestions;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF151D18),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
        ),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final questionCounts = List<int>.generate(
              maxQuestions - minQuestions + 1,
              (index) => minQuestions + index,
            );

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  24,
                  20,
                  MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.sports_soccer,
                          color: Color(0xFF27D66B),
                          size: 28,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            quizName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    const Text(
                      'প্রশ্নের সংখ্যা নির্বাচন করুন',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 10),

                    DropdownButtonFormField<int>(
                      value: selectedQuestionCount,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF151D18),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.white24,
                          ),
                        ),
                        prefixIcon: const Icon(
                          Icons.format_list_numbered,
                          color: Color(0xFF27D66B),
                        ),
                      ),
                      items: questionCounts.map((count) {
                        return DropdownMenuItem<int>(
                          value: count,
                          child: Text(
                            '$count টি প্রশ্ন',
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;

                        setSheetState(() {
                          selectedQuestionCount = value;
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    Text(
                      'সর্বনিম্ন: $minQuestions টি  •  সর্বোচ্চ: $maxQuestions টি',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF27D66B),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          final user = supabase.auth.currentUser;

                          if (user == null) {
                            Navigator.pop(sheetContext);

                            ScaffoldMessenger.of(this.context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'আপনার লগইন সেশন পাওয়া যায়নি।',
                                ),
                              ),
                            );
                            return;
                          }

                          final count = selectedQuestionCount;

                          Navigator.pop(sheetContext);

                          Navigator.push(
                            this.context,
                            MaterialPageRoute(
                              builder: (_) => QuizPlayScreen(
                                mode: mode,
                                questionCount: count,
                                quizName: quizName,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.play_arrow),
                        label: const Text(
                          'কুইজ শুরু করুন',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget buildModeCard(
    String title,
    String subtitle,
    IconData icon,
    String mode,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 11),
      color: const Color(0xFF151D18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 9,
        ),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: const Color(0xFF164B2C),
          child: Icon(
            icon,
            color: const Color(0xFF27D66B),
            size: 25,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
            ),
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Color(0xFF27D66B),
        ),
        onTap: () => selectQuiz(title, mode),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        color: const Color(0xFF27D66B),
        onRefresh: loadQuizSettings,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(18),
          children: [
            const Text(
              'কুইজ নির্বাচন করুন',
              style: TextStyle(
                color: Colors.white,
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'আপনার পছন্দের ফুটবল কুইজ পদ্ধতি বেছে নিন।',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 18),

            if (loadingSettings)
              const LinearProgressIndicator(
                color: Color(0xFF27D66B),
                backgroundColor: Colors.white12,
              ),

            if (!loadingSettings && !settingsLoaded)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.35),
                  ),
                ),
                child: const Text(
                  'সার্ভারের Quiz Settings লোড করা যায়নি। Default সেটিংস ব্যবহার করা হচ্ছে।',
                  style: TextStyle(
                    color: Colors.orangeAccent,
                    fontSize: 12,
                  ),
                ),
              ),

            if (!loadingSettings && settingsLoaded)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF164B2C).withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'প্রশ্ন নির্বাচন: $minQuestions–$maxQuestions টি',
                  style: const TextStyle(
                    color: Color(0xFF27D66B),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),

            ...modes.map(
              (mode) => buildModeCard(
                mode.$1,
                mode.$2,
                mode.$3,
                mode.$4,
              ),
            ),

            const SizedBox(height: 12),

            const Center(
              child: Text(
                'JABER FOOTBALL QUIZ',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
