
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String coverUrl = '';
  String logoUrl = '';
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadHomeSettings();
  }

  Future<void> loadHomeSettings() async {
    try {
      final data = await Supabase.instance.client
          .from('app_settings')
          .select('key, value')
          .inFilter('key', ['home_cover_url', 'home_logo_url']);

      String cover = '';
      String logo = '';

      for (final item in data) {
        final key = item['key'].toString();
        final value = item['value']?.toString() ?? '';

        if (key == 'home_cover_url') {
          cover = value;
        }

        if (key == 'home_logo_url') {
          logo = value;
        }
      }

      if (!mounted) return;

      setState(() {
        coverUrl = cover;
        logoUrl = logo;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }

  Widget buildLogo() {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: const Color(0xFF164B2C),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: logoUrl.isNotEmpty
          ? Image.network(
              logoUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.sports_soccer,
                  color: Color(0xFF27D66B),
                  size: 35,
                );
              },
            )
          : const Icon(
              Icons.sports_soccer,
              color: Color(0xFF27D66B),
              size: 35,
            ),
    );
  }

  Widget buildCover() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: double.infinity,
        height: 190,
        child: coverUrl.isNotEmpty
            ? Image.network(
                coverUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: const Color(0xFF164B2C),
                    child: const Icon(
                      Icons.image,
                      size: 55,
                      color: Colors.white70,
                    ),
                  );
                },
              )
            : Container(
                color: const Color(0xFF164B2C),
                child: const Icon(
                  Icons.image,
                  size: 55,
                  color: Colors.white70,
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: loadHomeSettings,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            // Top Logo
            Row(
              children: [
                buildLogo(),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'JABER FOOTBALL QUIZ',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Cover Header Image
            buildCover(),

            const SizedBox(height: 22),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF164B2C),
                    Color(0xFF102018),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.emoji_events,
                    color: Color(0xFF27D66B),
                    size: 36,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'আজকের চ্যালেঞ্জ',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'প্রতিদিন কুইজ খেলুন এবং XP অর্জন করুন।',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            const Text(
              'আপনার ফুটবল জগৎ',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            const Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _HomeTile(
                  icon: Icons.flag,
                  title: 'দেশভিত্তিক কুইজ',
                ),
                _HomeTile(
                  icon: Icons.shield,
                  title: 'ক্লাব কুইজ',
                ),
                _HomeTile(
                  icon: Icons.person,
                  title: 'খেলোয়াড় কুইজ',
                ),
                _HomeTile(
                  icon: Icons.leaderboard,
                  title: 'লিডারবোর্ড',
                ),
                _HomeTile(
                  icon: Icons.groups,
                  title: 'বন্ধুদের সঙ্গে',
                ),
                _HomeTile(
                  icon: Icons.emoji_events,
                  title: 'টুর্নামেন্ট',
                ),
              ],
            ),

            const SizedBox(height: 20),

            const Text(
              'নোট: লাইভ ডেটা ও অনলাইন ফিচার ব্যাকএন্ড/API যুক্ত করার পর চালু হবে।',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeTile extends StatelessWidget {
  final IconData icon;
  final String title;

  const _HomeTile({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 155,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              Icon(
                icon,
                color: const Color(0xFF27D66B),
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
