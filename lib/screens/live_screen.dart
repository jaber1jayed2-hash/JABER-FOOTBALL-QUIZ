import 'package:flutter/material.dart';

class LiveScreen extends StatelessWidget {
  const LiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text('লাইভ ফুটবল', style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('লাইভ স্কোর • ম্যাচের বিস্তারিত • লিগ টেবিল • ফলাফল'),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Icon(Icons.radio_button_checked, color: Colors.orange, size: 14),
                    SizedBox(width: 7),
                    Text('লাইভ স্কোর API সংযোগ বাকি', style: TextStyle(fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 12),
                  const Text('এখানে আসল ম্যাচের দল, স্কোর, মিনিট ও ম্যাচের অবস্থা দেখানো হবে।'),
                  const SizedBox(height: 12),
                  const Text('এখনো কোনো লাইভ স্কোর দেখানো হচ্ছে না—API যুক্ত না হওয়া পর্যন্ত ভুয়া স্কোর দেখানো হবে না।',
                      style: TextStyle(color: Colors.white60, fontSize: 12)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          const _FeatureRow(icon: Icons.calendar_month, title: 'পরবর্তী ম্যাচ', subtitle: 'ফিক্সচার ও কিক-অফ সময়'),
          const _FeatureRow(icon: Icons.table_chart, title: 'লিগ টেবিল', subtitle: 'পয়েন্ট, ম্যাচ, জয়, ড্র ও হার'),
          const _FeatureRow(icon: Icons.analytics_outlined, title: 'ম্যাচের বিস্তারিত', subtitle: 'গোল, কার্ড ও ম্যাচের পরিসংখ্যান'),
          const _FeatureRow(icon: Icons.history, title: 'পুরোনো ফলাফল', subtitle: 'শেষ হওয়া ম্যাচের ফলাফল'),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _FeatureRow({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(icon, color: const Color(0xFF27D66B)),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.lock_outline, size: 18),
    ),
  );
}
