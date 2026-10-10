import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrayerTimesScreen extends StatelessWidget {
  final Map<String, dynamic> prayerData;

  const PrayerTimesScreen({super.key, required this.prayerData});

  @override
  Widget build(BuildContext context) {
    // prayerData is normally the payload from 'timings' endpoint
    // Structure: { "timings": { "Fajr": "05:00", ... }, "date": { "readable": "...", "hijri": ... }, "meta": ... }

    final timings = prayerData['timings'] as Map<String, dynamic>;
    final date = prayerData['date'];
    final hijri = date['hijri'];
    final gregorian = date['gregorian'];

    return Scaffold(
      appBar: AppBar(title: const Text('Prayer Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Date Card
            Card(
              color: Theme.of(context).primaryColor,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(
                      '${hijri['day']} ${hijri['month']['en']} ${hijri['year']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${gregorian['weekday']['en']}, ${gregorian['day']} ${gregorian['month']['en']} ${gregorian['year']}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Timings Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                _buildTimingTile(
                  context,
                  'Imsak',
                  timings['Imsak'],
                  Icons.nightlight_round,
                ),
                _buildTimingTile(
                  context,
                  'Fajr',
                  timings['Fajr'],
                  Icons.wb_twilight,
                ),
                _buildTimingTile(
                  context,
                  'Sunrise',
                  timings['Sunrise'],
                  Icons.wb_sunny,
                ),
                _buildTimingTile(
                  context,
                  'Dhuhr',
                  timings['Dhuhr'],
                  Icons.sunny,
                ),
                _buildTimingTile(
                  context,
                  'Asr',
                  timings['Asr'],
                  Icons.cloud_queue,
                ),
                _buildTimingTile(
                  context,
                  'Sunset',
                  timings['Sunset'],
                  Icons.wb_twilight,
                ),
                _buildTimingTile(
                  context,
                  'Maghrib',
                  timings['Maghrib'],
                  Icons.nights_stay,
                ),
                _buildTimingTile(
                  context,
                  'Isha',
                  timings['Isha'],
                  Icons.nightlight,
                ),
                _buildTimingTile(
                  context,
                  'Midnight',
                  timings['Midnight'],
                  Icons.circle,
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),

            // Meta info
            if (prayerData['meta'] != null)
              Text(
                "Calculation Method: ${prayerData['meta']['method']['name']}",
                style: const TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimingTile(
    BuildContext context,
    String name,
    String time,
    IconData icon,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                time,
                style: GoogleFonts.robotoMono(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
