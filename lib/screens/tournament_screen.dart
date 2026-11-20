
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

      if (!mounted) return;

      setState(() {
        tournaments = List<Map<String, dynamic>>.from(response);
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
      case 'upcoming':
        return 'শীঘ্রই শুরু হবে';
      case 'active':
        return 'চলমান';
      case 'completed':
        return 'শেষ হয়েছে';
      case 'cancelled':
        return 'বাতিল';
      default:
        return value?.toString() ?? 'অজানা';
    }
  }

  Color statusColor(dynamic value) {
    switch (value?.toString().toLowerCase()) {
      case 'active':
        return const Color(0xFF27D66B);
      case 'upcoming':
        return Colors.orangeAccent;
      case 'completed':
        return Colors.blueAccent;
      case 'cancelled':
        return Colors.redAccent;
      default:
        return Colors.white70;
    }
  }

  void showTournamentDetails(Map<String, dynamic> tournament) {
    final title = tournament['title']?.toString() ?? 'Tournament';
    final description =
        tournament['description']?.toString() ?? 'কোনো বিবরণ দেওয়া হয়নি।';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF151D18),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
        ),
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
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  detailRow(
                    'অবস্থা',
                    statusText(tournament['status']),
                  ),
                  detailRow(
                    'কুইজের ধরন',
                    tournament['quiz_mode']?.toString() ?? 'নির্ধারিত নয়',
                  ),
                  detailRow(
                    'প্রশ্ন সংখ্যা',
                    tournament['question_count']?.toString() ?? 'নির্ধারিত নয়',
                  ),
                  detailRow(
                    'শুরুর তারিখ',
                    formatDate(tournament['starts_at']),
                  ),
                  detailRow(
                    'শেষের তারিখ',
                    formatDate(tournament['ends_at']),
                  ),
                  detailRow(
                    'সর্বোচ্চ অংশগ্রহণকারী',
                    tournament['max_participants']?.toString() ?? 'সীমা নেই',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'এই টুর্নামেন্টের অংশগ্রহণ ও Stage-এর কার্যক্রম পরবর্তী ধাপে এখানে যুক্ত করা হবে।',
                    style: TextStyle(
                      color: Color(0xFF27D66B),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
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
            width: 145,
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

  Widget buildTournamentCard(Map<String, dynamic> tournament) {
    final imageUrl = tournament['image_url']?.toString() ?? '';
    final title = tournament['title']?.toString() ?? 'নামহীন Tournament';
    final status = tournament['status'];

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      color: const Color(0xFF151D18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.white.withValues(alpha: 0.07),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
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
                errorBuilder: (context, error, stackTrace) {
                  return tournamentImagePlaceholder();
                },
              )
            else
              tournamentImagePlaceholder(),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor(status).withValues(alpha: 0.13),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusText(status),
                          style: TextStyle(
                            color: statusColor(status),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Text(
                    tournament['description']?.toString() ??
                        'কোনো বিবরণ দেওয়া হয়নি।',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white60,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_month,
                        size: 16,
                        color: Color(0xFF27D66B),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        formatDate(tournament['starts_at']),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'বিস্তারিত দেখুন',
                        style: TextStyle(
                          color: Color(0xFF27D66B),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 13,
                        color: Color(0xFF27D66B),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget tournamentImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 155,
      color: const Color(0xFF164B2C),
      child: const Icon(
        Icons.emoji_events,
        size: 55,
        color: Color(0xFF27D66B),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090D0B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF090D0B),
        title: const Text(
          'টুর্নামেন্ট',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: loadTournaments,
            icon: const Icon(Icons.refresh),
            tooltip: 'রিফ্রেশ',
          ),
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
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF164B2C),
                    Color(0xFF102018),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.emoji_events,
                    color: Color(0xFF27D66B),
                    size: 38,
                  ),
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
              'সকল টুর্নামেন্ট',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (loading)
              const Padding(
                padding: EdgeInsets.all(30),
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF27D66B),
                  ),
                ),
              )
            else if (errorMessage != null)
              Column(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.redAccent,
                    size: 42,
                  ),
                  const SizedBox(height: 10),
                  const Text('টুর্নামেন্ট লোড করা যায়নি।'),
                  const SizedBox(height: 6),
                  Text(
                    errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
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
