
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'home_screen.dart';
import 'quiz_screen.dart';
import 'live_screen.dart';
import 'profile_screen.dart';
import 'contact_developer_screen.dart';
import 'nickname_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final supabase = Supabase.instance.client;

  StreamSubscription<AuthState>? _authSubscription;

  int index = 0;
  bool _checking = true;
  bool _hasNickname = false;
  bool _isBanned = false;

  String _banReason = '';
  String? _checkedUserId;

  final pages = const [
    HomeScreen(),
    QuizScreen(),
    LiveScreen(),
    ProfileScreen(),
    ContactDeveloperScreen(),
  ];

  @override
  void initState() {
    super.initState();

    _checkProfile();

    _authSubscription =
        supabase.auth.onAuthStateChange.listen((data) {
      _checkedUserId = null;
      _checkProfile();
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkProfile() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        _checking = false;
        _hasNickname = false;
        _isBanned = false;
        _banReason = '';
        _checkedUserId = null;
      });
      return;
    }

    if (_checkedUserId == user.id && !_checking) {
      return;
    }

    setState(() {
      _checking = true;
    });

    try {
      final profile = await supabase
          .from('profiles')
          .select('display_name, is_banned, ban_reason')
          .eq('id', user.id)
          .maybeSingle();

      final nickname =
          profile?['display_name']?.toString().trim() ?? '';

      final banned =
          profile?['is_banned'] == true;

      final reason =
          profile?['ban_reason']?.toString() ?? '';

      if (!mounted) return;

      setState(() {
        _hasNickname = nickname.isNotEmpty;
        _isBanned = banned;
        _banReason = reason;
        _checkedUserId = user.id;
        _checking = false;
        index = 0;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _checking = false;
        _hasNickname = false;
        _isBanned = false;
        _checkedUserId = null;
      });
    }
  }

  void _nicknameSaved() {
    setState(() {
      _hasNickname = true;
      index = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        backgroundColor: Color(0xFF090D0B),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF27D66B),
          ),
        ),
      );
    }

    // Login ছাড়া অ্যাপে প্রবেশ নিষিদ্ধ
    if (supabase.auth.currentUser == null) {
      return const LoginRequiredScreen();
    }

    // ব্যান করা অ্যাকাউন্টের জন্য সম্পূর্ণ Ban Screen
    if (_isBanned) {
      return BanScreen(reason: _banReason);
    }

    // Nickname ছাড়া Home-এ প্রবেশ নিষিদ্ধ
    if (!_hasNickname) {
      return NicknameScreen(
        onSaved: _nicknameSaved,
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: index,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) {
          setState(() => index = value);
        },
        backgroundColor: const Color(0xFF111914),
        indicatorColor: const Color(0xFF245D39),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'হোম',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_soccer),
            label: 'কুইজ',
          ),
          NavigationDestination(
            icon: Icon(Icons.scoreboard_outlined),
            label: 'লাইভ স্কোর',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'প্রোফাইল',
          ),
          NavigationDestination(
            icon: Icon(Icons.contact_support_outlined),
            label: 'Developer',
          ),
        ],
      ),
    );
  }
}

// =====================================================
// BAN SCREEN
// =====================================================

class BanScreen extends StatefulWidget {
  final String reason;

  const BanScreen({
    super.key,
    required this.reason,
  });

  @override
  State<BanScreen> createState() => _BanScreenState();
}

class _BanScreenState extends State<BanScreen> {
  final supabase = Supabase.instance.client;

  bool loading = true;

  String developerName = '';
  String developerPhone = '';
  String whatsappLink = '';

  @override
  void initState() {
    super.initState();
    _loadDeveloperInfo();
  }

