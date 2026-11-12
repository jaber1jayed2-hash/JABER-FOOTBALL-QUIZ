
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

  int _number(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
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

  void _showDetails(Map<String, dynamic> item) {
    final questions = _number(item['question_count']);
    final correct = _number(item['correct_count']);
    final wrong = _number(item['wrong_count']);
    final points = _number(item['points']);
    final xp = _number(item['xp_earned']);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF151D18),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(22),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                const SizedBox(height: 22),
                const Text(
                  'কুইজের বিস্তারিত ফলাফল',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _modeName(item['quiz_mode']),
                  style: const TextStyle(
                    color: Color(0xFF27D66B),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _dateTime(item['completed_at']),
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 20),
                _detailRow('মোট প্রশ্ন', '$questions'),
                _detailRow('সঠিক উত্তর', '$correct'),
                _detailRow('ভুল উত্তর', '$wrong'),
                const Divider(color: Colors.white12, height: 25),
                _detailRow(
                  'মোট পয়েন্ট',
                  '$points',
                  color: const Color(0xFF27D66B),
                ),
                _detailRow(
                  'অর্জিত XP',
                  '${xp >= 0 ? '+' : ''}$xp XP',
                  color: Colors.orangeAccent,
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF27D66B),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: const Text('বন্ধ করুন'),
                  ),
                ),
              ],
            ),
          ),
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
                      Icon(
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
                          _statCard(
                            'মোট কুইজ',
                            '$totalQuizzes',
                            Icons.quiz,
                          ),
                          _statCard(
                            'মোট প্রশ্ন',
                            '$totalQuestions',
                            Icons.help_outline,
                          ),
                          _statCard(
                            'সঠিক উত্তর',
                            '$totalCorrect',
                            Icons.check_circle_outline,
                          ),
                          _statCard(
                            'ভুল উত্তর',
                            '$totalWrong',
                            Icons.cancel_outlined,
                          ),
                          _statCard(
                            'মোট Points',
                            '$totalPoints',
                            Icons.stars,
                          ),
                          _statCard(
                            'মোট XP',
                            '$totalXP',
                            Icons.bolt,
                          ),
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
                                style: TextStyle(
                                  color: Colors.white70,
                                ),
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
