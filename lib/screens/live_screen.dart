
import 'package:flutter/material.dart';

class LiveScreen extends StatelessWidget {
  const LiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(18),
          children: [
            const Text(
              'লাইভ ফুটবল',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'লাইভ স্কোর • ম্যাচের বিস্তারিত • লিগ টেবিল • ফলাফল',
              style: TextStyle(color: Colors.white70),
            ),

            const SizedBox(height: 18),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF164B2C),
                    Color(0xFF102018),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.radio_button_checked,
                        color: Colors.orange,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'LIVE FOOTBALL',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 15),

                  Center(
                    child: Icon(
                      Icons.sports_soccer,
                      size: 48,
                      color: Color(0xFF27D66B),
                    ),
                  ),

                  SizedBox(height: 12),

                  Center(
                    child: Text(
                      'লাইভ স্কোর API সংযোগ বাকি',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  SizedBox(height: 8),

                  Text(
                    'API যুক্ত হলে আসল ম্যাচের দল, স্কোর, মিনিট এবং ম্যাচের অবস্থা এখানে দেখা যাবে।',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            const Text(
              'ফুটবল আপডেট',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            const _FeatureRow(
              icon: Icons.calendar_month,
              title: 'পরবর্তী ম্যাচ',
              subtitle: 'ফিক্সচার ও কিক-অফ সময়',
            ),

            const _FeatureRow(
              icon: Icons.table_chart,
              title: 'লিগ টেবিল',
              subtitle: 'পয়েন্ট, ম্যাচ, জয়, ড্র ও হার',
            ),

            const _FeatureRow(
              icon: Icons.analytics_outlined,
              title: 'ম্যাচের বিস্তারিত',
              subtitle: 'গোল, কার্ড ও ম্যাচের পরিসংখ্যান',
            ),

            const _FeatureRow(
              icon: Icons.history,
              title: 'পুরোনো ফলাফল',
              subtitle: 'শেষ হওয়া ম্যাচের ফলাফল',
            ),

            const SizedBox(height: 15),

            const Text(
              'নোট: আসল লাইভ ডেটা দেখানোর জন্য পরবর্তী ধাপে Football API সংযুক্ত করতে হবে।',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF164B2C),
          child: Icon(
            icon,
            color: const Color(0xFF27D66B),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
