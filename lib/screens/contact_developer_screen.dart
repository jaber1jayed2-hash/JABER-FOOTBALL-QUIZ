
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactDeveloperScreen extends StatefulWidget {
  const ContactDeveloperScreen({super.key});

  @override
  State<ContactDeveloperScreen> createState() =>
      _ContactDeveloperScreenState();
}

class _ContactDeveloperScreenState
    extends State<ContactDeveloperScreen> {
  Map<String, String> settings = {};

  bool loading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  Future<void> loadSettings() async {
    if (mounted) {
      setState(() {
        loading = true;
        errorMessage = null;
      });
    }

    try {
      final data = await Supabase.instance.client
          .from('app_settings')
          .select('key, value')
          .inFilter('key', [
        'developer_photo_url',
        'developer_name',
        'developer_phone',
        'whatsapp_link',
      ]);

      final result = <String, String>{};

      for (final item in data) {
        result[item['key'].toString()] =
            item['value']?.toString() ?? '';
      }

      if (!mounted) return;

      setState(() {
        settings = result;
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

  Future<void> openWhatsApp() async {
    final link = settings['whatsapp_link']?.trim() ?? '';

    if (link.isEmpty) {
      showMessage('WhatsApp লিংক পাওয়া যায়নি।');
      return;
    }

    final uri = Uri.tryParse(link);

    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'https' && uri.scheme != 'http')) {
      showMessage('WhatsApp লিংকটি সঠিক নয়।');
      return;
    }

    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened && mounted) {
        showMessage('WhatsApp লিংক খোলা যায়নি।');
      }
    } catch (e) {
      if (mounted) {
        showMessage('WhatsApp খুলতে সমস্যা হয়েছে।');
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photo = settings['developer_photo_url']?.trim() ?? '';
    final name = settings['developer_name']?.trim() ?? '';
    final phone = settings['developer_phone']?.trim() ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF090D0B),
      appBar: AppBar(
        title: const Text('Contact Us'),
        backgroundColor: const Color(0xFF101B15),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: loadSettings,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF27D66B),
              ),
            )
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.redAccent,
                          size: 45,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'তথ্য লোড করা যায়নি',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.redAccent,
                          ),
                        ),
                        const SizedBox(height: 15),
                        ElevatedButton(
                          onPressed: loadSettings,
                          child: const Text('আবার চেষ্টা করুন'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadSettings,
                  child: ListView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: [
                      const SizedBox(height: 25),

                      // Developer Photo
                      Center(
                        child: CircleAvatar(
                          radius: 65,
                          backgroundColor:
                              const Color(0xFF245D39),
                          backgroundImage: photo.isNotEmpty
                              ? NetworkImage(photo)
                              : null,
                          onBackgroundImageError:
                              photo.isNotEmpty
                                  ? (exception, stackTrace) {}
                                  : null,
                          child: photo.isEmpty
                              ? const Icon(
                                  Icons.person,
                                  size: 65,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ),

                      const SizedBox(height: 18),

                      const Center(
                        child: Text(
                          'Developer',
                          style: TextStyle(
                            fontSize: 18,
                            color: Color(0xFF27D66B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Developer Name
                      Center(
                        child: Text(
                          name.isNotEmpty
                              ? name
                              : 'Developer Name',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      // Phone Number
                      Card(
                        color: const Color(0xFF14221A),
                        child: ListTile(
                          leading: const Icon(
                            Icons.phone,
                            color: Color(0xFF27D66B),
                          ),
                          title: const Text(
                            'Phone Number',
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            phone.isNotEmpty
                                ? phone
                                : 'Phone number not added',
                            style: const TextStyle(
                              color: Colors.white70,
                            ),
                          ),
                          onTap: phone.isEmpty
                              ? null
                              : () async {
                                  final uri =
                                      Uri(scheme: 'tel', path: phone);
                                  await launchUrl(uri);
                                },
                        ),
                      ),

                      const SizedBox(height: 20),

                      // WhatsApp Button
                      ElevatedButton.icon(
                        onPressed: openWhatsApp,
                        icon: const Icon(Icons.chat),
                        label: const Text(
                          'Contact on WhatsApp',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF27D66B),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
