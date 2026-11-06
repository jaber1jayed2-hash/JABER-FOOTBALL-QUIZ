
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();

  Future<void> _openAuthDialog() async {
    await showDialog(
      context: context,
      builder: (_) => const AuthDialog(),
    );
  }

  Future<void> _logout() async {
    try {
      await _authService.signOut();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('লগআউট সফল হয়েছে'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('লগআউট করতে সমস্যা হয়েছে: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final user = Supabase.instance.client.auth.currentUser;

        final email = user?.email ?? 'অতিথি খেলোয়াড়';

        return SafeArea(
          child: ListView(
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

              // Profile Photo
              Center(
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: const Color(0xFF245D39),
                  child: const Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              Center(
                child: Text(
                  email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Center(
                child: Text(
                  user == null
                      ? 'Guest Player'
                      : 'আপনি সফলভাবে লগইন করেছেন।',
                  style: const TextStyle(
                    color: Colors.white60,
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // Login / Logout
              if (user == null)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _openAuthDialog,
                    icon: const Icon(Icons.login),
                    label: const Text(
                      'লগইন / অ্যাকাউন্ট তৈরি',
                    ),
                  ),
                )
              else
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
                value: '0',
              ),

              _StatCard(
                icon: Icons.military_tech,
                title: 'Level',
                value: '1',
              ),

              _StatCard(
                icon: Icons.emoji_events,
                title: 'Rank',
                value: '--',
              ),

              _StatCard(
                icon: Icons.quiz,
                title: 'Played Quizzes',
                value: '0',
              ),

              _StatCard(
                icon: Icons.check_circle,
                title: 'Correct Answers',
                value: '0',
              ),

              _StatCard(
                icon: Icons.history,
                title: 'Quiz History',
                value: '0',
              ),

              const SizedBox(height: 15),

              const Text(
                'নোট: XP, Rank এবং অন্যান্য Statistics '
                'পরবর্তী ধাপে Database-এর সঙ্গে যুক্ত করা হবে।',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
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
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Color(0xFF27D66B),
          ),
        ),
      ),
    );
  }
}

class AuthDialog extends StatefulWidget {
  const AuthDialog({super.key});

  @override
  State<AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<AuthDialog> {
  final AuthService _authService = AuthService();

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  bool _isLogin = true;
  bool _loading = false;
  bool _hidePassword = true;

  String? _error;
  String? _success;

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _error = 'ইমেইল ও পাসওয়ার্ড লিখুন।';
      });
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      setState(() {
        _error = 'সঠিক ইমেইল ঠিকানা লিখুন।';
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        _error = 'পাসওয়ার্ড কমপক্ষে ৬ অক্ষরের হতে হবে।';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });

    try {
      if (_isLogin) {
        await _authService.signIn(
          email: email,
          password: password,
        );

        if (!mounted) return;

        Navigator.pop(context);
      } else {
        final response = await _authService.signUp(
          email: email,
          password: password,
        );

        if (!mounted) return;

        if (response.session != null) {
          Navigator.pop(context);
        } else {
          setState(() {
            _success =
                'অ্যাকাউন্ট তৈরি হয়েছে। ইমেইলে পাঠানো লিংক দিয়ে যাচাই করুন।';
          });
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'সমস্যা হয়েছে। আবার চেষ্টা করুন।';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF151D18),

      title: Text(
        _isLogin
            ? 'লগইন করুন'
            : 'নতুন অ্যাকাউন্ট তৈরি করুন',
      ),

      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'ইমেইল',
                prefixIcon: Icon(Icons.email),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _passwordController,
              obscureText: _hidePassword,
              decoration: InputDecoration(
                labelText: 'পাসওয়ার্ড',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _hidePassword = !_hidePassword;
                    });
                  },
                  icon: Icon(
                    _hidePassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                ),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(
                  color: Colors.redAccent,
                ),
              ),
            ],

            if (_success != null) ...[
              const SizedBox(height: 12),
              Text(
                _success!,
                style: const TextStyle(
                  color: Color(0xFF27D66B),
                ),
              ),
            ],

            const SizedBox(height: 12),

            TextButton(
              onPressed: _loading
                  ? null
                  : () {
                      setState(() {
                        _isLogin = !_isLogin;
                        _error = null;
                        _success = null;
                      });
                    },
              child: Text(
                _isLogin
                    ? 'নতুন অ্যাকাউন্ট তৈরি করবেন?'
                    : 'আগে থেকেই অ্যাকাউন্ট আছে? লগইন করুন',
              ),
            ),
          ],
        ),
      ),

      actions: [
        TextButton(
          onPressed: _loading
              ? null
              : () => Navigator.pop(context),
          child: const Text('বন্ধ করুন'),
        ),

        FilledButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  _isLogin ? 'লগইন' : 'অ্যাকাউন্ট তৈরি',
                ),
        ),
      ],
    );
  }
}
