
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'quiz_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String coverUrl = '';
  String logoUrl = '';
  String? loadError;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadHomeSettings();
  }

  Future<void> loadHomeSettings() async {
    if (mounted) {
      setState(() {
        loading = true;
        loadError = null;
      });
    }

    try {
      final data = await Supabase.instance.client
          .from('app_settings')
          .select('key, value')
          .inFilter('key', [
        'home_cover_url',
        'home_logo_url',
      ]);

      String cover = '';
      String logo = '';

      for (final item in data) {
        final key = item['key']?.toString() ?? '';
        final value = item['value']?.toString() ?? '';

        if (key == 'home_cover_url') {
          cover = value;
        } else if (key == 'home_logo_url') {
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
        loadError = e.toString();
      });
    }
  }

  void openFeature(String title) {
    if (title == 'দেশভিত্তিক কুইজ' ||
        title == 'ক্লাব কুইজ' ||
        title == 'খেলোয়াড় কুইজ') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const QuizScreen(),
        ),
      );
      return;
    }

    String message;

    switch (title) {
      case 'লিডারবোর্ড':
        message = 'লিডারবোর্ড পেজ পরবর্তী ধাপে চালু করা হবে।';
        break;
      case 'বন্ধুদের সঙ্গে':
        message = 'বন্ধুদের ফিচার পরবর্তী ধাপে চালু করা হবে।';
        break;
      case 'টুর্নামেন্ট':
        message = 'টুর্নামেন্ট পেজ পরবর্তী ধাপে চালু করা হবে।';
        break;
      case 'মাল্টিপ্লেয়ার':
        message = 'মাল্টিপ্লেয়ার পেজ পরবর্তী ধাপে চালু করা হবে।';
        break;
      default:
        message = 'ফিচারটি শিগগিরই চালু হবে।';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF164B2C),
      ),
    );
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
                      Icons.broken_image,
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
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(18),
          children: [
            if (loading)
              const LinearProgressIndicator(
                color: Color(0xFF27D66B),
                backgroundColor: Color(0xFF164B2C),
              ),

            if (loadError != null) ...[
              const SizedBox(height: 10),
              Text(
                'সেটিংস লোড করা যায়নি: $loadError',
                style: const TextStyle(color: Colors.redAccent),
              ),
              TextButton(
                onPressed: loadHomeSettings,
                child: const Text('আবার চেষ্টা করুন'),
              ),
            ],

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

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _HomeTile(
                  icon: Icons.flag,
                  title: 'দেশভিত্তিক কুইজ',
                  onTap: () => openFeature('দেশভিত্তিক কুইজ'),
                ),
                _HomeTile(
                  icon: Icons.shield,
                  title: 'ক্লাব কুইজ',
                  onTap: () => openFeature('ক্লাব কুইজ'),
                ),
                _HomeTile(
                  icon: Icons.person,
                  title: 'খেলোয়াড় কুইজ',
                  onTap: () => openFeature('খেলোয়াড় কুইজ'),
                ),
                _HomeTile(
                  icon: Icons.leaderboard,
                  title: 'লিডারবোর্ড',
                  onTap: () => openFeature('লিডারবোর্ড'),
                ),
                _HomeTile(
                  icon: Icons.groups,
                  title: 'বন্ধুদের সঙ্গে',
                  onTap: () => openFeature('বন্ধুদের সঙ্গে'),
                ),
                _HomeTile(
                  icon: Icons.emoji_events,
                  title: 'টুর্নামেন্ট',
                  onTap: () => openFeature('টুর্নামেন্ট'),
                ),
                _HomeTile(
                  icon: Icons.sports_esports,
                  title: 'মাল্টিপ্লেয়ার',
                  onTap: () => openFeature('মাল্টিপ্লেয়ার'),
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
  final VoidCallback onTap;

  const _HomeTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 155,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
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
      ),
    );
  }
}
