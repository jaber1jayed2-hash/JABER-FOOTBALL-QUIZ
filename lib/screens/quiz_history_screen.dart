
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QuizHistoryScreen extends StatefulWidget {
  const QuizHistoryScreen({super.key});

  @override
  State<QuizHistoryScreen> createState() =>
      _QuizHistoryScreenState();
}

class _QuizHistoryScreenState extends State<QuizHistoryScreen> {
  final SupabaseClient supabase = Supabase.instance.client;

  bool loading = true;
  String? errorMessage;

  List<Map<String, dynamic>> history = [];

  int totalQuizzes = 0;
  int totalQuestions = 0;
  int totalCorrect = 0;
  int totalWrong = 0;
  int totalPoints = 0;
  int totalXP = 0;

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  int _number(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<void> loadHistory() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      if (!mounted) return;
      setState(() {
        loading = false;
        errorMessage = 'ইতিহাস দেখতে প্রথমে লগইন করুন।';
      });
      return;
    }

    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final response = await supabase
          .from('quiz_attempts')
          .select(
            'id, quiz_mode, question_count, correct_count, '
            'wrong_count, points, xp_earned, completed_at',
          )
          .eq('user_id', user.id)
          .order('completed_at', ascending: false);

      final records = List<Map<String, dynamic>>.from(response);

      int questions = 0;
      int correct = 0;
      int wrong = 0;
      int points = 0;
      int xp = 0;

      for (final item in records) {
        questions += _number(item['question_count']);
        correct += _number(item['correct_count']);
        wrong += _number(item['wrong_count']);
        points += _number(item['points']);
        xp += _number(item['xp_earned']);
      }

      if (!mounted) return;

