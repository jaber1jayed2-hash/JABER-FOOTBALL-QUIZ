
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

    // প্রোফাইল তথ্য
    final profile = await supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (profile == null) return null;

    // ব্যবহারকারীর সম্পন্ন কুইজের তথ্য
    final attempts = await supabase
        .from('quiz_attempts')
        .select('correct_count')
        .eq('user_id', user.id);

    // মোট সম্পন্ন কুইজ
    final playedQuizzes = attempts.length;

    // সব কুইজের সঠিক উত্তর যোগ
    int correctAnswers = 0;

    for (final attempt in attempts) {
      correctAnswers +=
          (attempt['correct_count'] as num?)?.toInt() ?? 0;
    }

    // Profile-এর সঙ্গে পরিসংখ্যান যুক্ত
    final result = Map<String, dynamic>.from(profile);

    result['played_quizzes'] = playedQuizzes;
    result['correct_answers'] = correctAnswers;

    return result;
  }

  Future<void> _logout() async {
    try {
      await supabase.auth.signOut();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('লগআউট করতে সমস্যা হয়েছে।'),
        ),
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
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF27D66B),
              ),
            );
          }

          if (snapshot.hasError || snapshot.data == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Profile লোড করা যায়নি।',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {});
                      },
                      child: const Text('আবার চেষ্টা করুন'),
                    ),
                  ],
                ),
              ),
            );
          }

          final profile = snapshot.data!;

          final nickname =
              profile['display_name']?.toString() ?? 'Player';

          final xp = profile['xp'] ?? 0;
          final level = profile['level'] ?? 1;
          final points = profile['total_points'] ?? 0;

          final playedQuizzes =
              profile['played_quizzes'] ?? 0;

          final correctAnswers =
              profile['correct_answers'] ?? 0;

          final avatarUrl =
              profile['avatar_url']?.toString();

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
                      avatarUrl != null &&
                              avatarUrl.isNotEmpty
                          ? NetworkImage(avatarUrl)
                          : null,
                  child:
                      avatarUrl == null || avatarUrl.isEmpty
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
                  style: TextStyle(
                    color: Colors.white60,
                  ),
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

              _StatCard(
                icon: Icons.quiz,
                title: 'Played Quizzes',
                value: '$playedQuizzes',
              ),

              _StatCard(
                icon: Icons.check_circle,
                title: 'Correct Answers',
                value: '$correctAnswers',
              ),

              const SizedBox(height: 15),

              OutlinedButton.icon(
                onPressed: () {
                  setState(() {});
                },
                icon: const Icon(Icons.refresh),
                label: const Text('পরিসংখ্যান রিফ্রেশ করুন'),
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

// Login এবং Register Dialog
class AuthDialog extends StatefulWidget {
  const AuthDialog({super.key});

  @override
  State<AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<AuthDialog> {
  final supabase = Supabase.instance.client;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isRegister = false;
  bool isLoading = false;
  bool obscurePassword = true;

  String? errorMessage;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        errorMessage = 'Email এবং Password লিখুন।';
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        errorMessage =
            'Password কমপক্ষে ৬ অক্ষরের হতে হবে।';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      if (isRegister) {
        final response = await supabase.auth.signUp(
          email: email,
          password: password,
        );

        if (!mounted) return;

        Navigator.of(context).pop();

        if (response.session == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'অ্যাকাউন্ট তৈরি হয়েছে। Email যাচাই করে লগইন করুন।',
              ),
              duration: Duration(seconds: 5),
            ),
          );
        }
      } else {
        await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );

        if (!mounted) return;
        Navigator.of(context).pop();
      }
    } on AuthException catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.message;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage =
            'সমস্যা হয়েছে। আবার চেষ্টা করুন।';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF151D18),
      title: Text(
        isRegister ? 'নতুন অ্যাকাউন্ট তৈরি' : 'লগইন করুন',
        style: const TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: passwordController,
              obscureText: obscurePassword,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      obscurePassword = !obscurePassword;
                    });
                  },
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                ),
              ),
            ),

            if (errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                errorMessage!,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 13,
                ),
              ),
            ],

            const SizedBox(height: 12),

            TextButton(
              onPressed: isLoading
                  ? null
                  : () {
                      setState(() {
                        isRegister = !isRegister;
                        errorMessage = null;
                      });
                    },
              child: Text(
                isRegister
                    ? 'আগে থেকেই অ্যাকাউন্ট আছে? Login'
                    : 'নতুন অ্যাকাউন্ট তৈরি করুন',
                style: const TextStyle(
                  color: Color(0xFF27D66B),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isLoading
              ? null
              : () => Navigator.of(context).pop(),
          child: const Text('বন্ধ করুন'),
        ),

        FilledButton(
          onPressed: isLoading ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF27D66B),
            foregroundColor: Colors.black,
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                )
              : Text(isRegister ? 'Register' : 'Login'),
        ),
      ],
    );
  }
}
