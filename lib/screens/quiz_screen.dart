
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

  List<Map<String, dynamic>> countries = [];

  int minQuestions = 5;
  int maxQuestions = 50;
  int defaultQuestions = 10;

  bool loadingSettings = true;
  bool settingsLoaded = false;
  bool loadingCountries = true;

  String? countryError;

  String? selectedCountryCode;

  @override
  void initState() {
    super.initState();
    loadAllData();
  }

  int parseSetting(dynamic value, int fallback) {
    if (value == null) return fallback;

    if (value is int) return value;

    if (value is num) return value.toInt();

    return int.tryParse(value.toString()) ?? fallback;
  }

  Future<void> loadAllData() async {
    await Future.wait([
      loadQuizSettings(),
      loadCountries(),
    ]);
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

  Future<void> loadCountries() async {
    try {
      final data = await supabase
          .from('quiz_subjects')
          .select(
            'subject_code,name_en,name_bn,flag_emoji,is_enabled,sort_order',
          )
          .eq('subject_type', 'country')
          .eq('is_enabled', true)
          .order('sort_order', ascending: true);

      if (!mounted) return;

      setState(() {
        countries = List<Map<String, dynamic>>.from(data);
        loadingCountries = false;
        countryError = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loadingCountries = false;
        countryError = e.toString();
      });
    }
  }

  Future<void> refreshAll() async {
    await loadAllData();
  }

  String countryName(Map<String, dynamic> country) {
    return country['name_bn']?.toString().trim().isNotEmpty == true
        ? country['name_bn'].toString()
        : country['name_en']?.toString() ??
            country['subject_code'].toString();
  }

  String countryFlag(Map<String, dynamic> country) {
    final flag = country['flag_emoji']?.toString().trim() ?? '';

    return flag.isEmpty ? '🌍' : flag;
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void selectQuiz(String quizName, String mode) {
    openQuestionCountSheet(
      quizName: quizName,
      mode: mode,
    );
  }

  void selectCountry(Map<String, dynamic> country) {
    final code =
        country['subject_code']?.toString().trim().toUpperCase() ?? '';

    if (code.isEmpty) {
      showMessage('এই দেশের কোড পাওয়া যায়নি।');
      return;
    }

    setState(() {
      selectedCountryCode = code;
    });

    openQuestionCountSheet(
      quizName: countryName(country),
      mode: 'country_quiz',
      subjectCode: code,
      countryFlag: countryFlag(country),
    );
  }

  void openQuestionCountSheet({
    required String quizName,
    required String mode,
    String? subjectCode,
    String? countryFlag,
  }) {
    if (loadingSettings) {
      showMessage('কুইজ সেটিংস লোড হচ্ছে। একটু অপেক্ষা করুন।');
      return;
    }

    if (supabase.auth.currentUser == null) {
      showMessage('কুইজ খেলতে প্রথমে লগইন করুন।');
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
                        if (countryFlag != null)
                          Text(
                            countryFlag,
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
                            showMessage('আপনার লগইন সেশন পাওয়া যায়নি।');
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
                                subjectCode: subjectCode,
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

  Widget buildCountryCard(Map<String, dynamic> country) {
    final code = country['subject_code']?.toString() ?? '';
    final isSelected = selectedCountryCode == code;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => selectCountry(country),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 5,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF164B2C)
                : const Color(0xFF151D18),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF27D66B)
                  : Colors.white.withOpacity(0.07),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                countryFlag(country),
                style: const TextStyle(
                  fontSize: 39,
                ),
              ),

              const SizedBox(height: 9),

              Text(
                countryName(country),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                code,
                style: const TextStyle(
                  color: Color(0xFF27D66B),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildCountrySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(
              Icons.public,
              color: Color(0xFF27D66B),
              size: 25,
            ),

            const SizedBox(width: 9),

            const Expanded(
              child: Text(
                'Country Quiz',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            Text(
              '${countries.length} দেশ',
              style: const TextStyle(
                color: Color(0xFF27D66B),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 7),

        const Text(
          'আপনার পছন্দের দেশের পতাকায় ক্লিক করুন। শুধু সেই দেশের প্রশ্ন আসবে।',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13,
          ),
        ),

        const SizedBox(height: 15),

        if (loadingCountries)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(22),
              child: CircularProgressIndicator(
                color: Color(0xFF27D66B),
              ),
            ),
          ),

        if (!loadingCountries && countryError != null)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text(
                  'দেশের তালিকা লোড করা যায়নি।',
                  style: TextStyle(color: Colors.redAccent),
                ),
                const SizedBox(height: 8),
                Text(
                  countryError!,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                ),
                TextButton(
                  onPressed: loadCountries,
                  child: const Text('আবার চেষ্টা করুন'),
                ),
              ],
            ),
          ),

        if (!loadingCountries &&
            countryError == null &&
            countries.isEmpty)
          const Padding(
            padding: EdgeInsets.all(18),
            child: Text(
              'কোনো সক্রিয় দেশ পাওয়া যায়নি। Admin Panel থেকে দেশ সক্রিয় করুন।',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
          ),

        if (!loadingCountries && countries.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: countries.length,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.88,
            ),
            itemBuilder: (context, index) {
              return buildCountryCard(countries[index]);
            },
          ),
      ],
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
          color: Colors.white.withOpacity(0.05),
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
        onRefresh: refreshAll,
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

            const SizedBox(height: 22),

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
                  color: Colors.orange.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.35),
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
                margin: const EdgeInsets.only(bottom: 18),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF164B2C).withOpacity(0.35),
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

            buildCountrySection(),

            const SizedBox(height: 28),

            const Divider(color: Colors.white24),

            const SizedBox(height: 15),

            const Text(
              'সাধারণ ফুটবল কুইজ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 7),

            const Text(
              'এখানে আগের ৮টি কুইজ পদ্ধতি রয়েছে।',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 15),

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