      setState(() {
        history = records;
        totalQuizzes = records.length;
        totalQuestions = questions;
        totalCorrect = correct;
        totalWrong = wrong;
        totalPoints = points;
        totalXP = xp;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        errorMessage = 'কুইজের ইতিহাস লোড করা যায়নি।';
      });
    }
  }

  String _modeName(dynamic mode) {
    const modes = {
      'general_mcq': 'সাধারণ MCQ',
      'guess_player': 'প্লেয়ার অনুমান',
      'guess_club': 'ক্লাব অনুমান',
      'guess_country': 'দেশ অনুমান',
      'guess_jersey': 'জার্সি অনুমান',
      'guess_stadium': 'স্টেডিয়াম অনুমান',
      'guess_silhouette': 'সিলুয়েট অনুমান',
      'guess_clues': 'ক্লু থেকে অনুমান',
    };

    final key = mode?.toString() ?? '';
    return modes[key] ?? key.replaceAll('_', ' ').toUpperCase();
  }

  String _dateTime(dynamic value) {
    if (value == null) return 'তারিখ পাওয়া যায়নি';

    final date = DateTime.tryParse(value.toString());
    if (date == null) return 'তারিখ পাওয়া যায়নি';

    final local = date.toLocal();

    String two(int n) => n.toString().padLeft(2, '0');

    return '${two(local.day)}/${two(local.month)}/${local.year} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  // একটি কুইজের সব প্রশ্ন ও উত্তর Supabase থেকে আনা
  Future<List<Map<String, dynamic>>> _loadQuestionReviews(
    dynamic attemptId,
  ) async {
    final response = await supabase
        .from('quiz_question_attempts')
        .select(
          'id, question_id, selected_option, is_correct, '
          'status, attempted_at, '
          'quiz_questions('
          'question_bn, options, correct_option, '
          'explanation_bn, image_url'
          ')',
        )
        .eq('quiz_attempt_id', attemptId)
        .order('attempted_at', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  // Supabase থেকে পাওয়া প্রশ্নের তথ্য বের করা
  Map<String, dynamic> _questionData(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    if (value is List && value.isNotEmpty && value.first is Map) {
      return Map<String, dynamic>.from(value.first);
    }

    return {};
  }

  String _answerText(dynamic value, dynamic options) {
    if (value == null || value.toString().trim().isEmpty) {
      return 'উত্তর দেওয়া হয়নি';
    }

    final answer = value.toString();

    // উত্তরটি A/B/C/D হলে অপশন থেকে সম্পূর্ণ উত্তর দেখানোর চেষ্টা
    if (options is List) {
      const labels = ['A', 'B', 'C', 'D'];

      final index = labels.indexOf(answer.toUpperCase());

      if (index >= 0 && index < options.length) {
        return '${labels[index]}. ${options[index]}';
      }
    }

    if (options is Map) {
      final option = options[answer] ?? options[answer.toUpperCase()];
      if (option != null) {
        return '$answer. $option';
      }
    }

    return answer;
  }

  void _showDetails(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF151D18),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),
      builder: (sheetContext) {
        return _QuizReviewSheet(
          item: item,
          loadReviews: () => _loadQuestionReviews(item['id']),
          modeName: _modeName,
          dateTime: _dateTime,
          questionData: _questionData,
          answerText: _answerText,
          number: _number,
        );
      },
    );
  }

  Widget _detailRow(
    String title,
    String value, {
    Color color = Colors.white,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFF151D18),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF27D66B), size: 22),
          const SizedBox(height: 9),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyCard(Map<String, dynamic> item) {
    final questions = _number(item['question_count']);
    final correct = _number(item['correct_count']);
    final wrong = _number(item['wrong_count']);
    final points = _number(item['points']);
    final xp = _number(item['xp_earned']);

    return InkWell(
      onTap: () => _showDetails(item),
      borderRadius: BorderRadius.circular(17),
      child: Container(
        margin: const EdgeInsets.only(bottom: 13),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF151D18),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF27D66B).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.sports_soccer,
                    color: Color(0xFF27D66B),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _modeName(item['quiz_mode']),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _dateTime(item['completed_at']),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white38,
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 17),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _miniStat('প্রশ্ন', '$questions', Colors.white70),
                _miniStat('সঠিক', '$correct', Colors.greenAccent),
                _miniStat('ভুল', '$wrong', Colors.redAccent),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(color: Colors.white10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '⭐ $points Points',
                  style: const TextStyle(
                    color: Color(0xFF27D66B),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '⚡ ${xp >= 0 ? '+' : ''}$xp XP',
                  style: const TextStyle(
                    color: Colors.orangeAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'বিস্তারিত প্রশ্ন ও উত্তর দেখতে চাপ দিন',
              style: TextStyle(
                color: Color(0xFF27D66B),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090D0B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF090D0B),
        elevation: 0,
        title: const Text(
          'কুইজের ইতিহাস',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: loadHistory,
            tooltip: 'রিফ্রেশ',
            icon: const Icon(
              Icons.refresh,
              color: Color(0xFF27D66B),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadHistory,
        color: const Color(0xFF27D66B),
        child: loading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF27D66B),
                ),
              )
            : errorMessage != null
                ? ListView(
                    children: [
                      const SizedBox(height: 150),
                      const Icon(
                        Icons.error_outline,
                        color: Colors.redAccent,
                        size: 50,
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          errorMessage!,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                      Center(
                        child: TextButton(
                          onPressed: loadHistory,
                          child: const Text('আবার চেষ্টা করুন'),
                        ),
                      ),
                    ],
                  )
                : ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text(
                        'তোমার কুইজ পারফরম্যান্স',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.55,
                        children: [
                          _statCard('মোট কুইজ', '$totalQuizzes', Icons.quiz),
                          _statCard('মোট প্রশ্ন', '$totalQuestions', Icons.help_outline),
                          _statCard('সঠিক উত্তর', '$totalCorrect', Icons.check_circle_outline),
                          _statCard('ভুল উত্তর', '$totalWrong', Icons.cancel_outlined),
                          _statCard('মোট Points', '$totalPoints', Icons.stars),
                          _statCard('মোট XP', '$totalXP', Icons.bolt),
                        ],
                      ),
                      const SizedBox(height: 25),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'সাম্প্রতিক কুইজ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '$totalQuizzes টি',
                            style: const TextStyle(
                              color: Color(0xFF27D66B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (history.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: const Color(0xFF151D18),
                            borderRadius: BorderRadius.circular(17),
                          ),
                          child: const Column(
                            children: [
                              Icon(
                                Icons.history,
                                color: Colors.white38,
                                size: 55,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'এখনো কোনো কুইজের ইতিহাস নেই',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white70),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'কুইজ সম্পন্ন করলে এখানে ফলাফল দেখা যাবে।',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ...history.map(_historyCard),
                    ],
                  ),
      ),
    );
  }
}

// ==========================================
// বিস্তারিত প্রশ্ন ও উত্তর দেখানোর স্ক্রিন
// ==========================================

class _QuizReviewSheet extends StatelessWidget {
  final Map<String, dynamic> item;
  final Future<List<Map<String, dynamic>>> Function() loadReviews;
  final String Function(dynamic) modeName;
  final String Function(dynamic) dateTime;
  final Map<String, dynamic> Function(dynamic) questionData;
  final String Function(dynamic, dynamic) answerText;
  final int Function(dynamic) number;

  const _QuizReviewSheet({
    required this.item,
    required this.loadReviews,
    required this.modeName,
    required this.dateTime,
    required this.questionData,
    required this.answerText,
    required this.number,
  });

  @override
  Widget build(BuildContext context) {
    final questions = number(item['question_count']);
    final correct = number(item['correct_count']);
    final wrong = number(item['wrong_count']);
    final points = number(item['points']);
    final xp = number(item['xp_earned']);

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.88,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 45,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'কুইজের বিস্তারিত ফলাফল',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    modeName(item['quiz_mode']),
                    style: const TextStyle(
                      color: Color(0xFF27D66B),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    dateTime(item['completed_at']),
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _summaryRow('মোট প্রশ্ন', '$questions'),
                  _summaryRow('সঠিক উত্তর', '$correct'),
                  _summaryRow('ভুল উত্তর', '$wrong'),
                  _summaryRow('মোট পয়েন্ট', '$points'),
                  _summaryRow(
                    'অর্জিত XP',
                    '${xp >= 0 ? '+' : ''}$xp XP',
                  ),
                  const Divider(color: Colors.white12, height: 22),
                  const Text(
                    'প্রশ্নভিত্তিক রিভিউ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: loadReviews(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF27D66B),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'প্রশ্নের বিস্তারিত লোড করা যায়নি।\nআবার চেষ্টা করুন।',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    );
                  }

                  final reviews = snapshot.data ?? [];

                  if (reviews.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'এই কুইজের প্রশ্নভিত্তিক রেকর্ড পাওয়া যায়নি।\n'
                          'পুরোনো কুইজে বিস্তারিত উত্তর সংরক্ষিত নাও থাকতে পারে।',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white60),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    itemCount: reviews.length,
                    itemBuilder: (context, index) {
                      final review = reviews[index];
                      final question = questionData(
                        review['quiz_questions'],
                      );

                      final isCorrect = review['is_correct'] == true;
                      final options = question['options'];
                      final selected = answerText(
                        review['selected_option'],
                        options,
                      );
                      final answer = answerText(
                        question['correct_option'],
                        options,
                      );
                      final imageUrl =
                          question['image_url']?.toString().trim() ?? '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: const Color(0xFF090D0B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isCorrect
                                ? Colors.green.withOpacity(0.35)
                                : Colors.redAccent.withOpacity(0.35),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'প্রশ্ন ${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isCorrect
                                        ? Colors.green.withOpacity(0.15)
                                        : Colors.redAccent.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    isCorrect ? 'সঠিক' : 'ভুল',
                                    style: TextStyle(
                                      color: isCorrect
                                          ? Colors.greenAccent
                                          : Colors.redAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 13),
                            Text(
                              question['question_bn']?.toString() ??
                                  'প্রশ্ন পাওয়া যায়নি',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                height: 1.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (imageUrl.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  imageUrl,
                                  width: double.infinity,
                                  height: 190,
                                  fit: BoxFit.contain,
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;
                                    return const SizedBox(
                                      height: 130,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: Color(0xFF27D66B),
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return const SizedBox(
                                      height: 90,
                                      child: Center(
                                        child: Text(
                                          'ছবিটি লোড করা যায়নি',
                                          style: TextStyle(
                                            color: Colors.white54,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                            const SizedBox(height: 15),
                            _answerBox(
                              'আপনার উত্তর',
                              selected,
                              isCorrect
                                  ? Colors.greenAccent
                                  : Colors.redAccent,
                            ),
                            const SizedBox(height: 9),
                            _answerBox(
                              'সঠিক উত্তর',
                              answer,
                              Colors.greenAccent,
                            ),
                            if ((question['explanation_bn'] ?? '')
                                .toString()
                                .trim()
                                .isNotEmpty) ...[
                              const SizedBox(height: 13),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'ব্যাখ্যা',
                                      style: TextStyle(
                                        color: Colors.orangeAccent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      question['explanation_bn'].toString(),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        height: 1.5,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _summaryRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _answerBox(
    String title,
    String value,
    Color color,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
