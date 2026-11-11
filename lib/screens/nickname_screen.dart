
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NicknameScreen extends StatefulWidget {
  final VoidCallback onSaved;

  const NicknameScreen({
    super.key,
    required this.onSaved,
  });

  @override
  State<NicknameScreen> createState() => _NicknameScreenState();
}

class _NicknameScreenState extends State<NicknameScreen> {
  final TextEditingController _controller =
      TextEditingController();

  bool _loading = false;
  String? _error;

  Future<void> _saveNickname() async {
    final nickname = _controller.text.trim();

    if (nickname.length < 2 || nickname.length > 20) {
      setState(() {
        _error = 'Nickname ২ থেকে ২০ অক্ষরের মধ্যে দিন।';
      });
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      setState(() {
        _error = 'প্রথমে লগইন করুন।';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await Supabase.instance.client
          .from('profiles')
          .update({'display_name': nickname})
          .eq('id', user.id)
          .select('id')
          .maybeSingle();

      if (result == null) {
        throw Exception('Profile পাওয়া যায়নি। আবার চেষ্টা করুন।');
      }

      if (!mounted) return;

      widget.onSaved();
    } on PostgrestException catch (e) {
      if (!mounted) return;

      setState(() {
        if (e.code == '23505') {
          _error = 'এই Nickname ইতিমধ্যে ব্যবহার করা হয়েছে।';
        } else {
          _error = 'Nickname সংরক্ষণ করা যায়নি। আবার চেষ্টা করুন।';
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'সমস্যা হয়েছে। আবার চেষ্টা করুন।';
      });
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
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF27D66B);

    return Scaffold(
      backgroundColor: const Color(0xFF090D0B),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.sports_soccer,
                  size: 75,
                  color: green,
                ),
                const SizedBox(height: 25),

                const Text(
                  'আপনার Nickname দিন',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'এই নামটি আপনার Profile এবং Leaderboard-এ '
                  'দেখানো হবে।',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 30),

                TextField(
                  controller: _controller,
                  maxLength: 20,
                  textCapitalization: TextCapitalization.words,
                  enabled: !_loading,
                  decoration: InputDecoration(
                    labelText: 'আপনার Nickname',
                    hintText: 'যেমন: Jaber King',
                    prefixIcon: const Icon(Icons.person),
                    filled: true,
                    fillColor: const Color(0xFF151D18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),

                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.redAccent,
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed:
                        _loading ? null : _saveNickname,
                    style: FilledButton.styleFrom(
                      backgroundColor: green,
                      foregroundColor: Colors.black,
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(
                            color: Colors.black,
                          )
                        : const Text(
                            'Nickname সংরক্ষণ করুন',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
