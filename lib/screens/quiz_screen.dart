
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'quiz_play_screen.dart';
import 'tournament_screen.dart';

class QuizScreen extends StatefulWidget {
  final String? initialCategory;
  final String? initialMode;

  const QuizScreen({
    super.key,
    this.initialCategory,
    this.initialMode,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final SupabaseClient supabase = Supabase.instance.client;

  List<Map<String, dynamic>> subjects = [];

  int minQuestions = 5;
  int maxQuestions = 50;
  int defaultQuestions = 10;

  bool loadingSettings = true;
  bool settingsLoaded = false;
  bool loadingSubjects = false;
  bool modeStarted = false;

  String? subjectError;
  String? activeCategory;

  @override
  void initState() {
    super.initState();

    activeCategory = widget.initialCategory;

    loadQuizSettings();

    if (activeCategory != null) {
      loadSubjects(activeCategory!);
    }
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
      ).clamp(1, 100).toInt();

      int maximum = parseSetting(
        settings['quiz_max_questions'],
        50,
      ).clamp(1, 100).toInt();

      if (maximum < minimum) maximum = minimum;

      int defaultCount = parseSetting(
        settings['quiz_default_questions'],
        10,
      ).clamp(minimum, maximum).toInt();

      if (!mounted) return;

      setState(() {
        minQuestions = minimum;
        maxQuestions = maximum;
        defaultQuestions = defaultCount;
        loadingSettings = false;
        settingsLoaded = true;
      });

      startInitialMode();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        minQuestions = 5;
        maxQuestions = 50;
        defaultQuestions = 10;
        loadingSettings = false;
        settingsLoaded = false;
      });

