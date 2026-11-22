
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TournamentScreen extends StatefulWidget {
  const TournamentScreen({super.key});

  @override
  State<TournamentScreen> createState() => _TournamentScreenState();
}

class _TournamentScreenState extends State<TournamentScreen> {
  final SupabaseClient db = Supabase.instance.client;

  List<Map<String, dynamic>> tournaments = [];
  final Map<String, int> participantCounts = {};
  final Set<String> joinedTournamentIds = {};
  final Set<String> kickedTournamentIds = {};
  final Set<String> joiningTournamentIds = {};

  bool loading = true;
  String? errorMessage;

  static const green = Color(0xFF27D66B);
  static const background = Color(0xFF090D0B);
  static const cardColor = Color(0xFF151D18);

  @override
  void initState() {
    super.initState();
    loadTournaments();
  }

  Future<void> loadTournaments() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final response = await db
          .from('tournaments')
          .select(
            'id,title,description,image_url,quiz_mode,question_count,'
            'starts_at,ends_at,max_participants,status',
          )
          .eq('status', 'published')
          .order('starts_at', ascending: true);

      final loaded = List<Map<String, dynamic>>.from(response);
      final counts = <String, int>{};

      for (final tournament in loaded) {
        final rows = await db
            .from('tournament_participants')
            .select('id')
            .eq('tournament_id', tournament['id'])
            .eq('status', 'joined');

        counts[tournament['id'].toString()] = (rows as List).length;
      }

      final user = db.auth.currentUser;
      final joined = <String>{};
      final kicked = <String>{};

      if (user != null) {
        final rows = await db
            .from('tournament_participants')
            .select('tournament_id,status')
            .eq('user_id', user.id);

        for (final row in rows as List) {
          final id = row['tournament_id'].toString();
          if (row['status'] == 'joined') joined.add(id);
          if (row['status'] == 'kicked') kicked.add(id);
        }
      }

      if (!mounted) return;

