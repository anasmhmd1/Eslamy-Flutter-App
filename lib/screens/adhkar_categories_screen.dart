import 'package:flutter/material.dart';
import 'adhkar_screen.dart';
import '../repositories/adhkar_repository.dart';
import '../widgets/glass_container.dart';

class AdhkarCategoriesScreen extends StatelessWidget {
  const AdhkarCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('الأذكار'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCategoryCard(
            context,
            title: 'أذكار الصباح',
            icon: Icons.wb_sunny,
            color: Colors.orangeAccent,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AdhkarScreen(
                    title: 'أذكار الصباح',
                    adhkarList: AdhkarRepository.getMorningAdhkar(),
                    isMorning: true,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildCategoryCard(
            context,
            title: 'أذكار المساء',
            icon: Icons.nightlight_round,
            color: Colors.indigoAccent,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AdhkarScreen(
                    title: 'أذكار المساء',
                    adhkarList: AdhkarRepository.getEveningAdhkar(),
                    isMorning: false,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GlassContainer(
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Icon(icon, size: 40, color: color),
        ],
      ),
    );
  }
}
