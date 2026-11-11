
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final supabase = Supabase.instance.client;

  Future<Map<String, dynamic>?> _loadProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    return await supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
  }

  Future<void> _logout() async {
    try {
      await supabase.auth.signOut();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('লগআউট করতে সমস্যা হয়েছে।')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    if (user == null) {
      return const Center(
        child: Text('লগইন প্রয়োজন।'),
      );
    }

    return SafeArea(
      child: FutureBuilder<Map<String, dynamic>?>(
        future: _loadProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF27D66B),
              ),
            );
          }

          if (snapshot.hasError || snapshot.data == null) {
            return const Center(
              child: Text('Profile লোড করা যায়নি।'),
            );
          }

          final profile = snapshot.data!;

          final nickname =
              profile['display_name']?.toString() ?? 'Player';
          final xp = profile['xp'] ?? 0;
          final level = profile['level'] ?? 1;
          final points = profile['total_points'] ?? 0;
          final avatarUrl = profile['avatar_url']?.toString();

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              const Text(
                'আমার প্রোফাইল',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 25),

              Center(
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: const Color(0xFF245D39),
                  backgroundImage:
                      avatarUrl != null && avatarUrl.isNotEmpty
                          ? NetworkImage(avatarUrl)
                          : null,
                  child: avatarUrl == null || avatarUrl.isEmpty
                      ? const Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.white,
                        )
                      : null,
                ),
              ),

              const SizedBox(height: 15),

              Center(
                child: Text(
                  nickname,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 6),

              const Center(
                child: Text(
                  'Football Quiz Player',
                  style: TextStyle(color: Colors.white60),
                ),
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('লগআউট'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                'Player Statistics',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              _StatCard(
                icon: Icons.star,
                title: 'XP',
                value: '$xp',
              ),

              _StatCard(
                icon: Icons.military_tech,
                title: 'Level',
                value: '$level',
              ),

              _StatCard(
                icon: Icons.emoji_events,
                title: 'Total Points',
                value: '$points',
              ),

              const _StatCard(
                icon: Icons.quiz,
                title: 'Played Quizzes',
                value: 'পরবর্তী ধাপে যুক্ত হবে',
              ),

              const _StatCard(
                icon: Icons.check_circle,
                title: 'Correct Answers',
                value: 'পরবর্তী ধাপে যুক্ত হবে',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          icon,
          color: const Color(0xFF27D66B),
        ),
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF27D66B),
          ),
        ),
      ),
    );
  }
}