      setState(() {
        tournaments = loaded;
        participantCounts
          ..clear()
          ..addAll(counts);
        joinedTournamentIds
          ..clear()
          ..addAll(joined);
        kickedTournamentIds
          ..clear()
          ..addAll(kicked);
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        errorMessage = e.toString();
      });
    }
  }

  String formatDate(dynamic value) {
    if (value == null) return 'নির্ধারিত নয়';
    final date = DateTime.tryParse(value.toString());
    if (date == null) return 'নির্ধারিত নয়';

    final d = date.toLocal();
    return '${d.day}/${d.month}/${d.year}';
  }

  String formatDateTime(dynamic value) {
    if (value == null) return 'সময় নির্ধারিত নয়';

    final date = DateTime.tryParse(value.toString());
    if (date == null) return 'সময় নির্ধারিত নয়';

    final d = date.toLocal();
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final minute = d.minute.toString().padLeft(2, '0');
    final period = d.hour >= 12 ? 'PM' : 'AM';

    return '${d.day}/${d.month}/${d.year} · $hour:$minute $period';
  }

  String statusText(dynamic value) {
    switch (value?.toString().toLowerCase()) {
      case 'published':
        return 'রেজিস্ট্রেশন খোলা';
      case 'ongoing':
      case 'active':
        return 'চলমান';
      case 'completed':
        return 'শেষ হয়েছে';
      case 'cancelled':
        return 'বাতিল';
      case 'scheduled':
        return 'আসন্ন';
      case 'draft':
        return 'প্রকাশিত নয়';
      default:
        return value?.toString() ?? 'অজানা';
    }
  }

  Color statusColor(dynamic value) {
    switch (value?.toString().toLowerCase()) {
      case 'published':
      case 'active':
      case 'ongoing':
        return green;
      case 'scheduled':
        return Colors.orangeAccent;
      case 'completed':
        return Colors.blueAccent;
      case 'cancelled':
      case 'draft':
        return Colors.redAccent;
      default:
        return Colors.white70;
    }
  }

  bool isRegistrationOpen(Map<String, dynamic> tournament) {
    if (tournament['status']?.toString().toLowerCase() != 'published') {
      return false;
    }

    final end = DateTime.tryParse(tournament['ends_at']?.toString() ?? '');
    if (end != null && DateTime.now().isAfter(end.toLocal())) {
      return false;
    }

    final max = int.tryParse(
          tournament['max_participants']?.toString() ?? '',
        ) ??
        0;

    final count = participantCounts[tournament['id'].toString()] ?? 0;
    return max <= 0 || count < max;
  }

  String joinButtonText(Map<String, dynamic> tournament) {
    final id = tournament['id'].toString();

    if (joiningTournamentIds.contains(id)) return 'অপেক্ষা করুন...';
    if (joinedTournamentIds.contains(id)) return 'টুর্নামেন্টে প্রবেশ করুন';
    if (kickedTournamentIds.contains(id)) return 'অংশগ্রহণ বাতিল';

    final max = int.tryParse(
          tournament['max_participants']?.toString() ?? '',
        ) ??
        0;

    final count = participantCounts[id] ?? 0;

    if (max > 0 && count >= max) return 'আসন পূর্ণ';
    if (!isRegistrationOpen(tournament)) return 'Registration বন্ধ';

    return 'Join Tournament';
  }

  Future<bool> joinTournament(Map<String, dynamic> tournament) async {
    final user = db.auth.currentUser;

    if (user == null) {
      showMessage('Join করতে আগে Login করুন।');
      return false;
    }

    final id = tournament['id'].toString();

    if (joinedTournamentIds.contains(id)) {
      showMessage('আপনি ইতিমধ্যে Join করেছেন।');
      return false;
    }

    if (kickedTournamentIds.contains(id)) {
      showMessage('আপনাকে এই Tournament থেকে সরানো হয়েছে।');
      return false;
    }

    if (!isRegistrationOpen(tournament)) {
      showMessage(joinButtonText(tournament));
      return false;
    }

    setState(() => joiningTournamentIds.add(id));

    try {
      final existing = await db
          .from('tournament_participants')
          .select('id,status')
          .eq('tournament_id', tournament['id'])
          .eq('user_id', user.id)
          .maybeSingle();

      if (existing != null) {
        if (existing['status'] == 'joined') {
          if (mounted) {
            setState(() => joinedTournamentIds.add(id));
          }
          showMessage('আপনি ইতিমধ্যে Join করেছেন।');
        } else {
          if (existing['status'] == 'kicked' && mounted) {
            setState(() => kickedTournamentIds.add(id));
          }
          showMessage('আপনার আগের Participant record রয়েছে।');
        }
        return false;
      }

      final activeRows = await db
          .from('tournament_participants')
          .select('id')
          .eq('tournament_id', tournament['id'])
          .eq('status', 'joined');

      final currentCount = (activeRows as List).length;
      final max = int.tryParse(
            tournament['max_participants']?.toString() ?? '',
          ) ??
          0;

      if (max > 0 && currentCount >= max) {
        if (mounted) {
          setState(() => participantCounts[id] = currentCount);
        }
        showMessage('দুঃখিত, আসন পূর্ণ হয়ে গেছে।');
        return false;
      }

      await db.from('tournament_participants').insert({
        'tournament_id': tournament['id'],
        'user_id': user.id,
        'status': 'joined',
      });

      if (!mounted) return true;

      setState(() {
        joinedTournamentIds.add(id);
        participantCounts[id] = currentCount + 1;
      });

      showMessage('সফলভাবে Tournament-এ Join করেছেন!');
      return true;
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        if (mounted) setState(() => joinedTournamentIds.add(id));
        showMessage('আপনি ইতিমধ্যে Join করেছেন।');
      } else {
        showMessage('Join করা যায়নি: ${e.message}');
      }
      return false;
    } catch (e) {
      showMessage('Join করা যায়নি: $e');
      return false;
    } finally {
      if (mounted) {
        setState(() => joiningTournamentIds.remove(id));
      }
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void openTournament(Map<String, dynamic> tournament) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TournamentInsideScreen(
          tournament: tournament,
        ),
      ),
    );
  }

  void showTournamentDetails(Map<String, dynamic> tournament) {
    final id = tournament['id'].toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tournament['title']?.toString() ?? 'Tournament',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tournament['description']?.toString() ??
                        'কোনো বিবরণ দেওয়া হয়নি।',
                    style: const TextStyle(
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  detailRow('অবস্থা', statusText(tournament['status'])),
                  detailRow(
                    'কুইজের ধরন',
                    tournament['quiz_mode']?.toString() ?? 'নির্ধারিত নয়',
                  ),
                  detailRow(
                    'প্রশ্ন সংখ্যা',
                    tournament['question_count']?.toString() ?? 'নির্ধারিত নয়',
                  ),
                  detailRow('শুরুর তারিখ', formatDate(tournament['starts_at'])),
                  detailRow('শেষের তারিখ', formatDate(tournament['ends_at'])),
                  detailRow(
                    'অংশগ্রহণকারী',
                    '${participantCounts[id] ?? 0} / ${tournament['max_participants'] ?? 'সীমা নেই'}',
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: joiningTournamentIds.contains(id) ||
                              joinedTournamentIds.contains(id) ||
                              kickedTournamentIds.contains(id) ||
                              !isRegistrationOpen(tournament)
                          ? null
                          : () async {
                              final success = await joinTournament(tournament);
                              if (success && sheetContext.mounted) {
                                Navigator.pop(sheetContext);
                                openTournament(tournament);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: green,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(joinButtonText(tournament)),
                    ),
                  ),
                  if (joinedTournamentIds.contains(id)) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          openTournament(tournament);
                        },
                        child: const Text('টুর্নামেন্টে প্রবেশ করুন'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget imagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 155,
      color: const Color(0xFF164B2C),
      child: const Icon(
        Icons.emoji_events,
        size: 55,
        color: green,
      ),
    );
  }

  Widget buildTournamentCard(Map<String, dynamic> tournament) {
    final id = tournament['id'].toString();
    final imageUrl = tournament['image_url']?.toString() ?? '';
    final title = tournament['title']?.toString() ?? 'নামহীন Tournament';
    final count = participantCounts[id] ?? 0;
    final joined = joinedTournamentIds.contains(id);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => showTournamentDetails(tournament),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (imageUrl.isNotEmpty)
                  Image.network(
                    imageUrl,
                    width: double.infinity,
                    height: 155,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => imagePlaceholder(),
                  )
                else
                  imagePlaceholder(),
                Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tournament['description']?.toString() ??
                            'কোনো বিবরণ দেওয়া হয়নি।',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white60),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.calendar_month, size: 16, color: green),
                          const SizedBox(width: 6),
                          Text(
                            formatDate(tournament['starts_at']),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '$count / ${tournament['max_participants'] ?? '∞'} জন',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: joiningTournamentIds.contains(id) ||
                        kickedTournamentIds.contains(id) ||
                        (!joined && !isRegistrationOpen(tournament))
                    ? null
                    : joined
                        ? () => openTournament(tournament)
                        : () async {
                            final success = await joinTournament(tournament);
                            if (success && mounted) {
                              openTournament(tournament);
                            }
                          },
                icon: Icon(joined ? Icons.login : Icons.emoji_events),
                label: Text(joinButtonText(tournament)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: Colors.white12,
                  disabledForegroundColor: Colors.white60,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        title: const Text(
          'টুর্নামেন্ট',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: loadTournaments,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadTournaments,
        color: green,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF164B2C), Color(0xFF102018)],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.emoji_events, color: green, size: 38),
                  SizedBox(height: 10),
                  Text(
                    'Tournament Arena',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'অংশ নিন, কুইজ খেলুন এবং নিজের দক্ষতা প্রমাণ করুন।',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'প্রকাশিত টুর্নামেন্ট',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: CircularProgressIndicator(color: green),
                ),
              )
            else if (errorMessage != null)
              Column(
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 42),
                  const SizedBox(height: 10),
                  const Text('টুর্নামেন্ট লোড করা যায়নি।'),
                  Text(
                    errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  TextButton(
                    onPressed: loadTournaments,
                    child: const Text('আবার চেষ্টা করুন'),
                  ),
                ],
              )
            else if (tournaments.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 35),
                child: Column(
                  children: [
                    Icon(
                      Icons.emoji_events_outlined,
                      size: 55,
                      color: Colors.white38,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'এখনো কোনো টুর্নামেন্ট প্রকাশ করা হয়নি।',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white60),
                    ),
                  ],
                ),
              )
            else
              ...tournaments.map(buildTournamentCard),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------