      startInitialMode();
    }
  }

  void startInitialMode() {
    if (widget.initialMode == null || modeStarted) return;

    modeStarted = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final mode = widget.initialMode!;

      final names = {
        'guess_player': 'Guess the Player',
        'guess_club': 'Guess the Club',
        'guess_jersey': 'Guess the Jersey',
      };

      final name = names[mode];

      if (name == null) {
        showMessage('এই কুইজ মোডটি পাওয়া যায়নি।');
        return;
      }

      openQuestionCountSheet(
        quizName: name,
        mode: mode,
      );
    });
  }

  Future<void> loadSubjects(String category) async {
    setState(() {
      activeCategory = category;
      loadingSubjects = true;
      subjectError = null;
      subjects = [];
    });

    try {
      final data = await supabase
          .from('quiz_subjects')
          .select(
            'subject_code,name_en,name_bn,image_url,is_enabled,sort_order,flag_emoji',
          )
          .eq('subject_type', category)
          .eq('is_enabled', true)
          .order('sort_order', ascending: true);

      if (!mounted) return;

      setState(() {
        subjects = List<Map<String, dynamic>>.from(data);
        loadingSubjects = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loadingSubjects = false;
        subjectError = e.toString();
      });
    }
  }

  String getSubjectName(Map<String, dynamic> subject) {
    final bn = subject['name_bn']?.toString().trim() ?? '';
    final en = subject['name_en']?.toString().trim() ?? '';
    final code = subject['subject_code']?.toString() ?? '';

    if (bn.isNotEmpty) return bn;
    if (en.isNotEmpty) return en;
    return code;
  }

  String getSubjectCode(Map<String, dynamic> subject) {
    return subject['subject_code']
            ?.toString()
            .trim()
            .toUpperCase() ??
        '';
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF164B2C),
      ),
    );
  }

  void selectSubject(Map<String, dynamic> subject) {
    final code = getSubjectCode(subject);

    if (code.isEmpty) {
      showMessage('এই বিষয়ের কোড পাওয়া যায়নি।');
      return;
    }

    final category = activeCategory;
    if (category == null) return;

    final name = getSubjectName(subject);

    final mode = category == 'country'
        ? 'country_quiz'
        : category == 'club'
            ? 'club_quiz'
            : 'player_quiz';

    openQuestionCountSheet(
      quizName: name,
      mode: mode,
      subjectType: category,
      subjectCode: code,
      flag: category == 'country'
          ? subject['flag_emoji']?.toString()
          : null,
    );
  }

  void openQuestionCountSheet({
    required String quizName,
    required String mode,
    String? subjectType,
    String? subjectCode,
    String? flag,
  }) {
    if (loadingSettings) {
      showMessage('কুইজ সেটিংস লোড হচ্ছে। একটু অপেক্ষা করুন।');
      return;
    }

    if (supabase.auth.currentUser == null) {
      showMessage('কুইজ খেলতে প্রথমে লগইন করুন।');
      return;
    }

    int selectedCount = defaultQuestions;

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
            final counts = List<int>.generate(
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
                        if (flag != null && flag.trim().isNotEmpty)
                          Text(
                            flag,
                            style: const TextStyle(fontSize: 32),
                          )
                        else
                          const Icon(
                            Icons.sports_soccer,
                            color: Color(0xFF27D66B),
                            size: 28,
                          ),
                        const SizedBox(width: 12),
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
                      value: selectedCount,
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
                      items: counts.map((count) {
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
                          selectedCount = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'সর্বনিম্ন: $minQuestions টি  •  সর্বোচ্চ: $maxQuestions টি',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
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
                          if (supabase.auth.currentUser == null) {
                            Navigator.pop(sheetContext);
                            showMessage('আপনার লগইন সেশন পাওয়া যায়নি।');
                            return;
                          }

                          final count = selectedCount;

                          Navigator.pop(sheetContext);

                          Navigator.push(
                            this.context,
                            MaterialPageRoute(
                              builder: (_) => QuizPlayScreen(
                                mode: mode,
                                questionCount: count,
                                quizName: quizName,
                                subjectCode: subjectCode,
                                subjectType: subjectType,
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

  void openTournamentQuiz() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TournamentQuizSectionsScreen(),
      ),
    );
  }

  void openQuizMode({
    required String name,
    required String mode,
  }) {
    openQuestionCountSheet(quizName: name, mode: mode);
  }

  Widget buildQuizModeCard({
    required IconData icon,
    required String title,
    required String description,
    required String mode,
  }) {
    return Card(
      color: const Color(0xFF151D18),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withOpacity(0.07)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: loadingSettings
            ? () => showMessage('কুইজ সেটিংস লোড হচ্ছে। একটু অপেক্ষা করুন।')
            : () => openQuizMode(name: title, mode: mode),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF164B2C),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF27D66B),
                  size: 29,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Color(0xFF27D66B),
                size: 17,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTournamentQuizCard() {
    return Card(
      color: const Color(0xFF151D18),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: const Color(0xFF27D66B).withOpacity(0.35),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: openTournamentQuiz,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF164B2C),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: Color(0xFF27D66B),
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tournament Quiz',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'My Quizzes এবং Other Quiz থেকে নির্বাচন করুন।',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Color(0xFF27D66B),
                size: 17,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildQuizMenu() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(18),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF164B2C),
                Color(0xFF102018),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.sports_soccer,
                color: Color(0xFF27D66B),
                size: 35,
              ),
              SizedBox(height: 10),
              Text(
                'আপনার পছন্দের কুইজ খেলুন',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'একটি কুইজ নির্বাচন করুন এবং নিজের ফুটবল জ্ঞান যাচাই করুন।',
                style: TextStyle(
                  color: Colors.white70,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'কুইজ নির্বাচন করুন',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (loadingSettings)
          const LinearProgressIndicator(
            color: Color(0xFF27D66B),
            backgroundColor: Color(0xFF164B2C),
          ),
        buildQuizModeCard(
          icon: Icons.quiz,
          title: 'General MCQ',
          description: 'সাধারণ ফুটবল বিষয়ক বহুনির্বাচনী প্রশ্ন',
          mode: 'general_mcq',
        ),
        const SizedBox(height: 10),
        buildQuizModeCard(
          icon: Icons.stadium,
          title: 'Guess the Stadium',
          description: 'স্টেডিয়াম চিনে সঠিক উত্তর নির্বাচন করুন',
          mode: 'guess_stadium',
        ),
        const SizedBox(height: 10),
        buildQuizModeCard(
          icon: Icons.visibility,
          title: 'Guess the Silhouette',
          description: 'ছায়ার ছবি দেখে সঠিক উত্তর খুঁজুন',
          mode: 'guess_silhouette',
        ),
        const SizedBox(height: 10),
        buildQuizModeCard(
          icon: Icons.lightbulb_outline,
          title: 'Guess the Clues',
          description: 'ইঙ্গিত থেকে ফুটবল বিষয়টি শনাক্ত করুন',
          mode: 'guess_clues',
        ),
        const SizedBox(height: 10),
        buildTournamentQuizCard(),
        const SizedBox(height: 18),
      ],
    );
  }

  Widget buildSubjectCard(Map<String, dynamic> subject) {
    final category = activeCategory;
    final code = getSubjectCode(subject);
    final name = getSubjectName(subject);

    final imageUrl =
        subject['image_url']?.toString().trim() ?? '';

    final flag = subject['flag_emoji']?.toString().trim() ?? '';

    return Card(
      color: const Color(0xFF151D18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: Colors.white.withOpacity(0.06),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => selectSubject(subject),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 14,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (category == 'country' && flag.isNotEmpty)
                Text(
                  flag,
                  style: const TextStyle(fontSize: 38),
                )
              else if (imageUrl.isNotEmpty)
                SizedBox(
                  height: 48,
                  width: 48,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) {
                      return Icon(
                        category == 'club'
                            ? Icons.shield
                            : Icons.person,
                        color: const Color(0xFF27D66B),
                        size: 35,
                      );
                    },
                  ),
                )
              else
                Icon(
                  category == 'club'
                      ? Icons.shield
                      : category == 'player'
                          ? Icons.person
                          : Icons.flag,
                  color: const Color(0xFF27D66B),
                  size: 38,
                ),
              const SizedBox(height: 10),
              Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                code,
                style: const TextStyle(
                  color: Color(0xFF27D66B),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSubjectSection() {
    final category = activeCategory;

    if (category == null) {
      return const SizedBox.shrink();
    }

    final title = category == 'country'
        ? 'দেশ নির্বাচন করুন'
        : category == 'club'
            ? 'ক্লাব নির্বাচন করুন'
            : 'খেলোয়াড় নির্বাচন করুন';

    final subtitle = category == 'country'
        ? 'আপনার পছন্দের দেশের পতাকায় ক্লিক করুন।'
        : category == 'club'
            ? 'আপনার পছন্দের ক্লাব নির্বাচন করুন।'
            : 'আপনার পছন্দের খেলোয়াড় নির্বাচন করুন।';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              category == 'country'
                  ? Icons.flag
                  : category == 'club'
                      ? Icons.shield
                      : Icons.person,
              color: const Color(0xFF27D66B),
              size: 27,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              '${subjects.length} টি',
              style: const TextStyle(
                color: Color(0xFF27D66B),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 18),
        if (loadingSubjects)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(25),
              child: CircularProgressIndicator(
                color: Color(0xFF27D66B),
              ),
            ),
          ),
        if (!loadingSubjects && subjectError != null)
          Column(
            children: [
              Text(
                'তালিকা লোড করা যায়নি:\n$subjectError',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.redAccent,
                ),
              ),
              TextButton(
                onPressed: () => loadSubjects(category),
                child: const Text('আবার চেষ্টা করুন'),
              ),
            ],
          ),
        if (!loadingSubjects &&
            subjectError == null &&
            subjects.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'এখনো কোনো বিষয় যোগ করা হয়নি। Admin Panel থেকে বিষয় যোগ করুন।',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
          ),
        if (!loadingSubjects && subjects.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: subjects.length,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.88,
            ),
            itemBuilder: (context, index) {
              return buildSubjectCard(subjects[index]);
            },
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (activeCategory != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            activeCategory == 'country'
                ? 'দেশভিত্তিক কুইজ'
                : activeCategory == 'club'
                    ? 'ক্লাব কুইজ'
                    : 'প্লেয়ার কুইজ',
          ),
        ),
        body: SafeArea(
          child: RefreshIndicator(
            color: const Color(0xFF27D66B),
            onRefresh: () => loadSubjects(activeCategory!),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(18),
              children: [
                buildSubjectSection(),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('কুইজ'),
      ),
      body: SafeArea(
        child: buildQuizMenu(),
      ),
    );
  }
}

