import 'package:flutter/material.dart';
import 'hadith_list_screen.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../widgets/glass_container.dart';
import '../providers/locale_provider.dart';

class HadithScreen extends StatelessWidget {
  const HadithScreen({super.key});

  static final List<Map<String, String>> books = [
    {'id': 'ara-bukhari', 'name': 'Sahih Al-Bukhari', 'arabic': 'صحيح البخاري'},
    {'id': 'ara-muslim', 'name': 'Sahih Muslim', 'arabic': 'صحيح مسلم'},
    {
      'id': 'ara-abudawud',
      'name': 'Sunan Abu Dawood',
      'arabic': 'سنن أبي داود',
    },
    {
      'id': 'ara-tirmidhi',
      'name': 'Jami At-Tirmidhi',
      'arabic': 'جامع الترمذي',
    },
    {'id': 'ara-nasai', 'name': 'Sunan An-Nasa\'i', 'arabic': 'سنن النسائي'},
    {'id': 'ara-ibnmajah', 'name': 'Sunan Ibn Majah', 'arabic': 'سنن ابن ماجه'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('كتب الحديث'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: books.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final book = books[index];
          final isArabic =
              Provider.of<LocaleProvider>(context).locale.languageCode == 'ar';
          return GlassContainer(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HadithListScreen(
                    bookId: book['id']!,
                    bookName: isArabic ? book['arabic']! : book['name']!,
                  ),
                ),
              );
            },
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(
                  Icons.menu_book,
                  size: 40,
                  color: AppTheme.accentGold,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book['arabic']!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.white,
                          fontFamily: 'Amiri',
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.white54,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