// Joined tournament: My Matches and Other Matches
// ------------------------------------------------------

class TournamentInsideScreen extends StatefulWidget {
  final Map<String, dynamic> tournament;

  const TournamentInsideScreen({
    super.key,
    required this.tournament,
  });

  @override
  State<TournamentInsideScreen> createState() =>
      _TournamentInsideScreenState();
}

class _TournamentInsideScreenState extends State<TournamentInsideScreen> {
  final SupabaseClient db = Supabase.instance.client;

  static const green = Color(0xFF27D66B);
  static const cardColor = Color(0xFF151D18);

  bool loading = true;
  String? error;
  int selectedTab = 0;

  List<Map<String, dynamic>> matches = [];
  Map<String, String> playerNames = {};
  Map<String, String> stageNames = {};
  Map<String, String> roundNames = {};
  Map<String, Map<String, dynamic>> results = {};

  String get tournamentId => widget.tournament['id'].toString();

  @override
  void initState() {
    super.initState();
    loadMatches();
  }

  Future<void> loadMatches() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final user = db.auth.currentUser;
      if (user == null) throw Exception('Login প্রয়োজন।');

      final allRows = await db
          .from('tournament_matches')
          .select(
            'id,tournament_id,round_number,match_number,player1_id,'
            'player2_id,player1_score,player2_score,winner_id,status,'
            'scheduled_at,completed_at,stage_id,round_id',
          )
          .eq('tournament_id', widget.tournament['id'])
          .order('round_number')
          .order('match_number');

