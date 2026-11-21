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

  @override
  void initState() {
    super.initState();
    loadTournaments();
  }

  Future<void> loadTournaments() async {
    if (mounted) {
      setState(() {
        loading = true;
        errorMessage = null;
      });
    }

    try {
      final response = await db
          .from('tournaments')
          .select(
            'id, title, description, image_url, quiz_mode, '
            'question_count, starts_at, ends_at, '
            'max_participants, status',
          )
          .order('starts_at', ascending: true);

      final loaded = List<Map<String, dynamic>>.from(response);
      final counts = <String, int>{};

      // Participant table/columns match the existing Admin Panel.
      for (final tournament in loaded) {
        final id = tournament['id'].toString();
        final rows = await db
            .from('tournament_participants')
            .select('id')
            .eq('tournament_id', tournament['id'])
            .eq('status', 'joined');
        counts[id] = (rows as List).length;
      }

      final user = db.auth.currentUser;
      final joined = <String>{};
      final kicked = <String>{};
      if (user != null) {
        final myRows = await db
            .from('tournament_participants')
            .select('tournament_id, status')
            .eq('user_id', user.id);
        for (final row in myRows as List) {
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
    final local = date.toLocal();
    return '${local.day}/${local.month}/${local.year}';
  }

  String statusText(dynamic value) {
    switch (value?.toString().toLowerCase()) {
      case 'published':
        return 'রেজিস্ট্রেশন খোলা';
      case 'ongoing':
      case 'active':
        return 'চলমান';
      case 'upcoming':
        return 'শীঘ্রই শুরু হবে';
      case 'completed':
        return 'শেষ হয়েছে';
      case 'cancelled':
        return 'বাতিল';
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
        return const Color(0xFF27D66B);
      case 'upcoming':
      case 'ongoing':
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
    // In the existing Admin Panel, "published" is the public registration state.
    if (tournament['status']?.toString().toLowerCase() != 'published') {
      return false;
    }
    final end = DateTime.tryParse(tournament['ends_at']?.toString() ?? '');
    if (end != null && DateTime.now().isAfter(end.toLocal())) return false;

    final max = int.tryParse(tournament['max_participants']?.toString() ?? '') ?? 0;
    final count = participantCounts[tournament['id'].toString()] ?? 0;
    if (max > 0 && count >= max) return false;
    return true;
  }

  String joinButtonText(Map<String, dynamic> tournament) {
    final id = tournament['id'].toString();
    if (joiningTournamentIds.contains(id)) return 'অপেক্ষা করুন...';
    if (joinedTournamentIds.contains(id)) return 'আপনি Join করেছেন';
    if (kickedTournamentIds.contains(id)) return 'অংশগ্রহণ বাতিল';
    final max = int.tryParse(tournament['max_participants']?.toString() ?? '') ?? 0;
    final count = participantCounts[id] ?? 0;
    if (max > 0 && count >= max) return 'আসন পূর্ণ';
    if (!isRegistrationOpen(tournament)) return 'Registration বন্ধ';
    return 'Join Tournament';
  }

  Future<bool> joinTournament(Map<String, dynamic> tournament) async {
    final user = db.auth.currentUser;
    if (user == null) {
      _showMessage('Tournament-এ Join করতে আগে Login করুন।');
      return false;
    }

    final id = tournament['id'].toString();
    if (joinedTournamentIds.contains(id)) {
      _showMessage('আপনি ইতিমধ্যে এই Tournament-এ Join করেছেন।');
      return false;
    }
    if (kickedTournamentIds.contains(id)) {
      _showMessage('আপনাকে এই Tournament থেকে সরানো হয়েছে।');
      return false;
    }
    if (!isRegistrationOpen(tournament)) {
      _showMessage(joinButtonText(tournament));
      return false;
    }

    setState(() => joiningTournamentIds.add(id));
    try {
      // Prevent a second entry by checking this user's existing participant row.
      final existing = await db
          .from('tournament_participants')
          .select('id, status')
          .eq('tournament_id', tournament['id'])
          .eq('user_id', user.id)
          .maybeSingle();

      if (existing != null) {
        if (existing['status'] == 'joined') {
          if (mounted) setState(() => joinedTournamentIds.add(id));
          _showMessage('আপনি ইতিমধ্যে এই Tournament-এ Join করেছেন।');
        } else {
          if (existing['status'] == 'kicked' && mounted) {
            setState(() => kickedTournamentIds.add(id));
          }
          _showMessage('এই Tournament-এ আপনার আগের Participant record রয়েছে।');
        }
        return false;
      }

      // Recheck available seats immediately before inserting.
      final activeRows = await db
          .from('tournament_participants')
          .select('id')
          .eq('tournament_id', tournament['id'])
          .eq('status', 'joined');
      final currentCount = (activeRows as List).length;
      final max = int.tryParse(tournament['max_participants']?.toString() ?? '') ?? 0;
      if (max > 0 && currentCount >= max) {
        if (mounted) setState(() => participantCounts[id] = currentCount);
        _showMessage('দুঃখিত, এই Tournament-এর আসন পূর্ণ হয়ে গেছে।');
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
      _showMessage('সফলভাবে Tournament-এ Join করেছেন!');
      return true;
    } on PostgrestException catch (e) {
      // A unique constraint, if present, protects against simultaneous double taps/devices.
      if (e.code == '23505') {
        if (mounted) setState(() => joinedTournamentIds.add(id));
        _showMessage('আপনি ইতিমধ্যে এই Tournament-এ Join করেছেন।');
      } else {
        _showMessage('Join করা যায়নি: ${e.message}');
      }
      return false;
    } catch (e) {
      _showMessage('Join করা যায়নি: $e');
      return false;
    } finally {
      if (mounted) setState(() => joiningTournamentIds.remove(id));
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void showTournamentDetails(Map<String, dynamic> tournament) {
    final title = tournament['title']?.toString() ?? 'Tournament';
    final description = tournament['description']?.toString() ?? 'কোনো বিবরণ দেওয়া হয়নি।';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF151D18),
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
                  Center(
                    child: Container(
                      width: 45,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white30,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(description, style: const TextStyle(color: Colors.white70, height: 1.5)),
                  const SizedBox(height: 18),
                  detailRow('অবস্থা', statusText(tournament['status'])),
                  detailRow('কুইজের ধরন', tournament['quiz_mode']?.toString() ?? 'নির্ধারিত নয়'),
                  detailRow('প্রশ্ন সংখ্যা', tournament['question_count']?.toString() ?? 'নির্ধারিত নয়'),
                  detailRow('শুরুর তারিখ', formatDate(tournament['starts_at'])),
                  detailRow('শেষের তারিখ', formatDate(tournament['ends_at'])),
                  detailRow('অংশগ্রহণকারী', '${participantCounts[tournament['id'].toString()] ?? 0} / ${tournament['max_participants'] ?? 'সীমা নেই'}'),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: joiningTournamentIds.contains(tournament['id'].toString()) ||
                              joinedTournamentIds.contains(tournament['id'].toString()) ||
                              kickedTournamentIds.contains(tournament['id'].toString()) ||
                              !isRegistrationOpen(tournament)
                          ? null
                          : () async {
                              final success = await joinTournament(tournament);
                              if (success && sheetContext.mounted) Navigator.pop(sheetContext);
                            },
                      icon: const Icon(Icons.emoji_events),
                      label: Text(joinButtonText(tournament)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF27D66B),
                        foregroundColor: const Color(0xFF07130B),
                        disabledBackgroundColor: Colors.white12,
                        disabledForegroundColor: Colors.white60,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
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
          SizedBox(width: 145, child: Text(label, style: const TextStyle(color: Colors.white54))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget buildTournamentCard(Map<String, dynamic> tournament) {
    final imageUrl = tournament['image_url']?.toString() ?? '';
    final title = tournament['title']?.toString() ?? 'নামহীন Tournament';
    final status = tournament['status'];
    final id = tournament['id'].toString();
    final count = participantCounts[id] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      color: const Color(0xFF151D18),
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
                    errorBuilder: (context, error, stackTrace) => tournamentImagePlaceholder(),
                  )
                else
                  tournamentImagePlaceholder(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 15, 15, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusColor(status).withValues(alpha: 0.13),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              statusText(status),
                              style: TextStyle(color: statusColor(status), fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      Text(
                        tournament['description']?.toString() ?? 'কোনো বিবরণ দেওয়া হয়নি।',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white60, height: 1.4),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.calendar_month, size: 16, color: Color(0xFF27D66B)),
                          const SizedBox(width: 6),
                          Text(formatDate(tournament['starts_at']), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          const Spacer(),
                          Text('$count / ${tournament['max_participants'] ?? '∞'} জন', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(width: 8),
                          const Text('বিস্তারিত', style: TextStyle(color: Color(0xFF27D66B), fontWeight: FontWeight.bold)),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_ios, size: 13, color: Color(0xFF27D66B)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 4, 15, 15),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: joiningTournamentIds.contains(id) ||
                        joinedTournamentIds.contains(id) ||
                        kickedTournamentIds.contains(id) ||
                        !isRegistrationOpen(tournament)
                    ? null
                    : () => joinTournament(tournament),
                icon: Icon(joinedTournamentIds.contains(id) ? Icons.check_circle : Icons.emoji_events),
                label: Text(joinButtonText(tournament)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF27D66B),
                  foregroundColor: const Color(0xFF07130B),
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

  Widget tournamentImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 155,
      color: const Color(0xFF164B2C),
      child: const Icon(Icons.emoji_events, size: 55, color: Color(0xFF27D66B)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090D0B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF090D0B),
        title: const Text('টুর্নামেন্ট', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(onPressed: loadTournaments, icon: const Icon(Icons.refresh), tooltip: 'রিফ্রেশ'),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadTournaments,
        color: const Color(0xFF27D66B),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF164B2C), Color(0xFF102018)]),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.emoji_events, color: Color(0xFF27D66B), size: 38),
                  SizedBox(height: 10),
                  Text('Tournament Arena', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
                  SizedBox(height: 5),
                  Text('অংশ নিন, কুইজ খেলুন এবং নিজের দক্ষতা প্রমাণ করুন।', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const Text('সকল টুর্নামেন্ট', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (loading)
              const Padding(
                padding: EdgeInsets.all(30),
                child: Center(child: CircularProgressIndicator(color: Color(0xFF27D66B))),
              )
            else if (errorMessage != null)
              Column(
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 42),
                  const SizedBox(height: 10),
                  const Text('টুর্নামেন্ট লোড করা যায়নি।'),
                  const SizedBox(height: 6),
                  Text(errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                  TextButton(onPressed: loadTournaments, child: const Text('আবার চেষ্টা করুন')),
                ],
              )
            else if (tournaments.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 35),
                child: Column(
                  children: [
                    Icon(Icons.emoji_events_outlined, size: 55, color: Colors.white38),
                    SizedBox(height: 12),
                    Text('এখনো কোনো টুর্নামেন্ট প্রকাশ করা হয়নি।', textAlign: TextAlign.center, style: TextStyle(color: Colors.white60)),
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
