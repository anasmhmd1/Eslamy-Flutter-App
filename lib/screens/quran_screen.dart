import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/quran_service.dart';
import 'quran_reading_screen.dart';
import '../core/theme/app_theme.dart';
import '../widgets/glass_container.dart';
import '../core/utils/text_utils.dart';
import '../core/localization/app_localizations.dart';

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  late Future<List<dynamic>> _surahsFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, dynamic>> _verseResults = [];

  @override
  void initState() {
    super.initState();
    _surahsFuture = Provider.of<QuranService>(
      context,
      listen: false,
    ).getSurahs();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    setState(() {
      _searchQuery = query;
    });

    if (query.isNotEmpty) {
      Provider.of<QuranService>(
        context,
        listen: false,
      ).searchVerses(query).then((results) {
        if (mounted) {
          setState(() {
            _verseResults = results;
          });
        }
      });
    } else {
      setState(() {
        _verseResults = [];
      });
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('quran')),
        centerTitle: true,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _surahsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                '${AppLocalizations.of(context).translate('error')}: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          final allSurahs = snapshot.data!;
          var displayedSurahs = List<dynamic>.from(allSurahs);

          if (_searchQuery.isNotEmpty) {
            final normalizedQuery = TextUtils.removeDiacritics(_searchQuery);
            displayedSurahs = displayedSurahs.where((surah) {
              final name = TextUtils.removeDiacritics(
                surah['name_arabic'].toString(),
              );
              final id = surah['id'].toString();
              return name.contains(normalizedQuery) ||
                  id.contains(normalizedQuery);
            }).toList();
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'بحث عن سورة أو آية...',
                    hintStyle: const TextStyle(color: Colors.white60),
                    prefixIcon: const Icon(Icons.search, color: Colors.white),
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    // Surah Results Section
                    if (displayedSurahs.isNotEmpty) ...[
                      if (_searchQuery.isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            "السور",
                            style: TextStyle(
                              color: AppTheme.accentGold,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ...displayedSurahs.map((surah) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: GlassContainer(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      QuranReadingScreen(surah: surah),
                                ),
                              );
                            },
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    const Icon(
                                      Icons.star_outline_rounded,
                                      size: 50,
                                      color: AppTheme.accentGold,
                                    ),
                                    Text(
                                      '${surah['id']}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        surah['name_arabic'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        '${surah['verses_count']} ${AppLocalizations.of(context).translate('verses')}',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],

                    // Verse Results Section
                    if (_verseResults.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          "الآيات",
                          style: TextStyle(
                            color: AppTheme.accentGold,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ..._verseResults.map((verse) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: GlassContainer(
                            onTap: () {
                              // Find full surah object to navigate
                              final surah = allSurahs.firstWhere(
                                (s) => s['id'] == verse['surah_id'],
                              );
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      QuranReadingScreen(surah: surah),
                                ),
                              );
                            },
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  verse['verse_text'],
                                  style: const TextStyle(
                                    fontFamily: 'Amiri',
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textDirection: TextDirection.rtl,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "${verse['surah_name']} - الآية ${verse['verse_number']}",
                                  style: const TextStyle(
                                    color: AppTheme.accentGold,
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.left,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