      final loaded = List<Map<String, dynamic>>.from(allRows);

      final ids = <String>{};
      for (final match in loaded) {
        if (match['player1_id'] != null) {
          ids.add(match['player1_id'].toString());
        }
        if (match['player2_id'] != null) {
          ids.add(match['player2_id'].toString());
        }
      }

      final names = <String, String>{};
      if (ids.isNotEmpty) {
        final profiles = await db
            .from('profiles')
            .select('id,display_name')
            .inFilter('id', ids.toList());

        for (final profile in profiles as List) {
          names[profile['id'].toString()] =
              profile['display_name']?.toString() ?? 'খেলোয়াড়';
        }
      }

      final stageMap = <String, String>{};
      final stages = await db
          .from('tournament_stages')
          .select('id,stage_name')
          .eq('tournament_id', widget.tournament['id']);

      for (final stage in stages as List) {
        stageMap[stage['id'].toString()] =
            stage['stage_name']?.toString() ?? 'Stage';
      }

      final roundMap = <String, String>{};
      final rounds = await db
          .from('tournament_stage_rounds')
          .select('id,round_name,round_number')
          .eq('tournament_id', widget.tournament['id']);

      for (final round in rounds as List) {
        roundMap[round['id'].toString()] =
            round['round_name']?.toString() ??
                'Round ${round['round_number']}';
      }

      final resultMap = <String, Map<String, dynamic>>{};
      if (loaded.isNotEmpty) {
        final matchIds = loaded.map((m) => m['id']).toList();

        final resultRows = await db
            .from('tournament_match_results')
            .select(
              'match_id,user_id,questions_answered,correct_answers,points',
            )
            .inFilter('match_id', matchIds);

        for (final row in resultRows as List) {
          resultMap[
              '${row['match_id']}_${row['user_id']}'] =
              Map<String, dynamic>.from(row);
        }
      }

      if (!mounted) return;