/// Tournament Quiz-এর ভেতরের দুটি বিভাগ।
class TournamentQuizSectionsScreen extends StatelessWidget {
  const TournamentQuizSectionsScreen({super.key});

  void _showMyQuizzesInfo(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'My Quizzes-এর ব্যক্তিগত তালিকা পরবর্তী ধাপে যুক্ত করা হবে।',
        ),
      ),
    );
  }

  void _openOtherQuizzes(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TournamentScreen(),
      ),
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      color: const Color(0xFF151D18),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withOpacity(0.07)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: const Color(0xFF164B2C),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF27D66B),
                  size: 31,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Color(0xFF27D66B),
                size: 17,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090D0B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF090D0B),
        title: const Text('Tournament Quiz'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            'আপনার পছন্দের Tournament Quiz বিভাগ নির্বাচন করুন।',
            style: TextStyle(
              color: Colors.white70,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          _sectionCard(
            icon: Icons.bookmark,
            title: 'My Quizzes',
            description:
                'আপনার অংশগ্রহণ করা বা আপনার জন্য নির্ধারিত কুইজ',
            onTap: () => _showMyQuizzesInfo(context),
          ),
          const SizedBox(height: 12),
          _sectionCard(
            icon: Icons.explore,
            title: 'Other Quiz',
            description:
                'প্রকাশিত Tournament এবং অন্যান্য কুইজ দেখুন',
            onTap: () => _openOtherQuizzes(context),
          ),
        ],
      ),
    );
  }
}
