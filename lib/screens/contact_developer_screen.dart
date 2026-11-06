
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

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  Future<void> loadSettings() async {
    try {
      final data = await Supabase.instance.client
          .from('app_settings')
          .select('key, value');

      final result = <String, String>{};

      for (final item in data) {
        result[item['key'].toString()] =
            item['value']?.toString() ?? '';
      }

      if (mounted) {
        setState(() {
          settings = result;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> openWhatsApp() async {
    final link = settings['whatsapp_link'] ?? '';

    if (link.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WhatsApp লিংক পাওয়া যায়নি')),
      );
      return;
    }

    final uri = Uri.tryParse(link);

    if (uri == null ||
        !uri.isAbsolute ||
        !['http', 'https'].contains(uri.scheme)) {
      return;
    }

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final photo = settings['developer_photo'] ?? '';
    final name = settings['developer_name'] ?? '';
    final phone = settings['developer_phone'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF090D0B),
      appBar: AppBar(
        title: const Text('Contact with Developer'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadSettings,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 25),
                  Center(
                    child: CircleAvatar(
                      radius: 65,
                      backgroundColor: const Color(0xFF245D39),
                      backgroundImage: photo.isNotEmpty
                          ? NetworkImage(photo)
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
                  const SizedBox(height: 22),
                  Center(
                    child: Text(
                      name.isEmpty ? 'Developer' : name,
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (phone.isNotEmpty)
                    Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.phone,
                          color: Color(0xFF27D66B),
                        ),
                        title: const Text('Phone Number'),
                        subtitle: Text(phone),
                      ),
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: openWhatsApp,
                    icon: const Icon(Icons.chat),
                    label: const Text('Contact on WhatsApp'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF27D66B),
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