  Future<void> _loadDeveloperInfo() async {
    try {
      final rows = await supabase
          .from('app_settings')
          .select('*');

      final settings = <String, String>{};

      for (final row in rows) {
        final map = Map<String, dynamic>.from(row);

        final key = map['key']?.toString();
        final value = map['value']?.toString();

        if (key != null && value != null) {
          settings[key.toLowerCase()] = value;
        }
      }

      String getSetting(List<String> keys) {
        for (final key in keys) {
          final value = settings[key.toLowerCase()];

          if (value != null && value.trim().isNotEmpty) {
            return value.trim();
          }
        }

        return '';
      }

      if (!mounted) return;

      setState(() {
        developerName = getSetting([
          'developer_name',
          'dev_name',
          'contact_developer_name',
        ]);

        developerPhone = getSetting([
          'developer_phone',
          'dev_phone',
          'contact_developer_phone',
          'phone',
        ]);

        whatsappLink = getSetting([
          'developer_whatsapp',
          'whatsapp_link',
          'developer_whatsapp_link',
          'contact_developer_whatsapp',
        ]);

        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }

  Future<void> _openWhatsApp() async {
    if (whatsappLink.trim().isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('WhatsApp লিংক পাওয়া যায়নি'),
        ),
      );

      return;
    }

    final uri = Uri.tryParse(whatsappLink.trim());

    if (uri == null) return;

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('WhatsApp লিংক খোলা যায়নি'),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('WhatsApp লিংক খোলা যায়নি'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090D0B),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFF151D18),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.redAccent.withOpacity(0.45),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.block_rounded,
                    color: Colors.redAccent,
                    size: 90,
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'আপনার অ্যাকাউন্টটি ব্যান করা হয়েছে',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  const Text(
                    'আপনি বর্তমানে JABER FOOTBALL QUIZ '
                    'অ্যাপ ব্যবহার করতে পারবেন না। '
                    'বিস্তারিত জানতে Developer-এর সাথে যোগাযোগ করুন।',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),

                  if (widget.reason.trim().isNotEmpty) ...[
                    const SizedBox(height: 20),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.redAccent.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'ব্যান করার কারণ',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            widget.reason,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  const Divider(
                    color: Colors.white12,
                  ),

                  const SizedBox(height: 15),

                  const Text(
                    'Developer-এর সাথে যোগাযোগ',
                    style: TextStyle(
                      color: Color(0xFF27D66B),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 18),

                  if (loading)
                    const CircularProgressIndicator(
                      color: Color(0xFF27D66B),
                    )
                  else ...[
                    if (developerName.isNotEmpty)
                      _infoRow(
                        Icons.person,
                        developerName,
                      ),

                    if (developerPhone.isNotEmpty)
                      _infoRow(
                        Icons.phone,
                        developerPhone,
                      ),

                    if (developerName.isEmpty &&
                        developerPhone.isEmpty &&
                        whatsappLink.isEmpty)
                      const Text(
                        'Developer-এর যোগাযোগের তথ্য পাওয়া যায়নি।',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                        ),
                      ),
                  ],

                  const SizedBox(height: 25),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: loading
                          ? null
                          : _openWhatsApp,
                      icon: const Icon(Icons.chat),
                      label: const Text(
                        'WhatsApp-এ যোগাযোগ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            const Color(0xFF27D66B),
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF27D66B),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// LOGIN REQUIRED SCREEN
// =====================================================

class LoginRequiredScreen extends StatelessWidget {
  const LoginRequiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090D0B),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.sports_soccer,
                  size: 85,
                  color: Color(0xFF27D66B),
                ),

                const SizedBox(height: 25),

                const Text(
                  'JABER FOOTBALL QUIZ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'অ্যাপে প্রবেশ করতে হলে প্রথমে '
                  'লগইন অথবা নতুন অ্যাকাউন্ট তৈরি করুন।',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AuthDialog(),
                      );
                    },
                    icon: const Icon(Icons.login),
                    label: const Text(
                      'লগইন / অ্যাকাউন্ট তৈরি',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF27D66B),
                      foregroundColor: Colors.black,
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
