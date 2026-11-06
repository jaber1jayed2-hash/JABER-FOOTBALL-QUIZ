
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

  // Developer information
  static const String developerName = 'Saiful Islam Jaber';
  static const String developerPhone = '01860273648';
  static const String whatsappLink =
      'https://wa.me/qr/ENGSV6EPIQXWD1';

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  Future<void> loadSettings() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final data = await Supabase.instance.client
          .from('app_settings')
          .select('key, value');

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
    final uri = Uri.parse(whatsappLink);

    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('WhatsApp লিংক খোলা যায়নি'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('WhatsApp খুলতে সমস্যা হয়েছে'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final photo = settings['developer_photo_url'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF090D0B),

      appBar: AppBar(
        title: const Text('Contact Us'),
      ),

      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'তথ্য লোড করা যায়নি',
                          style: TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          errorMessage!,
                          style: const TextStyle(
                            color: Colors.redAccent,
                          ),
                        ),
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

                      // Developer Label
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
                      const Center(
                        child: Text(
                          developerName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      // Phone Number
                      Card(
                        child: ListTile(
                          leading: const Icon(
                            Icons.phone,
                            color: Color(0xFF27D66B),
                          ),
                          title: const Text('Phone Number'),
                          subtitle: const Text(developerPhone),
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