      setState(() {
        matches = loaded;
        playerNames = names;
        stageNames = stageMap;
        roundNames = roundMap;
        results = resultMap;
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

  String dateTimeText(dynamic value) {
    if (value == null) return 'তারিখ ও সময় নির্ধারিত নয়';

    final date = DateTime.tryParse(value.toString());
    if (date == null) return 'তারিখ ও সময় নির্ধারিত নয়';

    final d = date.toLocal();
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final minute = d.minute.toString().padLeft(2, '0');
    final period = d.hour >= 12 ? 'PM' : 'AM';

    return '${d.day}/${d.month}/${d.year} · $hour:$minute $period';
  }

  String matchStatus(dynamic value) {
    switch (value?.toString().toLowerCase()) {
      case 'scheduled':
        return 'আসন্ন';
      case 'ongoing':
        return 'চলমান';
      case 'completed':
        return 'সম্পন্ন';
      case 'cancelled':
        return 'বাতিল';
      default:
        return value?.toString() ?? 'অজানা';
    }
  }

  Color matchStatusColor(dynamic value) {
    switch (value?.toString().toLowerCase()) {
      case 'scheduled':
        return Colors.orangeAccent;
      case 'ongoing':
        return green;
      case 'completed':
        return Colors.blueAccent;
      case 'cancelled':
        return Colors.redAccent;
      default:
        return Colors.white70;
    }
  }

  bool isMyMatch(Map<String, dynamic> match, String userId) {
    return match['player1_id']?.toString() == userId ||
        match['player2_id']?.toString() == userId;
  }

  List<Map<String, dynamic>> get visibleMatches {
    final userId = db.auth.currentUser?.id;
    if (userId == null) return [];

    if (selectedTab == 0) {
      return matches.where((m) => isMyMatch(m, userId)).toList();
    }

    return matches.where((m) => !isMyMatch(m, userId)).toList();
  }

  String stageRoundText(Map<String, dynamic> match) {
    final stageId = match['stage_id']?.toString();
    final roundId = match['round_id']?.toString();

    final stage = stageNames[stageId] ?? 'Stage';
    final round = roundNames[roundId] ??
        'Round ${match['round_number'] ?? ''}';

    return '$stage · $round';
  }

  void showMatchDetails(Map<String, dynamic> match) {
    final userId = db.auth.currentUser?.id ?? '';
    final p1 = match['player1_id']?.toString() ?? '';
    final p2 = match['player2_id']?.toString() ?? '';

    final result1 = results['${match['id']}_$p1'];
    final result2 = results['${match['id']}_$p2'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Match #${match['match_number']}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  detail('টুর্নামেন্ট', widget.tournament['title']?.toString() ?? ''),
                  detail('স্টেজ ও রাউন্ড', stageRoundText(match)),
                  detail(
                    'তারিখ ও সময়',
                    dateTimeText(match['scheduled_at']),
                  ),
                  detail(
                    'অবস্থা',
                    matchStatus(match['status']),
                  ),
                  const Divider(color: Colors.white24, height: 25),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              playerNames[p1] ?? 'খেলোয়াড় ১',
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              '${match['player1_score'] ?? 0}',
                              style: const TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                color: green,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Text('VS', style: TextStyle(color: Colors.white54)),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              playerNames[p2] ?? 'খেলোয়াড় ২',
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              '${match['player2_score'] ?? 0}',
                              style: const TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                color: green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (match['status']?.toString() == 'completed') ...[
                    const Divider(color: Colors.white24, height: 25),
                    const Text(
                      'খেলোয়াড়দের কুইজের ফলাফল',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    resultDetails('আপনার ফলাফল', result1, userId == p1 ? result1 : result2),
                    resultDetails('অন্য খেলোয়াড়ের ফলাফল', userId == p1 ? result2 : result1, null),
                  ],
                  const SizedBox(height: 15),
                  const Text(
                    'এই স্ক্রিনে ম্যাচের তথ্য দেখা যাবে। ম্যাচ খেলার সুবিধা পরবর্তী ধাপে QuizPlayScreen-এর সঙ্গে যুক্ত হবে।',
                    style: TextStyle(color: Colors.white54, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget resultDetails(
    String title,
    Map<String, dynamic>? result,
    Map<String, dynamic>? ignored,
  ) {
    if (result == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Text('$title: ফলাফল পাওয়া যায়নি',
            style: const TextStyle(color: Colors.white60)),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Text(
        '$title: ${result['questions_answered'] ?? 0} প্রশ্ন · '
        '${result['correct_answers'] ?? 0} সঠিক · '
        '${result['points'] ?? 0} পয়েন্ট',
        style: const TextStyle(color: Colors.white70),
      ),
    );
  }

  Widget detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 115,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget matchCard(Map<String, dynamic> match) {
    final p1 = match['player1_id']?.toString() ?? '';
    final p2 = match['player2_id']?.toString() ?? '';
    final userId = db.auth.currentUser?.id ?? '';
    final mine = isMyMatch(match, userId);

    final opponentId = userId == p1 ? p2 : p1;
    final opponentName = playerNames[opponentId] ?? 'প্রতিপক্ষ';

    final status = match['status'];
    final myResult = results['${match['id']}_$userId'];

    return Card(
      color: cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Match #${match['match_number']}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: matchStatusColor(status).withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    matchStatus(status),
                    style: TextStyle(
                      color: matchStatusColor(status),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Icon(Icons.person, color: green, size: 30),
                      Text(
                        playerNames[p1] ?? 'খেলোয়াড় ১',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const Text(
                  'VS',
                  style: TextStyle(
                    color: green,
                    fontWeight: FontWeight.bold,
                    fontSize: 19,
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      const Icon(Icons.person, color: green, size: 30),
                      Text(
                        playerNames[p2] ?? 'খেলোয়াড় ২',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white12, height: 25),
            detail('প্রতিপক্ষ', opponentName),
            detail('রাউন্ড', stageRoundText(match)),
            detail('তারিখ ও সময়', dateTimeText(match['scheduled_at'])),
            if (mine && myResult != null) ...[
              const SizedBox(height: 8),
              Text(
                'আপনার ফলাফল: ${myResult['questions_answered'] ?? 0} প্রশ্ন · '
                '${myResult['correct_answers'] ?? 0} সঠিক · '
                '${myResult['points'] ?? 0} পয়েন্ট',
                style: const TextStyle(color: green),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => showMatchDetails(match),
                icon: const Icon(Icons.info_outline),
                label: const Text('ম্যাচের বিস্তারিত'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title =
        widget.tournament['title']?.toString() ?? 'Tournament';

    return Scaffold(
      backgroundColor: const Color(0xFF090D0B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF090D0B),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            onPressed: loadMatches,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadMatches,
        color: green,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF164B2C), Color(0xFF102018)],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.emoji_events, color: green, size: 35),
                  SizedBox(height: 8),
                  Text(
                    'Tournament Matches',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'আপনার এবং অন্যান্য খেলোয়াড়দের ম্যাচ দেখুন।',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => selectedTab = 0),
                    icon: const Icon(Icons.person),
                    label: const Text('আমার ম্যাচ'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedTab == 0
                          ? green
                          : cardColor,
                      foregroundColor: selectedTab == 0
                          ? Colors.black
                          : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => selectedTab = 1),
                    icon: const Icon(Icons.groups),
                    label: const Text(
                      'অন্যান্য সকল ম্যাচ',
                      textAlign: TextAlign.center,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedTab == 1
                          ? green
                          : cardColor,
                      foregroundColor: selectedTab == 1
                          ? Colors.black
                          : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              selectedTab == 0 ? 'আমার ম্যাচসমূহ' : 'অন্যান্য খেলোয়াড়দের ম্যাচ',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: CircularProgressIndicator(color: green),
                ),
              )
            else if (error != null)
              Column(
                children: [
                  const Icon(Icons.error_outline,
                      color: Colors.redAccent, size: 40),
                  const SizedBox(height: 8),
                  const Text('ম্যাচ লোড করা যায়নি।'),
                  Text(
                    error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                  TextButton(
                    onPressed: loadMatches,
                    child: const Text('আবার চেষ্টা করুন'),
                  ),
                ],
              )
            else if (visibleMatches.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 35),
                child: Column(
                  children: [
                    Icon(
                      selectedTab == 0
                          ? Icons.sports_soccer
                          : Icons.groups_outlined,
                      color: Colors.white38,
                      size: 50,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      selectedTab == 0
                          ? 'আপনাকে নিয়ে এখনো কোনো ম্যাচ তৈরি করা হয়নি।'
                          : 'অন্য কোনো ম্যাচ পাওয়া যায়নি।',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white60),
                    ),
                  ],
                ),
              )
            else
              ...visibleMatches.map(matchCard),
          ],
        ),
      ),
    );
  }
}
