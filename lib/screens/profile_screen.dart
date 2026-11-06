
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
        const SnackBar(content: Text('লগআউট সফল হয়েছে')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('সমস্যা হয়েছে: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final user = Supabase.instance.client.auth.currentUser;

        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              const Text(
                'আমার প্রোফাইল',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 22),
              const Center(
                child: CircleAvatar(
                  radius: 42,
                  backgroundColor: Color(0xFF245D39),
                  child: Icon(Icons.person, size: 45, color: Colors.white),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  user?.email ?? 'অতিথি খেলোয়াড়',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  user == null
                      ? 'অ্যাকাউন্ট তৈরি করলে অগ্রগতি অনলাইনে সংরক্ষণের ব্যবস্থা করা যাবে।'
                      : 'আপনি লগইন করেছেন।',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white60),
                ),
              ),
              const SizedBox(height: 22),

              if (user == null)
                FilledButton.icon(
                  onPressed: _openAuthDialog,
                  icon: const Icon(Icons.login),
                  label: const Text('লগইন / অ্যাকাউন্ট তৈরি'),
                )
              else
                FilledButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('লগআউট'),
                ),

              const SizedBox(height: 18),
              const Card(
                child: ListTile(
                  leading: Icon(Icons.star),
                  title: Text('XP'),
                  trailing: Text('0'),
                ),
              ),
              const Card(
                child: ListTile(
                  leading: Icon(Icons.military_tech),
                  title: Text('লেভেল'),
                  trailing: Text('1'),
                ),
              ),
              const Card(
                child: ListTile(
                  leading: Icon(Icons.emoji_events),
                  title: Text('র‍্যাংক'),
                  trailing: Text('--'),
                ),
              ),
            ],
          ),
        );
      },
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
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLogin = true;
  bool _loading = false;
  bool _hidePassword = true;
  String? _error;

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'ইমেইল ও পাসওয়ার্ড লিখুন।');
      return;
    }

    if (password.length < 6) {
      setState(() => _error = 'পাসওয়ার্ড কমপক্ষে ৬ অক্ষরের হতে হবে।');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_isLogin) {
        await _authService.signIn(email: email, password: password);

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
            _error = 'অ্যাকাউন্ট তৈরি হয়েছে। ইমেইলে পাঠানো লিংক দিয়ে যাচাই করুন।';
          });
        }
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'সমস্যা হয়েছে। আবার চেষ্টা করুন।');
    } finally {
      if (mounted) setState(() => _loading = false);
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
      title: Text(_isLogin ? 'লগইন করুন' : 'নতুন অ্যাকাউন্ট তৈরি করুন'),
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
                    setState(() => _hidePassword = !_hidePassword);
                  },
                  icon: Icon(
                    _hidePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent),
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
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('বন্ধ করুন'),
        ),
        FilledButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isLogin ? 'লগইন' : 'অ্যাকাউন্ট তৈরি'),
        ),
      ],
    );
  }
}
